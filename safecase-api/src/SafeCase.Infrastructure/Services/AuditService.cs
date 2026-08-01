using System.Security.Cryptography;
using System.Text;
using Microsoft.EntityFrameworkCore;
using SafeCase.Application.Abstractions;
using SafeCase.Domain.Audit;
using SafeCase.Infrastructure.Persistence;

namespace SafeCase.Infrastructure.Services;

public sealed class AuditService(
    SafeCaseDbContext db,
    ICurrentUser currentUser,
    IOrganizationContext organizationContext) : IAuditService
{
    private static readonly HashSet<string> ForbiddenReasonTokens =
    [
        "password", "ssn", "social security", "diagnosis", "allegation"
    ];

    public async Task WriteAsync(AuditWriteRequest request, CancellationToken cancellationToken = default)
    {
        var orgId = currentUser.OrganizationId ?? organizationContext.OrganizationId;
        if (orgId is null || orgId == Guid.Empty)
        {
            // Tenant audit requires an organization; skip rather than writing outside RLS.
            return;
        }

        organizationContext.OrganizationId = orgId;

        await using var tx = await db.Database.BeginTransactionAsync(cancellationToken);
        await db.Database.ExecuteSqlRawAsync(
            "SELECT set_config('app.current_organization_id', {0}, true);",
            orgId.Value.ToString());

        var reason = SanitizeReason(request.Reason);
        var previousHash = await db.AuditEvents.IgnoreQueryFilters()
                .Where(x => x.OrganizationId == orgId)
                .OrderByDescending(x => x.CreatedAt)
                .Select(x => x.EventHash)
                .FirstOrDefaultAsync(cancellationToken);

        var evt = new AuditEvent
        {
            OrganizationId = orgId.Value,
            ActorUserId = currentUser.UserId,
            ActorMembershipId = currentUser.MembershipId,
            Action = request.Action,
            ResourceType = request.ResourceType,
            ResourceId = request.ResourceId,
            CaseId = request.CaseId,
            ClientId = request.ClientId,
            Result = request.Result,
            Reason = reason,
            CorrelationId = Guid.CreateVersion7().ToString("N")[..16],
            PreviousHash = previousHash,
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow
        };

        evt.EventHash = ComputeHash(evt);
        db.AuditEvents.Add(evt);
        await db.SaveChangesAsync(cancellationToken);
        await tx.CommitAsync(cancellationToken);
    }

    internal static string? SanitizeReason(string? reason)
    {
        if (string.IsNullOrWhiteSpace(reason))
        {
            return null;
        }

        var trimmed = reason.Trim();
        if (trimmed.Length > 500)
        {
            trimmed = trimmed[..500];
        }

        var lower = trimmed.ToLowerInvariant();
        if (ForbiddenReasonTokens.Any(token => lower.Contains(token, StringComparison.Ordinal)))
        {
            return "[redacted]";
        }

        return trimmed;
    }

    internal static string ComputeHash(AuditEvent evt)
    {
        var payload = string.Join('|',
            evt.OrganizationId,
            evt.ActorUserId,
            evt.Action,
            evt.ResourceType,
            evt.ResourceId,
            evt.Result,
            evt.PreviousHash,
            evt.CreatedAt.ToUnixTimeMilliseconds());
        var bytes = SHA256.HashData(Encoding.UTF8.GetBytes(payload));
        return Convert.ToHexString(bytes).ToLowerInvariant();
    }
}
