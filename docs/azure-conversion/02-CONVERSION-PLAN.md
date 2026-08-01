# SafeCase Azure Conversion Plan

**Status:** Authoritative  
**Audience:** Product, engineering, security, pilot operations  
**Related:** [01-FRESH-AUDIT.md](./01-FRESH-AUDIT.md), [03-PARALLEL-AGENT-PROMPTS.md](./03-PARALLEL-AGENT-PROMPTS.md)

---

## 1. North star

Rebuild SafeCase as three connected layers:

```text
SafeCase Web Application (Next.js)
        ↓
SafeCase Azure API (ASP.NET Core 10)
        ↓
Azure-hosted database, documents, identity, audit
```

The existing SwiftUI app remains a **workflow prototype** and later optional desktop client. It must not own authentication, authorization, business rules, or authoritative client data.

---

## 2. Repository strategy

Do **not** keep bolting Azure code into the current monolith without reorganization.

| Repo | Rename / create | Purpose |
|---|---|---|
| Current `arkhevault-api` | → `safecase-macos-prototype` | Preserve SwiftUI workflows; synthetic data only |
| New | `safecase-api` | ASP.NET Core API, workers, Bicep, tests |
| New | `safecase-web` | Next.js pilot UI |
| New (optional then required for pilot) | `safecase-governance` | Threat model, PIA, retention, IR, access matrix |

### Suggested `safecase-api` layout

```text
safecase-api/
├── src/
│   ├── SafeCase.Api/
│   ├── SafeCase.Application/
│   ├── SafeCase.Domain/
│   ├── SafeCase.Infrastructure/
│   └── SafeCase.Workers/
├── tests/
│   ├── SafeCase.UnitTests/
│   ├── SafeCase.IntegrationTests/
│   ├── SafeCase.AuthorizationTests/
│   └── SafeCase.ArchitectureTests/
├── infrastructure/
│   ├── bicep/
│   ├── environments/
│   └── policies/
├── docs/
├── .github/workflows/
├── SafeCase.sln
└── README.md
```

### Suggested `safecase-web` layout

```text
safecase-web/
├── app/
├── components/
├── features/
├── lib/
├── types/
├── tests/
├── public/
├── docs/
└── .github/workflows/
```

---

## 3. Technology stack (locked for pilot)

### Frontend
- Next.js, TypeScript, React, Tailwind CSS
- shadcn/ui (or controlled internal library)
- React Hook Form + Zod
- MSAL where appropriate
- Playwright + axe-core

### Backend
- ASP.NET Core 10 Web API, C#
- EF Core + PostgreSQL provider
- FluentValidation, OpenAPI, OpenTelemetry
- xUnit + Testcontainers

### Azure services
- Entra External ID (not Azure AD B2C for new customers)
- App Service (API), Static Web Apps or App Service (web)
- PostgreSQL Flexible Server
- Blob Storage, Key Vault
- Service Bus + Functions for async work
- Monitor, Application Insights, Log Analytics
- Managed identities; private endpoints in production
- Front Door + WAF later

### Explicit non-goals for Milestone 1–3
- Full offline org database on devices
- Client-held AI provider keys
- Feature parity with every Mac screen
- Phone-first full case management

---

## 4. Conversion principles

1. **API decides.** Client displays and requests; API permits or denies.  
2. **No local passwords.** Entra owns credentials; SafeCase stores memberships/roles.  
3. **Tenant on every row.** `organization_id` + API filters + PostgreSQL RLS.  
4. **Classify before store/log.** Levels 0–4; Level 4 gets stricter controls.  
5. **Documents never live as authoritative blobs in Postgres or on laptops.**  
6. **Audit is server-authoritative and immutable.**  
7. **Telemetry ≠ case content.** App Insights gets technical/pseudonymous IDs only.  
8. **IaC or it doesn’t exist.** No critical portal-only config.  
9. **Prototype data is not migrated** (Scenario A).  
10. **Vertical slice before breadth.**

---

## 5. Domain conversion

Before writing feature-heavy Azure code, extract and normalize the domain.

### Principal aggregates for v1 platform

**Organizations:** Organization, OrganizationSettings, OrganizationLocation, OrganizationProgram, OrganizationMembership, OrganizationInvitation  

**Identity:** User, Membership, Role, Permission, AccessPolicy, AccessGrant, EmergencyAccessEvent  

**Survivors/clients:** Client, ClientIdentity, ClientContactMethod, ClientAlias, ClientAddress, ClientRiskProfile, ClientCommunicationPreference  

**Cases:** Case, CaseAssignment, CaseStatus, CaseNote, CaseTimelineEvent, CaseOutcome, CaseClosure  

**Consent / Safety / Services / Documents / Tasks / Audit / Reporting** — as listed in the product plan; map from Core Data in [04-DOMAIN-MAPPING.md](./04-DOMAIN-MAPPING.md).

### Core Data → Postgres strategy

**Scenario A (now):**  
- Do not migrate prototype SQLite  
- Publish schema reference from `.xcdatamodeld`  
- Clean EF Core migrations  
- Synthetic seed for two test orgs  

**Scenario B (later, only if real Mac data exists):**  
Controlled exporter → encrypted package → scan → staging import → reconciliation → approved production import → destroy temp export.

---

## 6. Identity and authorization

### Remove
- Local password hashing / Keychain credential establishment  
- Core Data Staff as auth source of truth  
- Biometric-only authorization  
- Client-stored provider keys  

### Add
- Entra External ID external tenant  
- Browser-delegated OIDC login  
- API JWT validation  
- SafeCase User linked by Entra object ID  
- Memberships, roles, granular permissions  

### Roles (application-stored, not only Entra groups)

Platform Operator, Organization Owner, Organization Administrator, Program Director, Supervisor, Advocate, Intake Specialist, Referral Partner, Report Analyst, Auditor, Read-Only Reviewer, Survivor Portal User

### Example permissions

`client.read`, `client.create`, `client.update_identity`, `case.read`, `case.assign`, `case.close`, `note.create`, `note.read_restricted`, `document.upload`, `document.download`, `document.share`, `consent.manage`, `report.generate`, `audit.review`, `organization.manage_users`

---

## 7. API design

### Modules

`/api/v1/auth`, `/me`, `/organizations`, `/memberships`, `/clients`, `/cases`, `/intakes`, `/safety-plans`, `/consents`, `/referrals`, `/documents`, `/tasks`, `/appointments`, `/reports`, `/audit-events`

### Pipeline (every endpoint)

Authenticate → resolve user → resolve organization → check permission → validate → business rule → transaction → audit event → safe response

### Error model (RFC 7807-style)

```json
{
  "type": "https://safecase.org/problems/validation-error",
  "title": "The request could not be completed",
  "status": 400,
  "traceId": "01J...",
  "errors": {
    "safeContactMethod": ["A safe contact method is required."]
  }
}
```

Never return stack traces, SQL, storage paths, secrets, or existence confirmation for inaccessible records.

---

## 8. Multi-tenant isolation

**Pilot model:** one app, one primary DB cluster, many orgs, strict logical separation.

Isolation layers:

1. API authorization (membership + permission)  
2. Automatic query filters on `organization_id`  
3. PostgreSQL RLS using `app.current_organization_id`

### Mandatory tenant tests

- Org A cannot view Org B clients  
- ID guessing fails closed without existence leak  
- Admin in A has no authority in B  
- Search/export/audit do not cross tenants  
- Background jobs retain tenant context  
- Document URLs are not reusable across orgs  

---

## 9. Documents, audit, AI, offline

### Documents
Private Blob containers; short-lived upload/download auth; path  
`organizations/{org}/clients/{client}/documents/{doc}`; malware scan; classification; retention; legal hold; download audit.

### Audit
Server events with actor, org, action, resource, result, correlation, hash chain fields.  
Do **not** put client narratives, safety-plan text, phones, or L4 content into ordinary App Insights logs.

### AI
**Deferred** until identity, tenancy, clients, cases, consent, safety, referrals, documents, and audit exist.  
When introduced: authorize → classify → consent/policy → redact → approved gateway → screen → audit → human review. Never auto-send Level 4.

### Offline
**v1: no full offline org DB.** Prefer online reliability + written downtime process. Limited encrypted drafts may come later with short TTL and no L4 by default.

---

## 10. Azure infrastructure layout

### Subscriptions
- SafeCase Development  
- SafeCase Staging  
- SafeCase Production  

### Production resource groups
`rg-safecase-network-prod`, `rg-safecase-app-prod`, `rg-safecase-data-prod`, `rg-safecase-security-prod`, `rg-safecase-monitoring-prod`

### Bicep modules
`app-service`, `postgresql`, `storage`, `key-vault`, `monitoring`, `network`, `identity`  
Parameters: `dev.bicepparam`, `staging.bicepparam`, `prod.bicepparam`

---

## 11. CI/CD

### PR pipeline
Restore → build → unit → integration → authorization → lint/format → dependency + secret + SAST scans → Bicep validate → package

### Promotion
- Main → deploy dev → smoke + migration validation  
- Staging: tests + review + security + e2e + manual approval  
- Production: immutable artifact, approval, backup, reversible migration, smoke, monitor, rollback  

### Auth to Azure
GitHub Actions OIDC only — no long-lived client secrets in GitHub.

---

## 12. Phased delivery

### Phase 0 — Freeze and classify
**Deliverables:** rename prototype repo; warning banner; prohibit real data; inventory Swift/Core Data/workflows; dispositions; ADRs; create api/web/governance repos.  
**Exit:** nobody mistakes prototype for production; every major feature has a disposition; new work has a repo home.

### Phase 1 — Azure foundation
**Deliverables:** dev subscription standards; Bicep baseline; App Service; Postgres; Blob; Key Vault; App Insights; managed identities; GH OIDC; env pattern.  
**Exit:** infra recreate-from-source; no permanent cloud creds in GitHub; health endpoint live; telemetry without sensitive data.

### Phase 2 — Identity and organizations
**Deliverables:** Entra External ID; browser login; API token validation; users; orgs; invitations; memberships; roles; permissions; org selector; disablement; sign-in audit.  
**Exit:** no SafeCase password storage; disabled membership blocks access; multi-org users work; cross-org tests pass.

### Phase 3 — Core data platform
**Deliverables:** schema + RLS; clients; separated identity; cases; assignments; notes; timeline; validation; optimistic concurrency; audit; synthetic seed.  
**Exit:** two orgs simultaneous; no cross access; actor/timestamp everywhere; concurrency conflicts surfaced.

### Phase 4 — First usable web workflow
Vertical slice: sign-in → org → client → case → assign → note → task → timeline → audit.  
**Exit:** org completes workflow without Mac app; Playwright covers slice; a11y baseline; all ops tenant-scoped + audited.

### Phase 5 — Safety and consent
Safety plans, risk, safe-contact, consent lifecycle, restricted permissions, emergency access + alerts.  
**Exit:** revoked consent blocks sharing; L4 restricted; emergency access reason+alert; safe-contact affects notifications.

### Phase 6 — Documents and referrals
Blob upload pipeline, malware scan, classification, retention, referral directory, consent-controlled share, follow-up, export watermarking.  
**Exit:** unauthorized Blob access fails; expired links die; downloads audited; recipients get only approved data.

### Phase 7 — Reports and pilot administration
Deidentified aggregates, program/grant metrics, org config, user admin, audit dashboard, feedback, support workflow.  
**Exit:** reports exclude identifiers unless authorized; pilot admins manage users without Azure portal; support cannot casually read cases.

### Phase 8 — Pilot hardening
Pen test, threat model, PIA, backup restore, DR exercise, IR plan, training, onboarding, DPA, AUP, security signoff.  
**Exit:** written production pilot approval; recovery tested; critical/high vulns resolved; orgs signed; escalation contacts defined.

---

## 13. Conversion milestones (delivery sequence)

| Milestone | Scope |
|---|---|
| **M1 Azure skeleton** | API deploy, Postgres, Key Vault, MI, health, telemetry, Bicep, CI/CD |
| **M2 Secure org access** | Entra, users, orgs, memberships, roles, tenant enforcement, audit |
| **M3 Functional MVP** | clients, cases, notes, assignments, tasks, timeline, dashboard |
| **M4 SafeCase protections** | consent, safety plans, confidential info, safe comms, referrals, documents |
| **M5 Free pilot** | onboarding, reporting, feedback, training, support, ops monitoring |

---

## 14. Web conversion map

| Current SwiftUI | Web feature |
|---|---|
| LoginView | Entra-hosted login |
| MainWindow | Responsive app shell |
| SidebarView | Role-aware navigation |
| DashboardView | Organization dashboard |
| ClientListView | Client search / caseload |
| IntakeSystemView | Guided intake |
| ClientNotesTab | Restricted case notes |
| ClientProgramsTab | Program enrollment |
| ClientTimelineTab | Audited timeline |
| SafetyDashboardView | Safety-plan workspace |
| ReferralListView | Consent-controlled referrals |
| TaskListView | Tasks + escalation |
| CalendarView | Appointments / deadlines |
| ReportListView | Aggregate reporting |
| SafeHouseListView | Restricted capacity mgmt |
| SettingsView | Organization configuration |

**Responsive:** desktop/tablet/laptop first; a11y keyboard, magnification, 200% zoom, reduced motion, high contrast.  
**Mobile v1:** quick lookup, tasks, appointments, safe-contact confirmation, emergency safety — not full parity.

---

## 15. Definition of done for “Azure-compatible”

Use the checklist in the audit §4. Do not declare Azure-compatible because an API merely runs on App Service.

---

## 16. Parallel execution model

Workstreams after Phase 0 can largely run in parallel until they converge on M3:

```text
Wave 0  Prototype freeze + repo bootstrap + governance skeleton
   │
Wave 1  ┌─ Infra Bicep ─┐
        ├─ API skeleton ─┤──→ M1
        ├─ Web skeleton ─┤
        ├─ Domain/schema ┘
        └─ Entra setup docs
   │
Wave 2  Identity/orgs + RLS + audit foundation → M2
   │
Wave 3  Vertical slice web+API features → M3
   │
Wave 4  Safety/consent then docs/referrals → M4
   │
Wave 5  Reporting/admin + hardening → M5 / pilot
```

Copy-paste agent prompts: [03-PARALLEL-AGENT-PROMPTS.md](./03-PARALLEL-AGENT-PROMPTS.md).

---

## 17. First sprint recommendation

Do **not** recreate every Mac screen.

Ship only:

```text
Entra login → organization membership → client creation → case creation
→ advocate assignment → case note → task → timeline → audit record
```

That slice proves the entire Azure architecture. After it is secure, each SafeCase feature expands a working platform instead of spawning another disconnected prototype.
