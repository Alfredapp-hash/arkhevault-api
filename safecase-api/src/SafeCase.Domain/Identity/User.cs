using SafeCase.Domain.Common;
using SafeCase.Domain.Organizations;

namespace SafeCase.Domain.Identity;

public class User : Entity
{
    /// <summary>Microsoft Entra External ID object identifier.</summary>
    public string EntraObjectId { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string DisplayName { get; set; } = string.Empty;
    public bool IsActive { get; set; } = true;
    public DateTimeOffset? LastSignInAt { get; set; }

    public ICollection<OrganizationMembership> Memberships { get; set; } = [];
}
