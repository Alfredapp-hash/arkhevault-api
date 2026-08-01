using Microsoft.EntityFrameworkCore;

namespace SafeCase.Infrastructure.Persistence;

public static class TenantWriteHelper
{
    public static async Task<T> ExecuteInTenantTransactionAsync<T>(
        SafeCaseDbContext db,
        OrganizationContext organizationContext,
        Guid organizationId,
        Func<CancellationToken, Task<T>> action,
        CancellationToken cancellationToken = default)
    {
        organizationContext.OrganizationId = organizationId;
        await using var tx = await db.Database.BeginTransactionAsync(cancellationToken);
        await db.Database.ExecuteSqlRawAsync(
            "SELECT set_config('app.current_organization_id', {0}, true);",
            organizationId.ToString());
        var result = await action(cancellationToken);
        await tx.CommitAsync(cancellationToken);
        return result;
    }

    public static Task ExecuteInTenantTransactionAsync(
        SafeCaseDbContext db,
        OrganizationContext organizationContext,
        Guid organizationId,
        Func<CancellationToken, Task> action,
        CancellationToken cancellationToken = default)
        => ExecuteInTenantTransactionAsync(db, organizationContext, organizationId, async ct =>
        {
            await action(ct);
            return true;
        }, cancellationToken);
}
