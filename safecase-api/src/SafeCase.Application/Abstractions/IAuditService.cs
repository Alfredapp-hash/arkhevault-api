namespace SafeCase.Application.Abstractions;

public sealed record AuditWriteRequest(
    string Action,
    string ResourceType,
    Guid? ResourceId = null,
    Guid? CaseId = null,
    Guid? ClientId = null,
    string Result = "success",
    string? Reason = null);

public interface IAuditService
{
    Task WriteAsync(AuditWriteRequest request, CancellationToken cancellationToken = default);
}
