using SafeCase.Domain.Common;

namespace SafeCase.Domain.Cases;

public class Case : TenantEntity
{
    public Guid ClientId { get; set; }
    public string Status { get; set; } = "open";
    public string? Title { get; set; }
    public Guid? OpenedByMembershipId { get; set; }
    public DateTimeOffset? ClosedAt { get; set; }

    public Clients.Client? Client { get; set; }
    public ICollection<CaseAssignment> Assignments { get; set; } = [];
    public ICollection<CaseNote> Notes { get; set; } = [];
    public ICollection<Tasks.TaskItem> Tasks { get; set; } = [];
    public ICollection<CaseTimelineEvent> TimelineEvents { get; set; } = [];
}

public class CaseAssignment : TenantEntity
{
    public Guid CaseId { get; set; }
    public Guid MembershipId { get; set; }
    public string RoleOnCase { get; set; } = "advocate";
    public DateTimeOffset AssignedAt { get; set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset? UnassignedAt { get; set; }

    public Case? Case { get; set; }
}

public class CaseNote : TenantEntity
{
    public Guid CaseId { get; set; }
    public Guid AuthorMembershipId { get; set; }
    public string NoteType { get; set; } = "general";
    public string VisibilityLevel { get; set; } = "standard"; // standard | restricted
    public string Narrative { get; set; } = string.Empty;

    public Case? Case { get; set; }
}

public class CaseTimelineEvent : TenantEntity
{
    public Guid CaseId { get; set; }
    public Guid? ClientId { get; set; }
    public string EventType { get; set; } = string.Empty;
    public string Summary { get; set; } = string.Empty;
    public Guid? ActorMembershipId { get; set; }
    public Guid? RelatedResourceId { get; set; }
    public string? RelatedResourceType { get; set; }

    public Case? Case { get; set; }
}
