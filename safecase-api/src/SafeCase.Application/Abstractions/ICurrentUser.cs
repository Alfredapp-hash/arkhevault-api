namespace SafeCase.Application.Abstractions;

public interface ICurrentUser
{
    bool IsAuthenticated { get; }
    string? EntraObjectId { get; }
    string? Email { get; }
    string? DisplayName { get; }
    Guid? UserId { get; set; }
    Guid? MembershipId { get; set; }
    Guid? OrganizationId { get; set; }
    IReadOnlySet<string> Permissions { get; set; }
    bool IsPlatformOperator { get; set; }
}

public sealed class CurrentUser : ICurrentUser
{
    public bool IsAuthenticated { get; set; }
    public string? EntraObjectId { get; set; }
    public string? Email { get; set; }
    public string? DisplayName { get; set; }
    public Guid? UserId { get; set; }
    public Guid? MembershipId { get; set; }
    public Guid? OrganizationId { get; set; }
    public IReadOnlySet<string> Permissions { get; set; } = new HashSet<string>();
    public bool IsPlatformOperator { get; set; }
}
