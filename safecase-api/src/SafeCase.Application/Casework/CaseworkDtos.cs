namespace SafeCase.Application.Casework;

public sealed record CreateClientRequest(
    string FirstName,
    string LastName,
    string? RiskLevel = null,
    bool OpenInitialCase = true,
    string? CaseTitle = null);

public sealed record ClientDto(
    Guid Id,
    Guid OrganizationId,
    string FirstName,
    string LastName,
    string Status,
    string? RiskLevel,
    DateTimeOffset CreatedAt);

public sealed record CreateCaseRequest(string? Title);

public sealed record CaseDto(
    Guid Id,
    Guid OrganizationId,
    Guid ClientId,
    string Status,
    string? Title,
    DateTimeOffset CreatedAt);

public sealed record CreateAssignmentRequest(Guid MembershipId, string RoleOnCase = "advocate");

public sealed record AssignmentDto(
    Guid Id,
    Guid CaseId,
    Guid MembershipId,
    string RoleOnCase,
    DateTimeOffset AssignedAt);

public sealed record CreateNoteRequest(
    string Narrative,
    string NoteType = "general",
    string VisibilityLevel = "standard");

public sealed record NoteDto(
    Guid Id,
    Guid CaseId,
    Guid AuthorMembershipId,
    string NoteType,
    string VisibilityLevel,
    string? Narrative,
    bool IsRedacted,
    DateTimeOffset CreatedAt);

public sealed record CreateTaskRequest(
    string Title,
    string Priority = "normal",
    DateTimeOffset? DueAt = null,
    Guid? AssignedMembershipId = null);

public sealed record TaskDto(
    Guid Id,
    Guid? CaseId,
    Guid? ClientId,
    string Title,
    string Status,
    string Priority,
    DateTimeOffset? DueAt,
    Guid? AssignedMembershipId,
    DateTimeOffset CreatedAt);

public sealed record TimelineEventDto(
    Guid Id,
    Guid CaseId,
    Guid? ClientId,
    string EventType,
    string Summary,
    Guid? ActorMembershipId,
    Guid? RelatedResourceId,
    string? RelatedResourceType,
    DateTimeOffset CreatedAt);

public sealed record VerticalSliceResult(
    ClientDto Client,
    CaseDto Case,
    AssignmentDto Assignment,
    NoteDto Note,
    TaskDto Task,
    IReadOnlyList<TimelineEventDto> Timeline);
