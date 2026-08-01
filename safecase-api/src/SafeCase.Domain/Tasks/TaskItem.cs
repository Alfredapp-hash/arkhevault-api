using SafeCase.Domain.Common;

namespace SafeCase.Domain.Tasks;

public class TaskItem : TenantEntity
{
    public Guid? CaseId { get; set; }
    public Guid? ClientId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Status { get; set; } = "open";
    public string Priority { get; set; } = "normal";
    public DateTimeOffset? DueAt { get; set; }
    public Guid? AssignedMembershipId { get; set; }
    public Guid CreatedByMembershipId { get; set; }

    public Cases.Case? Case { get; set; }
}
