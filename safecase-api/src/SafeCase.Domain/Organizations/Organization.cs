using SafeCase.Domain.Common;

namespace SafeCase.Domain.Organizations;

public class Organization : Entity
{
    public string Name { get; set; } = string.Empty;
    public string Slug { get; set; } = string.Empty;
    public bool IsActive { get; set; } = true;
    public ICollection<OrganizationMembership> Memberships { get; set; } = [];
}

public class OrganizationMembership : TenantEntity
{
    public Guid UserId { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTimeOffset? DisabledAt { get; set; }
    public string? DisabledReason { get; set; }

    public Organization? Organization { get; set; }
    public Identity.User? User { get; set; }
    public ICollection<MembershipRole> MembershipRoles { get; set; } = [];
}

public class Role : Entity
{
    public string Name { get; set; } = string.Empty;
    public string Code { get; set; } = string.Empty;
    public bool IsSystemRole { get; set; }
    public ICollection<RolePermission> RolePermissions { get; set; } = [];
}

public class Permission : Entity
{
    public string Code { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
}

public class RolePermission
{
    public Guid RoleId { get; set; }
    public Guid PermissionId { get; set; }
    public Role? Role { get; set; }
    public Permission? Permission { get; set; }
}

public class MembershipRole
{
    public Guid MembershipId { get; set; }
    public Guid RoleId { get; set; }
    public OrganizationMembership? Membership { get; set; }
    public Role? Role { get; set; }
}
