using Microsoft.EntityFrameworkCore;
using SafeCase.Domain.Audit;
using SafeCase.Domain.Cases;
using SafeCase.Domain.Clients;
using SafeCase.Domain.Identity;
using SafeCase.Domain.Organizations;
using SafeCase.Domain.Tasks;

namespace SafeCase.Infrastructure.Persistence;

public class SafeCaseDbContext(
    DbContextOptions<SafeCaseDbContext> options,
    IOrganizationContext organizationContext) : DbContext(options)
{
    private readonly IOrganizationContext _organizationContext = organizationContext;

    public DbSet<Organization> Organizations => Set<Organization>();
    public DbSet<User> Users => Set<User>();
    public DbSet<OrganizationMembership> Memberships => Set<OrganizationMembership>();
    public DbSet<Role> Roles => Set<Role>();
    public DbSet<Permission> Permissions => Set<Permission>();
    public DbSet<RolePermission> RolePermissions => Set<RolePermission>();
    public DbSet<MembershipRole> MembershipRoles => Set<MembershipRole>();
    public DbSet<Client> Clients => Set<Client>();
    public DbSet<ClientIdentity> ClientIdentities => Set<ClientIdentity>();
    public DbSet<ClientContactMethod> ClientContactMethods => Set<ClientContactMethod>();
    public DbSet<Case> Cases => Set<Case>();
    public DbSet<CaseAssignment> CaseAssignments => Set<CaseAssignment>();
    public DbSet<CaseNote> CaseNotes => Set<CaseNote>();
    public DbSet<CaseTimelineEvent> CaseTimelineEvents => Set<CaseTimelineEvent>();
    public DbSet<TaskItem> Tasks => Set<TaskItem>();
    public DbSet<AuditEvent> AuditEvents => Set<AuditEvent>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.HasDefaultSchema("safecase");

        modelBuilder.Entity<Organization>(e =>
        {
            e.HasIndex(x => x.Slug).IsUnique();
            e.Property(x => x.Name).HasMaxLength(200).IsRequired();
            e.Property(x => x.Slug).HasMaxLength(100).IsRequired();
            e.Property(x => x.RowVersion).IsRowVersion();
        });

        modelBuilder.Entity<User>(e =>
        {
            e.HasIndex(x => x.EntraObjectId).IsUnique();
            e.HasIndex(x => x.Email);
            e.Property(x => x.EntraObjectId).HasMaxLength(128).IsRequired();
            e.Property(x => x.Email).HasMaxLength(320).IsRequired();
            e.Property(x => x.DisplayName).HasMaxLength(200).IsRequired();
            e.Property(x => x.RowVersion).IsRowVersion();
        });

        modelBuilder.Entity<OrganizationMembership>(e =>
        {
            e.HasIndex(x => new { x.OrganizationId, x.UserId }).IsUnique();
            e.HasOne(x => x.Organization).WithMany(x => x.Memberships).HasForeignKey(x => x.OrganizationId);
            e.HasOne(x => x.User).WithMany(x => x.Memberships).HasForeignKey(x => x.UserId);
            e.Property(x => x.RowVersion).IsRowVersion();
        });

        modelBuilder.Entity<Role>(e =>
        {
            e.HasIndex(x => x.Code).IsUnique();
            e.Property(x => x.Code).HasMaxLength(100).IsRequired();
            e.Property(x => x.Name).HasMaxLength(200).IsRequired();
            e.Property(x => x.RowVersion).IsRowVersion();
        });

        modelBuilder.Entity<Permission>(e =>
        {
            e.HasIndex(x => x.Code).IsUnique();
            e.Property(x => x.Code).HasMaxLength(100).IsRequired();
            e.Property(x => x.Description).HasMaxLength(500).IsRequired();
            e.Property(x => x.RowVersion).IsRowVersion();
        });

        modelBuilder.Entity<RolePermission>(e =>
        {
            e.HasKey(x => new { x.RoleId, x.PermissionId });
            e.HasOne(x => x.Role).WithMany(x => x.RolePermissions).HasForeignKey(x => x.RoleId);
            e.HasOne(x => x.Permission).WithMany().HasForeignKey(x => x.PermissionId);
        });

        modelBuilder.Entity<MembershipRole>(e =>
        {
            e.HasKey(x => new { x.MembershipId, x.RoleId });
            e.HasOne(x => x.Membership).WithMany(x => x.MembershipRoles).HasForeignKey(x => x.MembershipId);
            e.HasOne(x => x.Role).WithMany().HasForeignKey(x => x.RoleId);
        });

        modelBuilder.Entity<Client>(e =>
        {
            e.HasIndex(x => x.OrganizationId);
            e.Property(x => x.Status).HasMaxLength(50).IsRequired();
            e.Property(x => x.RiskLevel).HasMaxLength(50);
            e.Property(x => x.RowVersion).IsRowVersion();
            e.HasOne(x => x.Identity).WithOne(x => x.Client).HasForeignKey<ClientIdentity>(x => x.ClientId);
        });

        modelBuilder.Entity<ClientIdentity>(e =>
        {
            e.HasIndex(x => x.OrganizationId);
            e.HasIndex(x => x.ClientId).IsUnique();
            e.Property(x => x.FirstName).HasMaxLength(100).IsRequired();
            e.Property(x => x.LastName).HasMaxLength(100).IsRequired();
            e.Property(x => x.RowVersion).IsRowVersion();
        });

        modelBuilder.Entity<ClientContactMethod>(e =>
        {
            e.HasIndex(x => x.OrganizationId);
            e.Property(x => x.MethodType).HasMaxLength(50).IsRequired();
            e.Property(x => x.Value).HasMaxLength(320).IsRequired();
            e.Property(x => x.RowVersion).IsRowVersion();
            e.HasOne(x => x.Client).WithMany(x => x.ContactMethods).HasForeignKey(x => x.ClientId);
        });

        modelBuilder.Entity<Case>(e =>
        {
            e.ToTable("cases");
            e.HasIndex(x => x.OrganizationId);
            e.HasIndex(x => new { x.OrganizationId, x.ClientId });
            e.Property(x => x.Status).HasMaxLength(50).IsRequired();
            e.Property(x => x.Title).HasMaxLength(300);
            e.Property(x => x.RowVersion).IsRowVersion();
            e.HasOne(x => x.Client).WithMany(x => x.Cases).HasForeignKey(x => x.ClientId);
        });

        modelBuilder.Entity<CaseAssignment>(e =>
        {
            e.HasIndex(x => x.OrganizationId);
            e.Property(x => x.RoleOnCase).HasMaxLength(100).IsRequired();
            e.Property(x => x.RowVersion).IsRowVersion();
            e.HasOne(x => x.Case).WithMany(x => x.Assignments).HasForeignKey(x => x.CaseId);
        });

        modelBuilder.Entity<CaseNote>(e =>
        {
            e.HasIndex(x => x.OrganizationId);
            e.Property(x => x.NoteType).HasMaxLength(50).IsRequired();
            e.Property(x => x.VisibilityLevel).HasMaxLength(50).IsRequired();
            e.Property(x => x.Narrative).IsRequired();
            e.Property(x => x.RowVersion).IsRowVersion();
            e.HasOne(x => x.Case).WithMany(x => x.Notes).HasForeignKey(x => x.CaseId);
        });

        modelBuilder.Entity<CaseTimelineEvent>(e =>
        {
            e.HasIndex(x => new { x.OrganizationId, x.CaseId, x.CreatedAt });
            e.Property(x => x.EventType).HasMaxLength(100).IsRequired();
            e.Property(x => x.Summary).HasMaxLength(500).IsRequired();
            e.Property(x => x.RelatedResourceType).HasMaxLength(100);
            e.Property(x => x.RowVersion).IsRowVersion();
            e.HasOne(x => x.Case).WithMany(x => x.TimelineEvents).HasForeignKey(x => x.CaseId);
        });

        modelBuilder.Entity<TaskItem>(e =>
        {
            e.ToTable("tasks");
            e.HasIndex(x => x.OrganizationId);
            e.Property(x => x.Title).HasMaxLength(300).IsRequired();
            e.Property(x => x.Status).HasMaxLength(50).IsRequired();
            e.Property(x => x.Priority).HasMaxLength(50).IsRequired();
            e.Property(x => x.RowVersion).IsRowVersion();
            e.HasOne(x => x.Case).WithMany(x => x.Tasks).HasForeignKey(x => x.CaseId);
        });

        modelBuilder.Entity<AuditEvent>(e =>
        {
            e.HasIndex(x => new { x.OrganizationId, x.CreatedAt });
            e.HasIndex(x => x.CorrelationId);
            e.Property(x => x.Action).HasMaxLength(100).IsRequired();
            e.Property(x => x.ResourceType).HasMaxLength(100).IsRequired();
            e.Property(x => x.Result).HasMaxLength(50).IsRequired();
            e.Property(x => x.Reason).HasMaxLength(500);
            e.Property(x => x.IpContext).HasMaxLength(100);
            e.Property(x => x.DeviceContext).HasMaxLength(300);
            e.Property(x => x.CorrelationId).HasMaxLength(64).IsRequired();
            e.Property(x => x.PreviousHash).HasMaxLength(128);
            e.Property(x => x.EventHash).HasMaxLength(128).IsRequired();
            e.Property(x => x.RowVersion).IsRowVersion();
        });

        // Fail closed: tenant rows are invisible until organization context is set.
        modelBuilder.Entity<Client>().HasQueryFilter(x =>
            _organizationContext.OrganizationId != null && x.OrganizationId == _organizationContext.OrganizationId);
        modelBuilder.Entity<ClientIdentity>().HasQueryFilter(x =>
            _organizationContext.OrganizationId != null && x.OrganizationId == _organizationContext.OrganizationId);
        modelBuilder.Entity<ClientContactMethod>().HasQueryFilter(x =>
            _organizationContext.OrganizationId != null && x.OrganizationId == _organizationContext.OrganizationId);
        modelBuilder.Entity<Case>().HasQueryFilter(x =>
            _organizationContext.OrganizationId != null && x.OrganizationId == _organizationContext.OrganizationId);
        modelBuilder.Entity<CaseAssignment>().HasQueryFilter(x =>
            _organizationContext.OrganizationId != null && x.OrganizationId == _organizationContext.OrganizationId);
        modelBuilder.Entity<CaseNote>().HasQueryFilter(x =>
            _organizationContext.OrganizationId != null && x.OrganizationId == _organizationContext.OrganizationId);
        modelBuilder.Entity<CaseTimelineEvent>().HasQueryFilter(x =>
            _organizationContext.OrganizationId != null && x.OrganizationId == _organizationContext.OrganizationId);
        modelBuilder.Entity<TaskItem>().HasQueryFilter(x =>
            _organizationContext.OrganizationId != null && x.OrganizationId == _organizationContext.OrganizationId);
        modelBuilder.Entity<AuditEvent>().HasQueryFilter(x =>
            _organizationContext.OrganizationId != null && x.OrganizationId == _organizationContext.OrganizationId);
    }
}
