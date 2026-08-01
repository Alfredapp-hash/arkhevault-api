using SafeCase.Domain.Common;

namespace SafeCase.Domain.Audit;

/// <summary>
/// Append-only, server-authoritative audit record.
/// Do not store case narratives, safety-plan text, or contact PII in Reason/metadata.
/// </summary>
public class AuditEvent : TenantEntity
{
    public Guid? ActorUserId { get; set; }
    public Guid? ActorMembershipId { get; set; }
    public string Action { get; set; } = string.Empty;
    public string ResourceType { get; set; } = string.Empty;
    public Guid? ResourceId { get; set; }
    public Guid? CaseId { get; set; }
    public Guid? ClientId { get; set; }
    public string Result { get; set; } = "success";
    public string? Reason { get; set; }
    public string? IpContext { get; set; }
    public string? DeviceContext { get; set; }
    public string CorrelationId { get; set; } = string.Empty;
    public string? PreviousHash { get; set; }
    public string EventHash { get; set; } = string.Empty;
}
