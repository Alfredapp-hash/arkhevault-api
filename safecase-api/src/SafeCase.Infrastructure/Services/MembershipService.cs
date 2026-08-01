using Microsoft.EntityFrameworkCore;
using SafeCase.Application.Abstractions;
using SafeCase.Application.Common;
using SafeCase.Application.Identity;
using SafeCase.Domain.Identity;
using SafeCase.Domain.Organizations;
using SafeCase.Infrastructure.Persistence;

namespace SafeCase.Infrastructure.Services;

public sealed class MembershipService(
    SafeCaseDbContext db,
    OrganizationContext organizationContext,
    ICurrentUser currentUser,
    IPermissionGate gate,
    IAuditService auditService)
{
    public async Task<IReadOnlyList<MembershipDto>> ListAsync(Guid organizationId, CancellationToken cancellationToken = default)
    {
        await EnsureOrgAccessAsync(organizationId, PermissionCodes.OrganizationManageUsers, readOnlyFallback: true, cancellationToken);

        return await db.Memberships.AsNoTracking()
            .Where(m => m.OrganizationId == organizationId)
            .OrderBy(m => m.User!.Email)
            .Select(m => new MembershipDto(
                m.Id,
                m.OrganizationId,
                m.UserId,
                m.User!.Email,
                m.User.DisplayName,
                m.IsActive,
                m.MembershipRoles.Select(r => r.Role!.Code).OrderBy(x => x).ToArray(),
                m.DisabledAt,
                m.DisabledReason))
            .ToListAsync(cancellationToken);
    }

    public async Task<MembershipDto> CreateAsync(
        Guid organizationId,
        CreateMembershipRequest request,
        CancellationToken cancellationToken = default)
    {
        await EnsureOrgAccessAsync(organizationId, PermissionCodes.OrganizationManageUsers, readOnlyFallback: false, cancellationToken);

        var role = await db.Roles.FirstOrDefaultAsync(r => r.Code == request.RoleCode, cancellationToken)
            ?? throw new ConflictException("Unknown role code.");

        if (role.Code == RoleCodes.PlatformOperator && !currentUser.IsPlatformOperator)
        {
            throw new PermissionDeniedException("Only platform operators can assign platform_operator.");
        }

        var user = await db.Users.FirstOrDefaultAsync(u => u.EntraObjectId == request.EntraObjectId, cancellationToken);
        if (user is null)
        {
            user = new User
            {
                EntraObjectId = request.EntraObjectId.Trim(),
                Email = request.Email.Trim().ToLowerInvariant(),
                DisplayName = request.DisplayName.Trim()
            };
            db.Users.Add(user);
            await db.SaveChangesAsync(cancellationToken);
        }

        var existing = await db.Memberships
            .Include(m => m.MembershipRoles)
            .FirstOrDefaultAsync(m => m.OrganizationId == organizationId && m.UserId == user.Id, cancellationToken);

        if (existing is not null)
        {
            if (!existing.IsActive)
            {
                existing.IsActive = true;
                existing.DisabledAt = null;
                existing.DisabledReason = null;
            }

            if (existing.MembershipRoles.All(r => r.RoleId != role.Id))
            {
                existing.MembershipRoles.Add(new MembershipRole { MembershipId = existing.Id, RoleId = role.Id });
            }

            await db.SaveChangesAsync(cancellationToken);
            await auditService.WriteAsync(new AuditWriteRequest(
                Action: "membership.updated",
                ResourceType: "membership",
                ResourceId: existing.Id), cancellationToken);
            return await GetDtoAsync(existing.Id, cancellationToken);
        }

        var membership = new OrganizationMembership
        {
            OrganizationId = organizationId,
            UserId = user.Id,
            IsActive = true
        };
        membership.MembershipRoles.Add(new MembershipRole { RoleId = role.Id });
        db.Memberships.Add(membership);
        await db.SaveChangesAsync(cancellationToken);

        await auditService.WriteAsync(new AuditWriteRequest(
            Action: "membership.created",
            ResourceType: "membership",
            ResourceId: membership.Id), cancellationToken);

        return await GetDtoAsync(membership.Id, cancellationToken);
    }

    public async Task<MembershipDto> DisableAsync(
        Guid organizationId,
        Guid membershipId,
        DisableMembershipRequest request,
        CancellationToken cancellationToken = default)
    {
        await EnsureOrgAccessAsync(organizationId, PermissionCodes.OrganizationManageUsers, readOnlyFallback: false, cancellationToken);

        var membership = await db.Memberships
            .FirstOrDefaultAsync(m => m.Id == membershipId && m.OrganizationId == organizationId, cancellationToken)
            ?? throw new NotFoundException("Membership not found.");

        membership.IsActive = false;
        membership.DisabledAt = DateTimeOffset.UtcNow;
        membership.DisabledReason = string.IsNullOrWhiteSpace(request.Reason) ? "disabled" : request.Reason.Trim();
        await db.SaveChangesAsync(cancellationToken);

        await auditService.WriteAsync(new AuditWriteRequest(
            Action: "membership.disabled",
            ResourceType: "membership",
            ResourceId: membership.Id,
            Reason: "admin_disable"), cancellationToken);

        return await GetDtoAsync(membership.Id, cancellationToken);
    }

    private async Task EnsureOrgAccessAsync(
        Guid organizationId,
        string permission,
        bool readOnlyFallback,
        CancellationToken cancellationToken)
    {
        gate.RequireAuthenticated();

        organizationContext.OrganizationId = organizationId;
        currentUser.OrganizationId = organizationId;

        if (currentUser.IsPlatformOperator)
        {
            return;
        }

        var membership = await db.Memberships
            .Include(m => m.MembershipRoles).ThenInclude(mr => mr.Role).ThenInclude(r => r!.RolePermissions).ThenInclude(rp => rp.Permission)
            .FirstOrDefaultAsync(m =>
                m.OrganizationId == organizationId
                && m.UserId == currentUser.UserId
                && m.IsActive, cancellationToken);

        if (membership is null)
        {
            throw new NotFoundException("Organization not found.");
        }

        currentUser.MembershipId = membership.Id;
        currentUser.Permissions = membership.MembershipRoles
            .SelectMany(mr => mr.Role!.RolePermissions.Select(rp => rp.Permission!.Code))
            .ToHashSet();

        if (readOnlyFallback && currentUser.Permissions.Contains(PermissionCodes.OrganizationManageUsers) == false)
        {
            // Members can see their own org membership list only if they have manage_users for now.
            // Fail closed for non-managers.
            throw new PermissionDeniedException($"Missing permission: {permission}");
        }

        gate.RequirePermission(permission);
    }

    private async Task<MembershipDto> GetDtoAsync(Guid membershipId, CancellationToken cancellationToken)
    {
        return await db.Memberships.AsNoTracking()
            .Where(m => m.Id == membershipId)
            .Select(m => new MembershipDto(
                m.Id,
                m.OrganizationId,
                m.UserId,
                m.User!.Email,
                m.User.DisplayName,
                m.IsActive,
                m.MembershipRoles.Select(r => r.Role!.Code).OrderBy(x => x).ToArray(),
                m.DisabledAt,
                m.DisabledReason))
            .FirstAsync(cancellationToken);
    }
}
