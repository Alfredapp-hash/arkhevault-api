# Entra External ID integration notes

Full runbook: `../../safecase-governance/identity/entra-external-id-runbook.md`

## API configuration

| Setting | Purpose |
|---|---|
| `Entra:TenantId` | External tenant ID |
| `Entra:Audience` | API app ID URI / audience |
| `Entra:AuthorityHost` | Usually `{tenant}.ciamlogin.com` |

## Behavior

- When TenantId + Audience are set, JWT bearer auth is enabled.
- When unset, `/api/v1/me` returns a development stub. This must not be used in deployed environments with real data.

## Mapping

```text
Entra oid claim → users.entra_object_id → organization_memberships → roles/permissions
```

SafeCase stores application roles; do not encode all authorization solely in Entra groups.
