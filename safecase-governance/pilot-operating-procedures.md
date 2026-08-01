# SafeCase Pilot Operating Procedures

> **Status:** DRAFT / PENDING LEGAL REVIEW  
> **Version:** 0.1  
> **Last updated:** 2026-08-01  
> **Applies to:** All pilot participants, SafeCase staff, and contractors

---

## 1. Purpose

These procedures govern how pilot organizations and SafeCase staff use the platform **before and during** the controlled production pilot. They prioritize survivor safety and legal compliance over feature velocity.

**Cardinal rule:** No real survivor, victim, or client identifying information in SafeCase until **Phase 8 production pilot signoff** (see [security-acceptance-criteria.md](./security-acceptance-criteria.md) §14).

---

## 2. Phase gate summary

| Phase | Data allowed | Primary surface |
|---|---|---|
| 0–7 | **Synthetic only** | Dev, staging, early prod infrastructure |
| 8 (post-signoff) | Real client data per DPA | Production pilot tenant |

Entering Phase 8 requires completed security acceptance criteria, executed DPA, trained org admins, and documented escalation contacts.

---

## 3. Synthetic data rules

### 3.1 Required practices

1. Use obviously fictional names (e.g., "Alex Sample", "Jordan Testcase") — not names of staff, volunteers, or public figures.  
2. Use fake contact information: `(555) 010-xxxx`, `@example.invalid` email domains.  
3. Do not use real addresses; use "123 Example St, Testville, TS 00000" or equivalent.  
4. L4 synthetic locations must be clearly fake ("Safe House Training Location Alpha").  
5. Do not copy/redact real intakes — create fresh fictional scenarios.  
6. Do not import macOS prototype SQLite or exports into Azure environments.  
7. Do not photograph or upload real documents — use generated PDFs marked "SYNTHETIC".  

### 3.2 Prohibited actions

- Loading historical case files "for testing"  
- Having staff role-play with their own personal information  
- Connecting production Entra identities to synthetic tenants that later receive real data without access review  
- Using AI tools to generate realistic survivor narratives from real news stories  
- Storing pilot credentials or tokens in shared documents  

### 3.3 macOS prototype

The SwiftUI prototype remains **synthetic only** and must not sync to pilot API with production tokens. It is a UX reference, not a pilot client.

---

## 4. Environment usage

| Environment | Who | Purpose |
|---|---|---|
| **Development** | SafeCase engineering | Feature work; disposable data |
| **Staging** | Engineering + selected org champions | Pre-release validation; synthetic only |
| **Production (pre–Phase 8)** | Limited smoke testers | Infra validation; synthetic only |
| **Production (post–Phase 8)** | Approved pilot org users | Live casework per DPA |

Org champions must acknowledge synthetic-data rules in writing before staging access.

---

## 5. User provisioning (pilot)

1. Org Owner completes [organization-onboarding.md](./organization-onboarding.md) checklist.  
2. SafeCase creates organization tenant record and Entra invitation flow.  
3. Minimum MFA: per Entra policy (see identity runbook).  
4. Roles assigned per [access-control-matrix.md](./access-control-matrix.md) — principle of least privilege.  
5. Referral partners and auditors receive narrow roles only.  
6. Offboarding: disable membership within 24 hours of departure notification; review audit trail.

---

## 6. Support procedures

### 6.1 Support tiers

| Tier | Handles |
|---|---|
| **L1 — Org admin** | Password/MFA issues (Entra), user invites, basic how-to |
| **L2 — SafeCase pilot support** | Bugs, configuration, non-content troubleshooting |
| **L3 — Engineering** | Security incidents, data integrity, platform defects |

### 6.2 Support access to client data

- Support **does not** routinely access case content.  
- If technical diagnosis requires content access, use time-limited `platform.support_session` with org approval and audit (Phase 7+ tooling).  
- Never ask users to email screenshots containing client PII via unapproved channels.

### 6.3 Approved support channels

Define before pilot (examples):

- In-app feedback widget (no client content in free text)  
- `pilot@safecase.org`  
- Scheduled screen-share with synthetic data preferred  

---

## 7. Escalation paths

### 7.1 Security concern (suspected breach, unauthorized access)

1. **Immediate:** Org admin disables affected accounts (Entra + SafeCase membership).  
2. **Within 1 hour:** Notify SafeCase security contact (see [incident-response.md](./incident-response.md)).  
3. **Do not** destroy evidence (logs, audit exports) unless IR lead directs.  
4. SafeCase initiates incident severity classification and notification timeline.

### 7.2 Safety emergency (client in immediate danger)

SafeCase is **not** an emergency dispatch system.

1. Staff follow their organization's **local emergency protocol** (911, hotline, supervisor).  
2. Document in SafeCase only after immediate safety steps are underway.  
3. Platform outages during emergency: use org offline contingency plan (phone tree, paper backup).

### 7.3 Data classification mistake (real data entered pre–Phase 8)

1. Stop entry immediately.  
2. Notify SafeCase security + org executive sponsor.  
3. Do not attempt self-service mass delete without guidance (audit preservation).  
4. SafeCase assesses scope, containment, and whether breach notification triggers apply.

### 7.4 Export or sharing mistake

1. Revoke consent/share if applicable.  
2. Notify recipient to delete copies (per org policy).  
3. Log incident in audit; open IR ticket if external unauthorized disclosure.

---

## 8. Change and release communication

- SafeCase publishes pilot release notes (features, known issues, security fixes).  
- Breaking API changes communicated ≥5 business days ahead when possible.  
- Maintenance windows posted; orgs confirm safety-critical periods (e.g., shelter census nights).

---

## 9. Training requirements

Before Phase 8 real data:

| Audience | Training |
|---|---|
| All users | MFA, role basics, synthetic vs real data policy (pre-8), password hygiene |
| Advocates / supervisors | L3/L4 handling, note restrictions, export rules |
| Org admins | User management, audit review, escalation |
| Report analysts | De-identification rules; L4 analytics ban |

Training completion logged (LMS or signed attestation — TBD).

---

## 10. Pilot feedback and exit

- Structured feedback monthly during pilot.  
- Exit criteria: mutual review, data export per DPA, membership disable, retention per [retention-policy.md](./retention-policy.md).  
- Pilot may be paused for critical security findings without notice.

---

## 11. Document control

| Version | Date | Change |
|---|---|---|
| 0.1 | 2026-08-01 | Initial draft |

Counsel review required before distributing to external pilot orgs as binding policy.

---

## 12. Related documents

- [security-acceptance-criteria.md](./security-acceptance-criteria.md)  
- [organization-onboarding.md](./organization-onboarding.md)  
- [incident-response.md](./incident-response.md)  
- [data-classification.md](./data-classification.md)  
