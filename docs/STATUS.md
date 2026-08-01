# SafeCase repository status

**Updated:** 2026-08-01

## Accurate completion statement

| Area | Status |
|---|---|
| macOS SwiftUI workflow prototype | Present (reference only) |
| Azure conversion plan / audit | Complete in `docs/azure-conversion/` |
| API Milestone 1 skeleton | Complete |
| Identity / organizations / memberships (Wave 2) | Complete (local / dev auth) |
| Casework vertical slice (Wave 3) | **Complete (local)** |
| Entra External ID production config | Not configured yet |
| PostgreSQL + EF filters + RLS | Migrations + policies + authz tests passing |
| Web shell + org selector + casework UI | Wired for local dev auth |
| Real survivor/client data | **Forbidden** until Phase 8 signoff |

## Vertical slice (proven)

```text
Sign in (dev) → select org → create client → create case
→ assign advocate → add note → add task → review timeline → audit event
```

API: `POST /api/v1/organizations/{orgId}/workflows/vertical-slice`  
Web: Dashboard → “Run vertical slice”, or Clients / Cases pages.

## Tests (local)

- UnitTests: 6
- ArchitectureTests: 2
- AuthorizationTests: 9 (tenant isolation + vertical slice + IDOR fail-closed)

## Next

Wave 4: safety plans, consent, Level 4 controls; then documents/referrals.
