# SafeCase Security Acceptance Criteria

> **Status:** DRAFT / PENDING LEGAL REVIEW  
> **Version:** 0.1  
> **Last updated:** 2026-08-01  
> **Purpose:** Define "pilot-ready" and "Azure-compatible" for SafeCase before Phase 8 production pilot approval

An environment is **not** pilot-ready because the API deploys successfully. All applicable sections below must pass for the target phase gate.

---

## 1. How to use this checklist

| Gate | Minimum sections |
|---|---|
| **M1 — Azure skeleton** (Phase 1) | §2 Infrastructure, §3 Observability |
| **M2 — Secure org access** (Phase 2) | + §4 Identity, §5 Authorization, §6 Audit (baseline) |
| **M3 — Functional MVP** (Phase 3) | + §7 Data platform, §8 Multi-tenant isolation |
| **M4 — SafeCase protections** (Phase 5–6) | + §9 Safety/consent, §10 Documents |
| **M5 / Phase 8 — Production pilot** | All sections + §14 Signoff |

Mark each item: **Pass** · **Fail** · **N/A** · **Deferred (with ticket)**

---

## 2. Infrastructure (Azure)

- [ ] Resources deployed from Bicep (or equivalent IaC) — no critical portal-only drift  
- [ ] Separate subscriptions or clearly isolated resource groups for dev / staging / prod  
- [ ] Managed identities used for API → Postgres, Blob, Key Vault (no long-lived secrets in app settings)  
- [ ] Key Vault holds connection strings and signing keys; access via RBAC + MI  
- [ ] PostgreSQL: SSL required, firewall / private networking documented for prod  
- [ ] Blob: private containers; no public anonymous access  
- [ ] GitHub Actions → Azure via OIDC (no stored Azure client secrets)  
- [ ] Environment naming and tagging (`env`, `app=safecase`, `data-classification`) applied  
- [ ] Destroy/recreate documented for non-prod  

---

## 3. Observability (safe telemetry)

- [ ] Application Insights connected with sampling appropriate to cost  
- [ ] **No** client names, note bodies, phone numbers, addresses, L4 fields, or document content in logs  
- [ ] Correlation IDs (`traceId`) on API errors (RFC 7807-style)  
- [ ] Alerts configured for API availability, error rate spikes, auth failures  
- [ ] Log retention aligned with [retention-policy.md](./retention-policy.md)  

---

## 4. Identity (Entra External ID)

- [ ] External tenant configured; **not** legacy Azure AD B2C for new customers  
- [ ] SPA and API app registrations with correct redirect URIs and scopes  
- [ ] API validates issuer, audience, signing keys, token lifetime  
- [ ] **No** SafeCase-native password storage or password reset flows  
- [ ] MFA policy documented and enabled per [entra-external-id-runbook.md](./identity/entra-external-id-runbook.md)  
- [ ] User disablement in Entra + membership disable in SafeCase both tested  
- [ ] Sign-in events recorded in audit log (success and failure)  
- [ ] Local dev uses Entra dev tenant or documented stub — not production credentials  

---

## 5. Authorization

- [ ] Every mutating endpoint checks permission + organization membership  
- [ ] Roles and permissions match [access-control-matrix.md](./access-control-matrix.md) for shipped features  
- [ ] Authorization integration test suite runs in CI  
- [ ] UI route guards mirror API permissions (defense in depth only)  
- [ ] Platform Operator has no standing case read access  
- [ ] Disabled user receives 403 within one request of membership disable  

---

## 6. Audit (server-authoritative)

- [ ] Audit events for authentication, membership changes, client/case CRUD, note access (metadata), exports  
- [ ] Events include: actor, organization, action, resource type/id, timestamp, result, correlation id  
- [ ] Audit store append-only from application perspective (no user delete)  
- [ ] Hash chain or integrity mechanism documented (implementation TBD)  
- [ ] `audit.review` permission required to query org audit trail  

---

## 7. Data platform

- [ ] PostgreSQL schema with `organization_id` on tenant-scoped tables  
- [ ] EF Core (or data layer) applies automatic organization filters  
- [ ] RLS policies enabled and tested with `app.current_organization_id`  
- [ ] Optimistic concurrency on editable aggregates (clients, cases, notes)  
- [ ] Field classification documented per [data-classification.md](./data-classification.md)  
- [ ] Synthetic seed data only until Phase 8 approval  

---

## 8. Multi-tenant isolation (mandatory tests)

All must **pass** in CI or documented manual test run:

- [ ] Org A user cannot read Org B client by ID  
- [ ] Org A user cannot list/search Org B clients  
- [ ] Invalid/guessed UUID returns 404 or 403 **without** confirming existence cross-tenant  
- [ ] Org A admin cannot manage Org B memberships  
- [ ] Background job preserves tenant context  
- [ ] Document download URL from Org A invalid for Org B  
- [ ] Audit queries scoped to org  

---

## 9. Safety & consent (Phase 5+ gate)

- [ ] Consent record required before referral share  
- [ ] Revoked consent blocks sharing immediately  
- [ ] L4 fields require elevated permissions  
- [ ] Emergency access generates alert + audit reason  
- [ ] Safe-contact preferences affect notification routing  

---

## 10. Documents (Phase 6+ gate)

- [ ] Upload → scan → classify → store in tenant path  
- [ ] Download requires authorization per request; short-lived URLs  
- [ ] Download audited  
- [ ] Malware scan failure quarantines object  
- [ ] Export watermarking where applicable  

---

## 11. Application security

- [ ] HTTPS only; HSTS on production web  
- [ ] CORS restricted to known web origins  
- [ ] Rate limiting on auth and sensitive endpoints  
- [ ] Input validation (FluentValidation + schema) on all writes  
- [ ] Dependency and secret scanning in CI  
- [ ] SAST baseline clean or documented exceptions  
- [ ] No stack traces or SQL in client error responses  

---

## 12. Operational readiness (Phase 8)

- [ ] Backup and restore tested for PostgreSQL (RPO/RTO documented)  
- [ ] DR exercise completed  
- [ ] [incident-response.md](./incident-response.md) roles and contacts assigned  
- [ ] [threat-model.md](./threat-model.md) reviewed within 90 days  
- [ ] Penetration test completed; critical/high findings remediated or accepted with signoff  
- [ ] [privacy-impact-assessment.md](./privacy-impact-assessment.md) counsel review scheduled/completed  
- [ ] DPA and AUP templates ready for pilot orgs  
- [ ] Support staff trained on synthetic-data and escalation procedures  

---

## 13. Explicit non-criteria (do not use as proof of security)

The following are **insufficient** alone:

- macOS prototype "security" features (local PIN, SHA-256 passwords, biometrics)  
- Prior `SECURITY_AUDIT_REPORT.md` claims in the prototype repo  
- Deploying to App Service without authorization tests  
- Encrypting disks without tenant isolation  
- Feature parity with SwiftUI screens  

---

## 14. Phase 8 production pilot signoff

Required approvers (define names before pilot):

| Approver | Responsibility | Signoff date |
|---|---|---|
| SafeCase Platform Operator lead | Technical criteria §2–11 | |
| Security / privacy lead | Threat model, PIA, IR | |
| Legal counsel | DPA, breach notification, retention | |
| Pilot organization executive sponsor | Operational readiness | |

**Signoff statement (template):**

> Organization `[name]` may enter production pilot with real client data as of `[date]`, subject to [pilot-operating-procedures.md](./pilot-operating-procedures.md) and executed DPA `[ref]`.

Until this signoff exists, all environments remain **synthetic data only**.

---

## 15. Related documents

- [pilot-operating-procedures.md](./pilot-operating-procedures.md)  
- [organization-onboarding.md](./organization-onboarding.md)  
- `safecase-macos-prototype/docs/azure-conversion/01-FRESH-AUDIT.md` §4  
