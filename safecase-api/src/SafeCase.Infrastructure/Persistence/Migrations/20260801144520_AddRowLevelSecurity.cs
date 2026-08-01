using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SafeCase.Infrastructure.Persistence.Migrations;

/// <inheritdoc />
public partial class AddRowLevelSecurity : Migration
{
    private static readonly string[] TenantTables =
    [
        "Clients",
        "ClientIdentities",
        "ClientContactMethods",
        "cases",
        "CaseAssignments",
        "CaseNotes",
        "CaseTimelineEvents",
        "tasks",
        "AuditEvents"
    ];

    /// <inheritdoc />
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        foreach (var table in TenantTables)
        {
            migrationBuilder.Sql($"""
                ALTER TABLE safecase."{table}" ENABLE ROW LEVEL SECURITY;
                ALTER TABLE safecase."{table}" FORCE ROW LEVEL SECURITY;
                DROP POLICY IF EXISTS tenant_isolation ON safecase."{table}";
                CREATE POLICY tenant_isolation ON safecase."{table}"
                USING (
                    "OrganizationId" = NULLIF(current_setting('app.current_organization_id', true), '')::uuid
                )
                WITH CHECK (
                    "OrganizationId" = NULLIF(current_setting('app.current_organization_id', true), '')::uuid
                );
                """);
        }
    }

    /// <inheritdoc />
    protected override void Down(MigrationBuilder migrationBuilder)
    {
        foreach (var table in TenantTables)
        {
            migrationBuilder.Sql($"""
                DROP POLICY IF EXISTS tenant_isolation ON safecase."{table}";
                ALTER TABLE safecase."{table}" NO FORCE ROW LEVEL SECURITY;
                ALTER TABLE safecase."{table}" DISABLE ROW LEVEL SECURITY;
                """);
        }
    }
}
