using Microsoft.EntityFrameworkCore;
using SafeCase.Application.Abstractions;
using SafeCase.Application.Identity;
using SafeCase.Domain.Organizations;
using SafeCase.Infrastructure.Persistence;

namespace SafeCase.Infrastructure.Services;

public sealed class OrganizationService(
    SafeCaseDbContext db,
    ICurrentUser currentUser,
    IPermissionGate gate,
    IAuditService auditService)
{
    public async Task<IReadOnlyList<OrganizationDto>> ListForCurrentUserAsync(CancellationToken cancellationToken = default)
    {
        gate.RequireAuthenticated();

        if (currentUser.IsPlatformOperator)
        {
            return await db.Organizations.AsNoTracking()
                .OrderBy(o => o.Name)
                .Select(o => new OrganizationDto(o.Id, o.Name, o.Slug, o.IsActive, o.CreatedAt))
                .ToListAsync(cancellationToken);
        }

        return await db.Memberships.AsNoTracking()
            .Where(m => m.UserId == currentUser.UserId && m.IsActive)
            .Select(m => m.Organization!)
            .OrderBy(o => o.Name)
            .Select(o => new OrganizationDto(o.Id, o.Name, o.Slug, o.IsActive, o.CreatedAt))
            .ToListAsync(cancellationToken);
    }

    public async Task<OrganizationDto> CreateAsync(CreateOrganizationRequest request, CancellationToken cancellationToken = default)
    {
        gate.RequirePlatformOperator();

        var name = request.Name.Trim();
        var slug = request.Slug.Trim().ToLowerInvariant();
        if (string.IsNullOrWhiteSpace(name) || string.IsNullOrWhiteSpace(slug))
        {
            throw new ConflictException("Name and slug are required.");
        }

        if (await db.Organizations.AnyAsync(o => o.Slug == slug, cancellationToken))
        {
            throw new ConflictException("Organization slug already exists.");
        }

        var org = new Organization { Name = name, Slug = slug };
        db.Organizations.Add(org);
        await db.SaveChangesAsync(cancellationToken);

        await auditService.WriteAsync(new AuditWriteRequest(
            Action: "organization.created",
            ResourceType: "organization",
            ResourceId: org.Id,
            Reason: "platform_operator_create"), cancellationToken);

        return new OrganizationDto(org.Id, org.Name, org.Slug, org.IsActive, org.CreatedAt);
    }

    public async Task<OrganizationDto> GetAsync(Guid organizationId, CancellationToken cancellationToken = default)
    {
        gate.RequireAuthenticated();

        var canAccess = currentUser.IsPlatformOperator
            || await db.Memberships.AnyAsync(
                m => m.OrganizationId == organizationId && m.UserId == currentUser.UserId && m.IsActive,
                cancellationToken);

        if (!canAccess)
        {
            // Fail closed without existence leak
            throw new NotFoundException("Organization not found.");
        }

        var org = await db.Organizations.AsNoTracking()
            .FirstOrDefaultAsync(o => o.Id == organizationId, cancellationToken)
            ?? throw new NotFoundException("Organization not found.");

        return new OrganizationDto(org.Id, org.Name, org.Slug, org.IsActive, org.CreatedAt);
    }
}
