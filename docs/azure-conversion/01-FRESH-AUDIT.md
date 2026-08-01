# SafeCase Fresh Audit — Current State vs Azure Target

**Audit date:** 2026-08-01  
**Scope:** `/workspace` (GitHub: `Alfredapp-hash/arkhevault-api`)  
**Method:** Source inspection of Swift services, Core Data model, feature modules, tests, and prior planning docs  
**Conclusion:** Not Azure-compatible. Suitable only as a workflow/design prototype with synthetic data.

---

## 1. Executive verdict

| Question | Answer |
|---|---|
| Can Azure host this SwiftUI/Core Data app as multi-org SaaS? | **No** |
| Is the app a useful prototype for conversion? | **Yes** — workflows and domain concepts are valuable |
| Is there an Azure API, Entra auth, Postgres, Blob, or Bicep today? | **No** |
| Are prior “cleared for live testing” claims valid for SaaS? | **No** |
| Correct next move | Freeze prototype → extract domain → build Azure API + web |

The existing architecture places authentication, authorization, business rules, storage, encryption claims, audit, and optional AI calls on one local device. That is unsuitable for victim-services SaaS because organizations need centralized access control, synchronized records, revocable access, durable storage, and an authoritative audit trail.

---

## 2. What exists today

### 2.1 Product shape

```text
SwiftUI macOS application
├── Interface (sidebar + feature views)
├── Local authentication (Staff + Keychain hashes + biometrics)
├── Business rules (mostly in views)
├── Core Data SQLite (authoritative on-device)
├── Local document file paths
├── Local security event log file
└── Optional direct Anthropic API calls
```

### 2.2 Code inventory

| Area | Location | Reality |
|---|---|---|
| App shell | `App/` | Login, main window, sidebar navigation |
| Data | `Core/Data/` | `NSPersistentContainer("ForgedInFireDataModel")` |
| Services | `Core/Services/` | Auth, session, network, rate limit, AI, config, local audit |
| Features | `Features/*` | 16 UI modules, mostly Core Data CRUD or placeholders |
| Shared UI | `Shared/` | Branding/components |
| Tests | `Tests/` | Security/component unit + UI smoke tests; schema drift |
| Docs | root `*.md` | Mix of overstated completion and AWS SaaS planning |

### 2.3 Core Data entities (actual schema)

From `Core/Data/ForgedInFireDataModel.xcdatamodeld/contents` — **14 entities**:

`Client`, `SafetyFlag`, `Program`, `ProgramEnrollment`, `CaseNote`, `Task`, `Appointment`, `SafeHouse`, `SafeHousePlacement`, `Staff`, `Referral`, `Document`, `Communication`, `ProgramOutcome`

**Not present:** `Organization`, `Membership`, `Role`, `Permission`, `Case` (as first-class entity), `ConsentRecord`, `AuditEvent`, `PendingChange`, `DocumentExtraction`, analytics/crash entities referenced by some views.

### 2.4 Prior docs that mislead conversion

| Document | Claim | Audit finding |
|---|---|---|
| `SECURITY_AUDIT_REPORT.md` | “CLEARED FOR LIVE TESTING” | Local SHA-256 auth, first-login any password, placeholder cert pins remain |
| `PROGRESS_AUDIT.md` | “85% complete”, phases done | UI prototype progress ≠ SaaS readiness |
| `IMPLEMENTATION_SUMMARY.md` | Near production-ready | Many placeholders; no central API |
| `UPGRADE_PASS_2_SAAS_INFRASTRUCTURE.md` | AWS/Node/JWT plan | Useful intent; wrong cloud/stack for SafeCase Azure path |
| `MASTER_UPGRADE_ROADMAP.md` / `EXECUTION_CHECKLIST_ORDERED.md` | AWS RDS checklist | Superseded by this package |

---

## 3. Security findings (fresh)

### Critical

1. **Local password auth is the production path**  
   `AuthenticationManager.login` authenticates against local `Staff` Core Data + Keychain hash. No Entra / OIDC.

2. **First-login password acceptance**  
   If no stored hash exists, `verifyPassword` returns `!password.isEmpty` — any non-empty password establishes credentials.

3. **Weak password hashing**  
   SHA-256 over `salt + password` with install-level salt (`APP_SALT_SUFFIX`). Not a password KDF (no Argon2id/bcrypt/PBKDF2).

4. **Biometric path can authorize on device owner alone**  
   Biometric “validation” effectively checks non-empty saved email; not server identity.

5. **No tenant boundary**  
   No `organization_id` in schema. Fetches are global on-device (`Client.fetchAll`, unscoped `SafetyFlag` fetches).

6. **Client-side AI provider key + sensitive prompts**  
   `AIService` sends `x-api-key` to Anthropic and includes client name, risk, biography, safety concerns in prompts.

7. **Encryption claims without cryptography**  
   UI text claims encrypted documents / confidential locations; storage is Core Data strings/paths (`document.filePath`, `safeHouse.confidentialLocation`).

### High

8. **Audit is local-only** — `SecurityEventLogger` writes Application Support / OSLog; exportable plaintext temp files.  
9. **Certificate pinning placeholders** — `PLACEHOLDER_HASH_*` in `NetworkSecurityManager`.  
10. **Offline sync incomplete/unsafe** — references missing `PendingChange`; sync POST sends token header but not change body.  
11. **Role flags without enforcement** — `Staff.role` / `permissions` exist; views do not enforce server-grade RBAC.  
12. **Documents are local paths** — no Blob, malware scan, short-lived SAS, retention, or download audit.

### Medium / structural

13. Schema drift between views/tests and model.  
14. CloudKit import present but sync commented out.  
15. Rate limiting is client-side and optional.  
16. No Key Vault, managed identity, private endpoints, Bicep, or GitHub OIDC deploy pipeline.

---

## 4. Gap analysis vs “Azure-compatible” definition

Conversion is complete only when all of the following are true. Current status:

| Requirement | Status |
|---|---|
| Authentication through Microsoft Entra External ID | ❌ Missing |
| Application passwords eliminated | ❌ Local hashes remain |
| Data centrally stored | ❌ Local Core Data |
| Tenant isolation enforced at API | ❌ No tenants |
| PostgreSQL row-level security | ❌ None |
| Documents in protected Blob Storage | ❌ Local paths |
| Secrets in Key Vault + managed identities | ❌ Env/Keychain |
| Infrastructure reproducible via Bicep | ❌ None |
| Automated deployments (OIDC, no long-lived secrets) | ❌ None |
| Logs exclude protected case content | ⚠️ Partial intent only |
| Server-authoritative audit events | ❌ Local only |
| Backups configured and restore-tested | ❌ N/A (local) |
| Core workflow via web app | ❌ Mac UI only |
| Mac app no longer source of truth | ❌ Still is |

**Blockers to calling this Azure-compatible: all of the above.**

---

## 5. Multi-tenant readiness

| Layer | Required | Current |
|---|---|---|
| Identity memberships | User ↔ many orgs | Single local Staff |
| API authorization | Org + permission checks | None |
| Query filters | Auto tenant scope | Global fetches |
| DB RLS | `organization_id` policies | No Postgres |
| Document URLs | Org-scoped, short-lived | Local filesystem |
| Background jobs | Tenant context preserved | N/A / broken offline queue |
| Error model | No existence leaks | Local UI errors only |

Critical tenant tests do not exist and cannot pass until an API + Postgres RLS stack exists.

---

## 6. Data classification readiness

The prototype stores Level 3–4 concepts locally without classification enforcement:

| Level | Examples in current model | Controls today |
|---|---|---|
| L3 Protected client info | names, phones, addresses, notes, documents metadata | Local disk |
| L4 Highly restricted | `SafeHouse.confidentialLocation`, safety concerns, placements, escape/exit plans | Plain Core Data fields; UI labels only |

No field-level redaction, restricted download policy, separate L4 permissions, or “never send to AI/analytics” enforcement.

---

## 7. Feature disposition summary

Full matrix: [05-FEATURE-DISPOSITION.md](./05-FEATURE-DISPOSITION.md)

| Category | Count / examples |
|---|---|
| **A — Preserve conceptually** | Dashboard, clients, intake, safety, programs, referrals, calendar, tasks, reports, volunteers, safe-house UX, notifications concepts |
| **B — Rewrite completely** | Local auth, SHA-256 passwords, biometric-as-authz, Core Data as source of truth, client API keys, local audit as compliance, offline sync as designed |
| **C — Design reference only** | NetworkSecurityManager intentions, session idle UX, rate limiter concept, Core Data migration guide, prior security report |
| **D — Move server-side** | Roles, validation, risk/status calc, consent, document permissions, referral sharing, reporting, retention, notifications generation |

---

## 8. Domain extraction readiness

The Core Data schema is a **useful starting inventory**, not a production schema.

Strengths:

- Rich client profile fields aligned with victim-services work
- Relationships across notes, tasks, appointments, referrals, documents, placements
- Staff assignment patterns

Gaps vs target domain (plan §5):

- No Organization / Membership / Invitation / AccessPolicy
- No first-class Case aggregate (casework is distributed across Client + notes/tasks)
- No Consent / InformationSharingAuthorization entities
- No AuditEvent / AccessEvent / ExportEvent
- Document storage is path metadata, not Blob object model
- Identity fields mixed into Client (need separated ClientIdentity)

Recommendation: **Scenario A** — do not migrate prototype SQLite; convert schema to a reference document; create clean PostgreSQL migrations; seed synthetic data.

---

## 9. Stack decision confirmation

Prior SaaS docs recommend Node/Express/JWT/AWS. For SafeCase Azure conversion, this audit **confirms the user’s recommended stack**:

| Layer | Choice | Why |
|---|---|---|
| Identity | Microsoft Entra External ID | CIAM for external/business customers; B2C no longer sold to new customers |
| API | ASP.NET Core 10 + EF Core | Azure identity, policy authz, background services, enterprise ops |
| DB | Azure Database for PostgreSQL Flexible Server + RLS | Managed backups, private networking, tenant isolation |
| Docs | Azure Blob Storage | Private containers, SAS, malware scan pipeline |
| Secrets | Key Vault + managed identities | No client-held provider keys |
| Web | Next.js + TypeScript + Tailwind + shadcn/ui | Pilot browser app |
| IaC | Bicep | Reproducible Azure layout |
| CI/CD | GitHub Actions OIDC | No long-lived Azure client secrets |

---

## 10. Risks if teams keep building in this repo

1. **False confidence** from prior “cleared” security docs  
2. **Real data contamination** if pilot orgs load survivor information into Core Data  
3. **Security theater** (placeholder pins, encryption labels) mistaken for controls  
4. **AWS/Node drift** against the Azure enterprise path  
5. **Offline/AI features** expanding the attack surface before identity/tenancy exist  
6. **Mac-first feature parity** delaying the web vertical slice that proves the platform

---

## 11. Immediate freeze actions (Phase 0)

1. Treat this repo as `safecase-macos-prototype` (rename on GitHub when ready)  
2. Keep the README prototype banner visible  
3. Prohibit real PII/PHI/safety data  
4. Stop new production auth/storage work in Swift  
5. Open `safecase-api`, `safecase-web`, `safecase-governance`  
6. Use [03-PARALLEL-AGENT-PROMPTS.md](./03-PARALLEL-AGENT-PROMPTS.md) to execute Wave 0/1 in parallel  

---

## 12. Audit sign-off statement

**This codebase is a workflow prototype, not a production SafeCase system.**  
Azure conversion must rebuild identity, authorization, data, documents, and audit as server-authoritative services. The Mac application may later become an optional approved client; it must not remain the source of truth.
