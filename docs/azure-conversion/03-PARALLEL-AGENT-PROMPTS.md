# Parallel Expert-Agent Prompts

Use these prompts with Cursor cloud agents, coding agents, or specialist contractors.  
Each prompt is self-contained. Run **Wave 0** first (or in tight sequence), then launch **Wave 1** agents in parallel.

**Shared context every agent should receive:**
- Product: SafeCase — victim-services multi-tenant SaaS
- Source prototype: this repo (`safecase-macos-prototype` / current `arkhevault-api`)
- Plan package: `docs/azure-conversion/`
- Stack: Entra External ID, ASP.NET Core 10, EF Core, PostgreSQL Flexible Server + RLS, Blob, Key Vault, Next.js, Bicep, GitHub OIDC
- Rule: synthetic data only; no real survivor/client PII
- Rule: client never owns authz or authoritative data

---

## Dependency graph

```text
W0-A Prototype freeze     ──┐
W0-B Create empty repos   ──┼──→ Wave 1 parallel
W0-C Governance skeleton  ──┘

W1-A Infra Bicep ──────────────┐
W1-B API skeleton ─────────────┤
W1-C Web skeleton ─────────────┼──→ W2-* ──→ W3-* ──→ W4-* ──→ W5-*
W1-D Domain schema extract ────┤
W1-E Entra External ID setup ──┤
W1-F CI/CD OIDC templates ─────┘
```

---

## Wave 0 — Freeze and classify

### Prompt W0-A — Prototype freeze & disposition

```text
You are a staff engineer converting SafeCase from a macOS SwiftUI prototype to Azure SaaS.

Repository: the current SafeCase / arkhevault-api macOS prototype.
Authoritative plan: docs/azure-conversion/ (especially 01-FRESH-AUDIT.md, 05-FEATURE-DISPOSITION.md).

Tasks:
1. Ensure README has a highly visible Prototype Status warning forbidding real survivor/victim/PII data.
2. Add docs/azure-conversion/ADR-0001-prototype-freeze.md recording that this repo is not production and must not grow Azure production code.
3. Verify/update 05-FEATURE-DISPOSITION.md against actual Features/* and Core/Services/* files; fix any drift.
4. Add a short SUPERSEDED banner at the top of UPGRADE_PASS_2_SAAS_INFRASTRUCTURE.md, MASTER_UPGRADE_ROADMAP.md, EXECUTION_CHECKLIST_ORDERED.md, SECURITY_AUDIT_REPORT.md pointing to docs/azure-conversion/.
5. Do not implement Azure services in this repo.
6. Open a PR titled “Phase 0: freeze SafeCase macOS prototype”.

Acceptance:
- Warning is unmissable in README
- Prior AWS/security overclaims are clearly superseded
- Feature disposition covers every Features/* module and Core/Services/* file
```

### Prompt W0-B — Bootstrap sibling repositories

```text
You are a platform engineer bootstrapping the SafeCase multi-repo layout.

Create (or scaffold in the org) three repositories with README stubs and LICENSE/CODEOWNERS placeholders:

1) safecase-api
   - Solution folders matching:
     src/SafeCase.Api, Application, Domain, Infrastructure, Workers
     tests/Unit, Integration, Authorization, Architecture
     infrastructure/bicep, docs, .github/workflows
   - README stating ASP.NET Core 10 + Entra External ID + PostgreSQL + Bicep goals
   - .gitignore for .NET / .netlify / IDE / secrets

2) safecase-web
   - Next.js App Router + TypeScript + Tailwind scaffolding (or documented create command)
   - folders: app, components, features, lib, types, tests, docs, .github/workflows
   - README stating MSAL/Entra browser-delegated auth and API consumption

3) safecase-governance
   - Empty stubs for:
     data-classification.md, threat-model.md, privacy-impact-assessment.md,
     retention-policy.md, incident-response.md, access-control-matrix.md,
     pilot-operating-procedures.md, organization-onboarding.md,
     security-acceptance-criteria.md

Also produce a short REPO_MAP.md explaining how the four repos relate (including safecase-macos-prototype rename of the current repo).

Do not invent fake Azure resource IDs. Do not commit secrets.
Return: repo URLs, initial commit SHAs, and next Wave 1 handoff notes.
```

### Prompt W0-C — Governance skeleton content

```text
You are a security/privacy lead for a victim-services SaaS (SafeCase).

Using docs/azure-conversion/01-FRESH-AUDIT.md and 02-CONVERSION-PLAN.md, draft initial content (not final legal advice) in safecase-governance for:

1. Data classification policy Levels 0–4 with SafeCase examples
2. Access-control matrix: roles × permissions for Phase 2–4 features
3. Security acceptance criteria for calling the system “pilot-ready”
4. Pilot operating procedures outline (no real data until Phase 8 signoff)
5. Threat model v0 (STRIDE against Entra, API, Postgres RLS, Blob, staff misuse, export abuse)

Constraints:
- Assume Microsoft Entra External ID, ASP.NET Core API, PostgreSQL RLS, Blob, Key Vault
- Explicitly ban Level 4 data in analytics/AI prompts by default
- Mark every document DRAFT / PENDING LEGAL REVIEW

Deliver PR-ready markdown and a checklist of what needs counsel/compliance signoff.
```

---

## Wave 1 — Parallel foundation (launch together)

### Prompt W1-A — Azure Bicep baseline

```text
You are an Azure infrastructure engineer.

Repo: safecase-api (infrastructure/bicep).
Goal: Phase 1 / Milestone 1 skeleton — reproducible dev environment.

Build Bicep for a DEVELOPMENT subscription layout:
- Resource groups pattern (network/app/data/security/monitoring) OR a simplified single RG for dev with modules ready to split for prod
- Modules: network (optional for early dev), app-service (API), postgresql flexible server (burstable/dev), storage account + private blob container config, key vault, log analytics, application insights, managed identity
- environments/dev.bicepparam (and stubs for staging/prod)
- Naming + tagging standards (env, app=safecase, owner, data-classification)
- Outputs: API hostname, Key Vault URI, Postgres FQDN, Storage account name, App Insights connection string secret reference pattern
- README with deploy commands using az deployment and GitHub OIDC notes

Constraints:
- No secrets in git
- Prefer managed identity connections
- Postgres should support SSL; document private endpoint as prod-only follow-up
- Dev tier must be stoppable/inexpensive where possible
- Include what-if / validation guidance

Acceptance: `az bicep build` succeeds; docs explain destroy/recreate from source.
```

### Prompt W1-B — ASP.NET Core API skeleton

```text
You are a principal .NET engineer.

Repo: safecase-api
Plan: docs/azure-conversion/02-CONVERSION-PLAN.md

Implement Milestone 1 API skeleton:
1. Clean architecture projects: Api, Application, Domain, Infrastructure, Workers (Workers can be stub)
2. ASP.NET Core 10 Web API with:
   - /health and /health/ready
   - OpenAPI
   - ProblemDetails error handling (no stack traces in production)
   - OpenTelemetry → Application Insights ready
   - Configuration via env / Key Vault references (document Netlify/Azure style; use IConfiguration, no hardcoded secrets)
3. EF Core PostgreSQL provider wired with empty DbContext and migration scaffolding
4. Placeholder auth middleware hook for Entra JWT (can be feature-flagged/dev-bypass ONLY for local Testcontainers tests, never for deployed defaults)
5. xUnit unit tests for health/error pipeline; Testcontainers project stub
6. Dockerfile or App Service publish profile docs
7. README with local run using docker-compose Postgres

Do NOT implement full domain CRUD yet. Do NOT add custom username/password auth.

Acceptance: solution builds; tests run; health endpoint works locally against Postgres.
```

### Prompt W1-C — Next.js web skeleton

```text
You are a senior Next.js engineer.

Repo: safecase-web
Goal: pilot shell ready for Entra + API integration.

Scaffold:
- Next.js App Router, TypeScript, Tailwind, ESLint, Prettier
- shadcn/ui baseline
- App shell layout: top bar brand “SafeCase”, org selector placeholder, role-aware nav placeholders matching conversion map (Dashboard, Clients, Cases, Tasks, Timeline, Settings)
- lib/api client stub with typed error handling for RFC7807 ProblemDetails
- Auth route placeholders for MSAL / Entra browser-delegated login (document env vars; do not hardcode tenant IDs if unknown — use env)
- Playwright smoke test (app loads)
- axe-core accessibility smoke on shell
- Responsive desktop/tablet layout; avoid generic purple SaaS aesthetic; follow accessible, calm victim-services visual direction (no dark-mode-by-default, no emoji clutter)

Out of scope: full client CRUD, offline, AI.

Acceptance: `pnpm/npm` build + playwright smoke pass; README documents required Entra app registration env vars.
```

### Prompt W1-D — Domain schema extraction & EF model v0

```text
You are a domain modeler / data architect.

Inputs:
- Prototype Core Data model: Core/Data/ForgedInFireDataModel.xcdatamodeld/contents in safecase-macos-prototype
- Target entities in docs/azure-conversion/04-DOMAIN-MAPPING.md and 02-CONVERSION-PLAN.md §5

Deliver in safecase-api:
1. docs/architecture/core-data-inventory.md — every entity/field/relationship from Core Data
2. docs/architecture/domain-model-v0.md — normalized aggregates for Azure
3. EF Core entities + first migration for Phase 2–3 foundations ONLY:
   - organizations, users, memberships, roles, permissions
   - clients (+ separated identity tables as designed)
   - cases, case_assignments, case_notes, tasks, case_timeline_events
   - audit_events
   - organization_id on every tenant table
4. Document RLS strategy (SQL policies + how API sets app.current_organization_id)
5. Synthetic seed plan for Org A and Org B

Rules:
- UUIDs everywhere
- No sequential public IDs
- Do not migrate prototype SQLite data
- Mark Level 3/4 fields in docs
- Optimistic concurrency tokens where updates exist

Acceptance: migration applies on empty Postgres; seed creates two isolated orgs.
```

### Prompt W1-E — Entra External ID setup runbook

```text
You are an identity engineer specializing in Microsoft Entra External ID.

Produce safecase-governance/docs/identity/entra-external-id-runbook.md and safecase-api/docs/auth/entra.md covering:

1. Why External ID (not B2C for new customers)
2. Tenant creation checklist
3. App registrations: spa (safecase-web) + api (safecase-api) with scopes
4. Browser-delegated auth / authorization code + PKCE for web
5. Token validation requirements for ASP.NET Core (issuer, audience, roles vs app roles)
6. Mapping: Entra object ID → SafeCase User → Memberships → Permissions
7. MFA / Conditional Access recommendations for staff
8. Invitation/onboarding flow outline for Organization Administrator
9. Disablement: Entra disable vs membership disable (both required behaviors)
10. Local development story without storing passwords in SafeCase

Also provide ASP.NET Core Program.cs auth configuration snippet and Next.js MSAL config snippet using env vars.

Do not implement custom password reset in SafeCase.
Deliverables are documentation + code snippets in the correct repos; if credentials are needed, list human steps only.
```

### Prompt W1-F — GitHub Actions OIDC + quality gates

```text
You are a DevOps engineer.

Repos: safecase-api and safecase-web.

Create GitHub Actions workflows:

safecase-api:
- PR: restore, build, unit tests, integration tests (Testcontainers if ready), format, vulnerable package scan, secret scan, Bicep lint/build, publish artifact
- main: deploy to Azure App Service (dev) via OIDC federated credential
- Document Azure federated identity credential setup (no long-lived secrets)

safecase-web:
- PR: install, lint, typecheck, unit/a11y smoke, Playwright
- main: deploy to Azure Static Web Apps or App Service (dev) via OIDC

Include branch protection recommendations and required status checks list.
No client secrets in repo. Provide example GitHub environment protection for staging/prod approvals.
```

---

## Wave 2 — Identity, tenancy, audit (parallel after M1)

### Prompt W2-A — Identity & organization APIs

```text
You are a backend engineer implementing SafeCase Phase 2.

Repo: safecase-api
Depends on: W1-B API skeleton, W1-D schema, W1-E Entra docs.

Implement:
- JWT bearer auth against Entra External ID
- Upsert SafeCase User on first authenticated request
- Organizations CRUD (platform operator / org owner constraints)
- Invitations + memberships
- Roles + permission grants
- /api/v1/me and organization selector payload
- Membership disablement blocks org access
- Sign-in / auth failure audit events (no passwords logged)

Authorization tests MUST prove:
- User without membership cannot access org routes
- Disabled membership cannot access
- User can belong to multiple orgs and switch context safely
- Cross-tenant ID access returns 404-equivalent without existence leak

Use FluentValidation + ProblemDetails. No local password storage tables.
```

### Prompt W2-B — Tenant RLS & query filters

```text
You are a PostgreSQL + EF Core specialist.

Repo: safecase-api

Implement three-layer tenancy:
1. IOrganizationContext from auth + explicit org header/route
2. Global EF query filters on organization_id
3. PostgreSQL RLS policies using SET LOCAL app.current_organization_id per connection/transaction

Integration tests with Testcontainers:
- Org A data invisible to Org B connection context
- Service role/migration bypass documented and locked down
- Background job tenant context helper

Fail closed if organization context missing on tenant-scoped operations.
Document operational runbooks for emergency break-glass (if any) under governance, not as default API behavior.
```

### Prompt W2-C — Audit event foundation

```text
You are a compliance-minded backend engineer.

Repo: safecase-api

Implement AuditEvent write path used by application services:
Fields: event_id, timestamp, organization_id, actor_user_id, actor_membership_id, action, resource_type, resource_id, case_id, client_id, result, reason, ip_context, device_context, correlation_id, previous_hash, event_hash

Requirements:
- Append-only repository API (no update/delete from app services)
- Hash chaining per organization (document concurrency approach)
- Redaction policy: never store narrative/safety-plan/phone/email contents in audit payload
- Application Insights: technical telemetry only; correlate via trace/correlation IDs
- Unit tests for hash chain + redaction

Provide /api/v1/audit-events read API restricted by audit.review permission, tenant-scoped.
```

### Prompt W2-D — Web auth + org selector

```text
You are a frontend engineer.

Repo: safecase-web
Depends on: W1-C shell, W1-E Entra, W2-A APIs.

Implement:
- Browser-delegated Entra login/logout
- Token acquisition for API scope
- Call /api/v1/me
- Organization selector; persist selected org securely for session
- Gate routes until org selected
- Friendly error states for disabled membership / no memberships
- Playwright: login mock or Entra test tenant flow documented

Do not build a local username/password form.
```

---

## Wave 3 — Functional MVP vertical slice (parallel by feature, shared contracts)

### Prompt W3-CONTRACT — OpenAPI contract first

```text
You are an API designer.

Before feature agents diverge, publish OpenAPI 3.1 for the Milestone 3 vertical slice in safecase-api:

Endpoints for:
- POST/GET clients (org-scoped)
- POST/GET cases
- POST case assignments
- POST/GET case notes
- POST/GET tasks
- GET case timeline
- GET audit events (already may exist)

Include permission requirements, validation rules, problem types, and example payloads with synthetic data only.
Freeze the contract in docs/api/v1-mvp.md and generated swagger; feature agents must implement against it.
```

### Prompt W3-A — Clients & cases API

```text
Implement clients + cases + assignments against the frozen OpenAPI contract.
Enforce client.create/client.read/case.* permissions, tenant scope, optimistic concurrency, audit events, separated ClientIdentity storage, non-sequential UUIDs.
Authorization tests for cross-tenant denial.
Synthetic seed updates for two orgs.
```

### Prompt W3-B — Notes, tasks, timeline API

```text
Implement case notes, tasks, and timeline event projection for the vertical slice.
Notes must support visibility levels; restricted notes require note.read_restricted.
Every create/update writes audit events without storing full narrative in App Insights.
Timeline is derived from authoritative events, not client-side invention.
```

### Prompt W3-C — Web vertical slice UI

```text
In safecase-web, implement the end-to-end UI for:
Sign in → select org → create client → create case → assign advocate → add note → add task → review timeline → show audit access (for permitted role).

Use React Hook Form + Zod. Role-aware nav. Playwright e2e covering the happy path with mocked or test API. axe checks on each major step.
Desktop/tablet first. No offline. No AI. No cards-for-decoration clutter; keep one job per section.
```

### Prompt W3-D — Authorization test battery

```text
Expand SafeCase.AuthorizationTests to cover the critical tenant matrix from the conversion plan §7 (cross-org read, IDOR, admin scope, search leak, export leak if any, document URL N/A yet, audit scope, error non-enumeration).
These tests are merge-blocking for Milestone 3.
```

---

## Wave 4 — SafeCase-specific protections (after M3)

### Prompt W4-A — Consent & information sharing

```text
Implement ConsentRecord, ConsentScope, ConsentRevocation, InformationSharingAuthorization.
APIs + enforcement points that block referral/document sharing when consent missing/expired/revoked.
Audit all grant/revoke. Web UI for consent lifecycle. Tests for revoke-blocks-share.
```

### Prompt W4-B — Safety plans & Level 4 controls

```text
Implement safety plans, risk assessments, safe-contact preferences, confidential location handling.
Apply Level 4 controls: narrower permissions, stricter audit alerts, field redaction, restricted exports, never send to analytics/AI.
Emergency access flow requires reason + alert event.
Web: restricted workspace UX that makes sensitivity visible without theatrical dark-mode.
```

### Prompt W4-C — Documents (Blob) pipeline

```text
Implement document metadata in Postgres + Azure Blob:
- request upload authorization → short-lived upload → metadata + checksum + malware scan status → audit
- download via short-lived authorization; no permanent Blob URLs
- path organizations/{org}/clients/{client}/documents/{doc}
- content-type allowlist, size limits, filename normalization
- Functions/Service Bus worker stub for malware scan
Integration tests ensuring cross-tenant URL reuse fails.
```

### Prompt W4-D — Referrals

```text
Implement referral directory + consent-controlled referral sharing + follow-up.
Recipients receive only approved fields. Audit share events. Web UI for referral list/create/follow-up.
```

---

## Wave 5 — Pilot administration & hardening

### Prompt W5-A — Reporting (deidentified)

```text
Build aggregate/deidentified reporting APIs and web views for program metrics and grant reporting.
Default exclude direct identifiers. Permission report.generate. Audit export events. Watermark exports if files are produced.
```

### Prompt W5-B — Org admin & audit review UI

```text
Web + API for organization user administration, role assignment, and audit-review dashboard.
Support staff must not casually read case narratives; implement support break-glass only if governance defines it.
```

### Prompt W5-C — Pen-test prep & backup restore evidence

```text
Produce hardening pack in safecase-governance:
- threat model update against implemented system
- backup restoration test procedure + evidence template
- DR exercise script
- incident response contacts template
- external pen-test scope for Entra, API, RLS, Blob, export, IDOR
Coordinate with infra to run a restore drill in staging and record results.
```

---

## Cross-cutting agent prompts (can run anytime after Wave 0)

### Prompt X-1 — Core Data → requirements translator

```text
Read each Features/*/Views/*.swift file and produce safecase-web/docs/requirements/<feature>.md capturing:
- user goal
- fields shown
- validations implied
- role assumptions
- data classification guess (0–4)
- API endpoints needed
- what must NOT be ported (local auth, local encryption theater, offline full DB, client AI keys)

This feeds web/API implementation without copying insecure patterns.
```

### Prompt X-2 — Documentation truth repair

```text
In safecase-macos-prototype, add banners to overclaiming docs and create docs/STATUS.md stating accurate completion: prototype UI vs SaaS readiness.
Do not delete historical docs; supersede them.
```

### Prompt X-3 — Architecture Decision Records

```text
Create ADRs in safecase-api/docs/decisions/:
- ADR-001 Entra External ID over local passwords / B2C
- ADR-002 ASP.NET Core over Node for SafeCase Azure
- ADR-003 Shared DB + RLS tenancy for pilot
- ADR-004 No full offline in v1
- ADR-005 AI deferred until core controls exist
- ADR-006 Blob for documents, not Postgres bytea / local disk
Each ADR: context, decision, consequences, alternatives rejected.
```

---

## Suggested parallel launch sets

### Day-0 launch (immediately)

| Agent | Prompt |
|---|---|
| A | W0-A |
| B | W0-B |
| C | W0-C |
| D | X-2 |
| E | X-3 |

### Day-1 launch (repos exist)

| Agent | Prompt |
|---|---|
| F | W1-A |
| G | W1-B |
| H | W1-C |
| I | W1-D |
| J | W1-E |
| K | W1-F |
| L | X-1 |

### After M1 green

| Agent | Prompt |
|---|---|
| M | W2-A |
| N | W2-B |
| O | W2-C |
| P | W2-D |

### After M2 green

| Agent | Prompt |
|---|---|
| Q | W3-CONTRACT (first, short) |
| R/S/T/U | W3-A, W3-B, W3-C, W3-D in parallel after contract freeze |

---

## Handoff checklist between waves

Before starting Wave 2:
- [ ] Prototype warning merged  
- [ ] api/web/governance repos exist  
- [ ] Bicep deploys health API to dev  
- [ ] Postgres + Key Vault + App Insights connected via managed identity  
- [ ] CI OIDC works without long-lived secrets  

Before starting Wave 3:
- [ ] Entra login works in web  
- [ ] Memberships/roles enforce  
- [ ] RLS tests pass  
- [ ] Audit write path exists  

Before pilot data:
- [ ] Phases 5–8 exit criteria met  
- [ ] Written security signoff  
- [ ] Synthetic-only affirmation until then  
