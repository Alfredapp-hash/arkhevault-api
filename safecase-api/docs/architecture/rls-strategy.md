# PostgreSQL Row-Level Security Strategy

## Goal

Every tenant-controlled table is protected by:

1. API authorization (membership + permission)
2. EF Core organization filters (Phase 2+)
3. PostgreSQL RLS using `app.current_organization_id`

## Session GUC

The API sets:

```sql
SELECT set_config('app.current_organization_id', '<uuid>', false);
```

Implemented by `TenantConnectionInterceptor`. Fail closed if organization context is missing on tenant-scoped operations (enforced in application services in Phase 2).

## Example policy (apply after migrations)

```sql
ALTER TABLE safecase.cases ENABLE ROW LEVEL SECURITY;
ALTER TABLE safecase.cases FORCE ROW LEVEL SECURITY;

CREATE POLICY cases_tenant_isolation ON safecase.cases
USING (organization_id = NULLIF(current_setting('app.current_organization_id', true), '')::uuid)
WITH CHECK (organization_id = NULLIF(current_setting('app.current_organization_id', true), '')::uuid);
```

Repeat for: `clients`, `client_identities`, `client_contact_methods`, `case_assignments`, `case_notes`, `case_timeline_events`, `tasks`, `audit_events`, `organization_memberships`.

## Migration / break-glass role

A dedicated migration role may bypass RLS. That role must never be used by the App Service runtime identity.

## Tests required

See conversion plan critical tenant tests — implemented in `SafeCase.AuthorizationTests` / IntegrationTests (Phase 2).
