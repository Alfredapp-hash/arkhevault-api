using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using SafeCase.Application.Common;
using SafeCase.Domain.Clients;
using SafeCase.Domain.Identity;
using SafeCase.Domain.Organizations;

namespace SafeCase.Infrastructure.Persistence.Seed;

public static class DevDataSeeder
{
    public static readonly Guid OrgAId = Guid.Parse("11111111-1111-1111-1111-111111111111");
    public static readonly Guid OrgBId = Guid.Parse("22222222-2222-2222-2222-222222222222");
    public static readonly string PlatformEntraId = "dev-platform-operator";
    public static readonly string OrgAAdminEntraId = "dev-org-a-admin";
    public static readonly string OrgBAdminEntraId = "dev-org-b-admin";
    public static readonly string OrgAAdvocateEntraId = "dev-org-a-advocate";

    private static readonly SemaphoreSlim SeedGate = new(1, 1);

    public static async Task SeedAsync(IServiceProvider services, CancellationToken cancellationToken = default)
    {
        await SeedGate.WaitAsync(cancellationToken);
        try
        {
            await SeedCoreAsync(services, cancellationToken);
        }
        finally
        {
            SeedGate.Release();
        }
    }

    private static async Task SeedCoreAsync(IServiceProvider services, CancellationToken cancellationToken)
    {
        await using var scope = services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<SafeCaseDbContext>();
        var logger = scope.ServiceProvider.GetRequiredService<ILoggerFactory>().CreateLogger("DevDataSeeder");

        await db.Database.MigrateAsync(cancellationToken);
        await EnsureRolesAndPermissionsAsync(db, cancellationToken);

        if (await db.Organizations.AnyAsync(cancellationToken))
        {
            logger.LogInformation("Seed skipped: organizations already exist.");
            return;
        }

        var orgA = new Organization { Id = OrgAId, Name = "North County Victim Services", Slug = "north-county" };
        var orgB = new Organization { Id = OrgBId, Name = "Metro Family Justice Center", Slug = "metro-fjc" };
        db.Organizations.AddRange(orgA, orgB);

        var platform = new User
        {
            EntraObjectId = PlatformEntraId,
            Email = "platform@safecase.local",
            DisplayName = "Platform Operator"
        };
        var adminA = new User
        {
            EntraObjectId = OrgAAdminEntraId,
            Email = "admin.a@safecase.local",
            DisplayName = "Org A Administrator"
        };
        var adminB = new User
        {
            EntraObjectId = OrgBAdminEntraId,
            Email = "admin.b@safecase.local",
            DisplayName = "Org B Administrator"
        };
        var advocateA = new User
        {
            EntraObjectId = OrgAAdvocateEntraId,
            Email = "advocate.a@safecase.local",
            DisplayName = "Org A Advocate"
        };
        db.Users.AddRange(platform, adminA, adminB, advocateA);
        await db.SaveChangesAsync(cancellationToken);

        var roles = await db.Roles.ToDictionaryAsync(r => r.Code, cancellationToken);
        await AddMembershipAsync(db, orgA.Id, platform.Id, roles[RoleCodes.PlatformOperator].Id, cancellationToken);
        await AddMembershipAsync(db, orgA.Id, adminA.Id, roles[RoleCodes.OrganizationAdministrator].Id, cancellationToken);
        await AddMembershipAsync(db, orgB.Id, adminB.Id, roles[RoleCodes.OrganizationAdministrator].Id, cancellationToken);
        await AddMembershipAsync(db, orgA.Id, advocateA.Id, roles[RoleCodes.Advocate].Id, cancellationToken);

        await InsertClientAsync(db, OrgAId, "Alex", "Rivera", cancellationToken);
        await InsertClientAsync(db, OrgBId, "Jordan", "Lee", cancellationToken);

        logger.LogInformation("Seeded synthetic organizations A/B and users.");
    }

    private static async Task InsertClientAsync(
        SafeCaseDbContext db,
        Guid organizationId,
        string firstName,
        string lastName,
        CancellationToken cancellationToken)
    {
        // Keep GUC on the same connection/transaction as SaveChanges (pooled connections otherwise drop it).
        await using var tx = await db.Database.BeginTransactionAsync(cancellationToken);
        await db.Database.ExecuteSqlRawAsync(
            "SELECT set_config('app.current_organization_id', {0}, true);",
            organizationId.ToString());

        db.Clients.Add(new Client
        {
            OrganizationId = organizationId,
            Status = "active",
            Identity = new ClientIdentity
            {
                OrganizationId = organizationId,
                FirstName = firstName,
                LastName = lastName
            }
        });
        await db.SaveChangesAsync(cancellationToken);
        await tx.CommitAsync(cancellationToken);
    }

    public static async Task EnsureRolesAndPermissionsAsync(SafeCaseDbContext db, CancellationToken cancellationToken)
    {
        foreach (var code in PermissionCodes.All)
        {
            if (!await db.Permissions.AnyAsync(p => p.Code == code, cancellationToken))
            {
                db.Permissions.Add(new Permission
                {
                    Code = code,
                    Description = code.Replace('.', ' ')
                });
            }
        }

        await db.SaveChangesAsync(cancellationToken);
        var permissions = await db.Permissions.ToDictionaryAsync(p => p.Code, cancellationToken);

        await EnsureRoleAsync(db, RoleCodes.PlatformOperator, "Platform Operator", PermissionCodes.All, permissions, cancellationToken);
        await EnsureRoleAsync(db, RoleCodes.OrganizationOwner, "Organization Owner", PermissionCodes.All, permissions, cancellationToken);
        await EnsureRoleAsync(db, RoleCodes.OrganizationAdministrator, "Organization Administrator",
        [
            PermissionCodes.ClientRead, PermissionCodes.ClientCreate, PermissionCodes.ClientUpdateIdentity,
            PermissionCodes.CaseRead, PermissionCodes.CaseAssign, PermissionCodes.CaseClose,
            PermissionCodes.NoteCreate, PermissionCodes.NoteReadRestricted,
            PermissionCodes.DocumentUpload, PermissionCodes.DocumentDownload,
            PermissionCodes.ConsentManage, PermissionCodes.ReportGenerate, PermissionCodes.AuditReview,
            PermissionCodes.OrganizationManageUsers
        ], permissions, cancellationToken);
        await EnsureRoleAsync(db, RoleCodes.Advocate, "Advocate",
        [
            PermissionCodes.ClientRead, PermissionCodes.ClientCreate,
            PermissionCodes.CaseRead, PermissionCodes.CaseAssign,
            PermissionCodes.NoteCreate, PermissionCodes.DocumentUpload, PermissionCodes.DocumentDownload
        ], permissions, cancellationToken);
        await EnsureRoleAsync(db, RoleCodes.Auditor, "Auditor",
        [
            PermissionCodes.ClientRead, PermissionCodes.CaseRead, PermissionCodes.AuditReview, PermissionCodes.ReportGenerate
        ], permissions, cancellationToken);
        await EnsureRoleAsync(db, RoleCodes.ReadOnlyReviewer, "Read-Only Reviewer",
        [
            PermissionCodes.ClientRead, PermissionCodes.CaseRead
        ], permissions, cancellationToken);
    }

    private static async Task EnsureRoleAsync(
        SafeCaseDbContext db,
        string code,
        string name,
        IReadOnlyCollection<string> permissionCodes,
        IReadOnlyDictionary<string, Permission> permissions,
        CancellationToken cancellationToken)
    {
        var role = await db.Roles.Include(r => r.RolePermissions).FirstOrDefaultAsync(r => r.Code == code, cancellationToken);
        if (role is null)
        {
            role = new Role { Code = code, Name = name, IsSystemRole = true };
            db.Roles.Add(role);
            await db.SaveChangesAsync(cancellationToken);
            role = await db.Roles.Include(r => r.RolePermissions).FirstAsync(r => r.Code == code, cancellationToken);
        }

        foreach (var permissionCode in permissionCodes)
        {
            if (role.RolePermissions.Any(rp => rp.PermissionId == permissions[permissionCode].Id))
            {
                continue;
            }

            db.RolePermissions.Add(new RolePermission
            {
                RoleId = role.Id,
                PermissionId = permissions[permissionCode].Id
            });
        }

        await db.SaveChangesAsync(cancellationToken);
    }

    private static async Task AddMembershipAsync(
        SafeCaseDbContext db,
        Guid orgId,
        Guid userId,
        Guid roleId,
        CancellationToken cancellationToken)
    {
        var membership = new OrganizationMembership
        {
            OrganizationId = orgId,
            UserId = userId,
            IsActive = true
        };
        membership.MembershipRoles.Add(new MembershipRole { RoleId = roleId });
        db.Memberships.Add(membership);
        await db.SaveChangesAsync(cancellationToken);
    }
}
