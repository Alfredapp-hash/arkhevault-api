# SafeCase repository status

**Updated:** 2026-08-01

## Accurate completion statement

| Area | Status |
|---|---|
| macOS SwiftUI workflow prototype | Present (reference only) |
| Azure-compatible multi-tenant SaaS | **Not complete** — scaffolding started |
| Entra External ID login in production path | Not configured yet |
| Authoritative PostgreSQL + RLS | Schema/migration scaffolded; RLS policies documented, not yet enforced in deployed env |
| Web vertical slice (client→case→note→audit) | Shell only |
| Real survivor/client data | **Forbidden** until Phase 8 signoff |

## Monorepo layout (temporary)

Sibling repos from the conversion plan are scaffolded in-tree so work can proceed before GitHub repo splits:

| Path | Intended eventual repo |
|---|---|
| `/` (App, Core, Features, …) | `safecase-macos-prototype` |
| `safecase-api/` | `safecase-api` |
| `safecase-web/` | `safecase-web` |
| `safecase-governance/` | `safecase-governance` |
| `docs/azure-conversion/` | Shared conversion package |

## Next implementation targets

1. Configure Entra External ID (human Azure tenant work)
2. Membership/role APIs + tenant EF filters + RLS SQL apply
3. Vertical slice APIs + web UI
4. Split monorepo folders into dedicated GitHub repositories when ready
