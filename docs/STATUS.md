# SafeCase repository status

**Updated:** 2026-08-01

## Accurate completion statement

| Area | Status |
|---|---|
| macOS SwiftUI workflow prototype | Present (reference only) |
| Azure conversion plan / audit | Complete in `docs/azure-conversion/` |
| API Milestone 1 skeleton | Complete |
| Identity / organizations / memberships (Wave 2) | **In progress / local complete** |
| Entra External ID production config | Not configured yet (dev auth header for local only) |
| PostgreSQL + EF filters + RLS | Migrations + policies + authz tests passing locally |
| Web shell + org selector against `/me` | Wired for local dev auth |
| Vertical slice (client→case→note→task→timeline→audit UI) | Not started |
| Real survivor/client data | **Forbidden** until Phase 8 signoff |

## How to run Wave 2 locally

```bash
# API
cd safecase-api
# Postgres required (local service or docker compose)
dotnet run --project src/SafeCase.Api
# Dev headers: X-Dev-User: dev-org-a-admin

# Web
cd safecase-web
cp .env.example .env.local
pnpm install && pnpm dev
```

## Test counts (local)

- UnitTests: 6 passed
- ArchitectureTests: 2 passed
- AuthorizationTests: 7 passed (tenant isolation, disable membership, IDOR fail-closed)

## Next

Wave 3 vertical slice APIs + web: client create → case → assign → note → task → timeline → audit review.
