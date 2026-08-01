using System.Data.Common;
using Microsoft.EntityFrameworkCore.Diagnostics;

namespace SafeCase.Infrastructure.Persistence;

/// <summary>
/// Sets PostgreSQL session GUC used by row-level security policies.
/// Fail-closed callers should refuse tenant work when OrganizationId is null.
/// </summary>
public sealed class TenantConnectionInterceptor(IOrganizationContext organizationContext) : DbConnectionInterceptor
{
    public override async Task ConnectionOpenedAsync(
        DbConnection connection,
        ConnectionEndEventData eventData,
        CancellationToken cancellationToken = default)
    {
        if (organizationContext.OrganizationId is { } orgId)
        {
            await using var command = connection.CreateCommand();
            command.CommandText = "SELECT set_config('app.current_organization_id', @orgId, false);";
            var parameter = command.CreateParameter();
            parameter.ParameterName = "orgId";
            parameter.Value = orgId.ToString();
            command.Parameters.Add(parameter);
            await command.ExecuteNonQueryAsync(cancellationToken);
        }

        await base.ConnectionOpenedAsync(connection, eventData, cancellationToken);
    }
}

public interface IOrganizationContext
{
    Guid? OrganizationId { get; set; }
}

public sealed class OrganizationContext : IOrganizationContext
{
    public Guid? OrganizationId { get; set; }
}
