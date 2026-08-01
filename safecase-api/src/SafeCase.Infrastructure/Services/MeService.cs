using Microsoft.EntityFrameworkCore;
using SafeCase.Application.Abstractions;
using SafeCase.Application.Common;
using SafeCase.Application.Identity;
using SafeCase.Domain.Identity;
using SafeCase.Domain.Organizations;
using SafeCase.Infrastructure.Persistence;

namespace SafeCase.Infrastructure.Services;

public sealed class MeService(
    SafeCaseDbContext db,
    ICurrentUser currentUser,
    IAuditService auditService)
{
    public async Task<MeResponse> GetOrProvisionAsync(CancellationToken cancellationToken = default)
    {
        if (!currentUser.IsAuthenticated || string.IsNullOrWhiteSpace(currentUser.EntraObjectId))
        {
            throw new PermissionDeniedException("Authentication required.");
        }

        var user = await db.Users
            .Include(u => u.Memberships)
                .ThenInclude(m => m.Organization)
            .Include(u => u.Memberships)
                .ThenInclude(m => m.MembershipRoles)
                    .ThenInclude(mr => mr.Role)
            .FirstOrDefaultAsync(u => u.EntraObjectId == currentUser.EntraObjectId, cancellationToken);

        var created = false;
        if (user is null)
        {
            user = new User
            {
                EntraObjectId = currentUser.EntraObjectId!,
                Email = currentUser.Email ?? $"{currentUser.EntraObjectId}@unknown.local",
                DisplayName = currentUser.DisplayName ?? "SafeCase User",
                LastSignInAt = DateTimeOffset.UtcNow
            };
            db.Users.Add(user);
            await db.SaveChangesAsync(cancellationToken);
            created = true;
        }
        else
        {
            user.LastSignInAt = DateTimeOffset.UtcNow;
            // Avoid overwriting curated seed emails with synthetic "{oid}@safecase.local" defaults.
            if (!string.IsNullOrWhiteSpace(currentUser.Email)
                && !currentUser.Email.EndsWith("@safecase.local", StringComparison.OrdinalIgnoreCase))
            {
                user.Email = currentUser.Email!;
            }

            if (!string.IsNullOrWhiteSpace(currentUser.DisplayName)
                && !string.Equals(currentUser.DisplayName, currentUser.EntraObjectId, StringComparison.Ordinal))
            {
                user.DisplayName = currentUser.DisplayName!;
            }

            await db.SaveChangesAsync(cancellationToken);
        }

        currentUser.UserId = user.Id;
        currentUser.IsPlatformOperator = await IsPlatformOperatorAsync(user.Id, cancellationToken);

        var memberships = user.Memberships
            .OrderBy(m => m.Organization!.Name)
            .Select(m => new MembershipSummaryDto(
                m.Id,
                m.OrganizationId,
                m.Organization!.Name,
                m.Organization.Slug,
                m.IsActive,
                m.MembershipRoles.Select(r => r.Role!.Code).OrderBy(x => x).ToArray()))
            .ToArray();

        var selectedOrgId = currentUser.OrganizationId;
        var selectedMembership = memberships.FirstOrDefault(m =>
            selectedOrgId is not null && m.OrganizationId == selectedOrgId && m.IsActive)
            ?? memberships.FirstOrDefault(m => m.IsActive);

        IReadOnlyList<string> permissions = [];
        if (selectedMembership is not null)
        {
            currentUser.OrganizationId = selectedMembership.OrganizationId;
            currentUser.MembershipId = selectedMembership.MembershipId;
            permissions = await LoadPermissionsAsync(selectedMembership.MembershipId, cancellationToken);
            currentUser.Permissions = permissions.ToHashSet();
        }

        await auditService.WriteAsync(new AuditWriteRequest(
            Action: created ? "user.provisioned" : "user.sign_in",
            ResourceType: "user",
            ResourceId: user.Id,
            Result: "success"), cancellationToken);

        return new MeResponse(
            user.Id,
            user.EntraObjectId,
            user.Email,
            user.DisplayName,
            currentUser.IsPlatformOperator,
            memberships,
            selectedMembership?.OrganizationId,
            selectedMembership?.MembershipId,
            permissions);
    }

    private async Task<bool> IsPlatformOperatorAsync(Guid userId, CancellationToken cancellationToken)
    {
        return await db.MembershipRoles
            .AsNoTracking()
            .Where(mr => mr.Membership!.UserId == userId && mr.Membership.IsActive)
            .AnyAsync(mr => mr.Role!.Code == RoleCodes.PlatformOperator, cancellationToken);
    }

    private async Task<IReadOnlyList<string>> LoadPermissionsAsync(Guid membershipId, CancellationToken cancellationToken)
    {
        return await db.MembershipRoles
            .AsNoTracking()
            .Where(mr => mr.MembershipId == membershipId)
            .SelectMany(mr => mr.Role!.RolePermissions.Select(rp => rp.Permission!.Code))
            .Distinct()
            .OrderBy(x => x)
            .ToListAsync(cancellationToken);
    }
}
