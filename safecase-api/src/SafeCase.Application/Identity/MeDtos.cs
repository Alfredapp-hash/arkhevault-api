namespace SafeCase.Application.Identity;

public sealed record MeResponse(
    Guid UserId,
    string EntraObjectId,
    string Email,
    string DisplayName,
    bool IsPlatformOperator,
    IReadOnlyList<MembershipSummaryDto> Memberships,
    Guid? SelectedOrganizationId,
    Guid? SelectedMembershipId,
    IReadOnlyList<string> Permissions);

public sealed record MembershipSummaryDto(
    Guid MembershipId,
    Guid OrganizationId,
    string OrganizationName,
    string OrganizationSlug,
    bool IsActive,
    IReadOnlyList<string> Roles);

public sealed record OrganizationDto(
    Guid Id,
    string Name,
    string Slug,
    bool IsActive,
    DateTimeOffset CreatedAt);

public sealed record CreateOrganizationRequest(string Name, string Slug);

public sealed record MembershipDto(
    Guid Id,
    Guid OrganizationId,
    Guid UserId,
    string Email,
    string DisplayName,
    bool IsActive,
    IReadOnlyList<string> Roles,
    DateTimeOffset? DisabledAt,
    string? DisabledReason);

public sealed record CreateMembershipRequest(
    string Email,
    string DisplayName,
    string EntraObjectId,
    string RoleCode);

public sealed record DisableMembershipRequest(string Reason);
