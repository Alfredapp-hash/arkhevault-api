# SafeCase Azure Conversion Package

**Date:** 2026-08-01  
**Status:** Authoritative planning package  
**Supersedes:** AWS/Node SaaS plans in repository root markdown files

## Documents in this package

| Doc | Purpose |
|---|---|
| [01-FRESH-AUDIT.md](./01-FRESH-AUDIT.md) | Independent audit of current code vs Azure SaaS requirements |
| [02-CONVERSION-PLAN.md](./02-CONVERSION-PLAN.md) | End-to-end conversion plan, phases, milestones, exit criteria |
| [03-PARALLEL-AGENT-PROMPTS.md](./03-PARALLEL-AGENT-PROMPTS.md) | Copy-paste prompts for expert agents working in parallel |
| [04-DOMAIN-MAPPING.md](./04-DOMAIN-MAPPING.md) | Core Data → PostgreSQL / domain entity mapping |
| [05-FEATURE-DISPOSITION.md](./05-FEATURE-DISPOSITION.md) | Preserve / rewrite / reference / defer matrix |

## Quick verdict

The current repository is a **single-device SwiftUI + Core Data prototype**. It cannot be “uploaded to Azure” as a multi-organization victim-services SaaS product.

The correct path is:

1. Freeze and reclassify this repo as `safecase-macos-prototype`
2. Create `safecase-api`, `safecase-web`, and `safecase-governance`
3. Rebuild authentication, authorization, data, documents, and audit as Azure-hosted services
4. Rebuild the pilot UI as a Next.js web application
5. Keep the Mac app as an optional future client only after the API is authoritative

## Recommended first vertical slice

```text
Entra login
→ organization membership
→ client creation
→ case creation
→ advocate assignment
→ case note
→ task
→ timeline
→ audit record
```

That slice proves browser → identity → API → PostgreSQL → monitoring before feature expansion.
