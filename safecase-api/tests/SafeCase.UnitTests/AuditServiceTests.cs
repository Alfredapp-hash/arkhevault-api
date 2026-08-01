using SafeCase.Domain.Audit;
using SafeCase.Infrastructure.Services;

namespace SafeCase.UnitTests;

public class AuditServiceTests
{
    [Theory]
    [InlineData("routine case review", "routine case review")]
    [InlineData("contains password reset attempt", "[redacted]")]
    [InlineData(null, null)]
    public void SanitizeReason_RedactsSensitiveTokens(string? input, string? expected)
    {
        Assert.Equal(expected, AuditService.SanitizeReason(input));
    }

    [Fact]
    public void ComputeHash_IsDeterministic()
    {
        var evt = new AuditEvent
        {
            OrganizationId = Guid.Parse("11111111-1111-1111-1111-111111111111"),
            ActorUserId = Guid.Parse("33333333-3333-3333-3333-333333333333"),
            Action = "client.viewed",
            ResourceType = "client",
            ResourceId = Guid.Parse("44444444-4444-4444-4444-444444444444"),
            Result = "success",
            PreviousHash = null,
            CreatedAt = DateTimeOffset.Parse("2026-08-01T00:00:00Z")
        };

        var hash1 = AuditService.ComputeHash(evt);
        var hash2 = AuditService.ComputeHash(evt);
        Assert.Equal(hash1, hash2);
        Assert.Equal(64, hash1.Length);
    }
}
