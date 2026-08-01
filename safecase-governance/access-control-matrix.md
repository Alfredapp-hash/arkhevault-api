# SafeCase Access Control Matrix

> **Status:** DRAFT / PENDING LEGAL REVIEW  
> **Version:** 0.1  
> **Last updated:** 2026-08-01  
> **Scope:** Phase 2 (identity & organizations) through Phase 4 (first usable web workflow)

This matrix defines application roles and granular permissions for SafeCase. **Entra External ID** authenticates users; **SafeCase** stores memberships, roles, and permissions per organization.

**Legend:** ✅ granted · ⚠️ conditional · ❌ denied · 🔒 platform-only

Permissions are enforced server-side in the API and reflected in PostgreSQL RLS context. UI hiding is not authorization.

---

## 1. Roles

| Role | Scope | Description |
|---|---|---|
| **Platform Operator** | Cross-tenant (platform) | SafeCase staff: infra, support tooling, break-glass; no standing case access |
| **Organization Owner** | Single org | Executive/account owner; billing, policy, user admin; limited L4 by default |
| **Organization Administrator** | Single org | Day-to-day user and config admin |
| **Program Director** | Org / programs | Program oversight, caseload assignment, reporting |
| **Supervisor** | Org / team | Supervises advocates; restricted note access; assignment authority |
| **Advocate** | Org / assigned cases | Primary caseworker for assigned clients |
| **Intake Specialist** | Org | Creates clients and intakes; may not see full case history |
| **Referral Partner** | Org / referral scope | External partner; consent-limited referral visibility |
| **Report Analyst** | Org | De-identified aggregates only |
| **Auditor** | Org or platform | Read audit trails; no client narrative unless explicitly granted |
| **Read-Only Reviewer** | Org | Read-only casework view without write or export |

*Survivor Portal User is out of scope for Phase 2–4; add in a future matrix revision.*

---

## 2. Permission catalog (Phase 2–4)

### Organization & membership

| Permission | Description |
|---|---|
| `organization.read` | View org profile and settings |
| `organization.update` | Edit org settings (non-security) |
| `organization.manage_users` | Invite, disable, change roles |
| `organization.manage_programs` | CRUD programs |
| `membership.read` | List org members |
| `membership.invite` | Send invitations |
| `membership.disable` | Disable member access |

### Clients & identity

| Permission | Description |
|---|---|
| `client.read` | View L3 client profile (assigned or org-wide per policy) |
| `client.create` | Create client / intake record |
| `client.update` | Update non-identity client fields |
| `client.update_identity` | Change legal name, DOB, identifiers |
| `client.search` | Search client index |
| `client.merge` | Merge duplicate records (supervised) |

### Cases & assignments

| Permission | Description |
|---|---|
| `case.read` | View case details |
| `case.create` | Open case |
| `case.update` | Edit case metadata |
| `case.assign` | Assign/reassign advocate |
| `case.close` | Close case with outcome |
| `case.reopen` | Reopen closed case |

### Notes & timeline

| Permission | Description |
|---|---|
| `note.create` | Add case note |
| `note.read` | Read standard notes (L3) |
| `note.read_restricted` | Read L4 / restricted notes |
| `note.update_own` | Edit own notes within window |
| `timeline.read` | View audited timeline |
| `timeline.create` | Add timeline events |

### Tasks

| Permission | Description |
|---|---|
| `task.read` | View tasks |
| `task.create` | Create tasks |
| `task.assign` | Assign tasks |
| `task.complete` | Complete tasks |

### Documents (Phase 4 stub — full pipeline Phase 6)

| Permission | Description |
|---|---|
| `document.upload` | Upload documents |
| `document.read` | View metadata |
| `document.download` | Download content (audited) |
| `document.delete` | Soft-delete / archive |

### Consent & safety (Phase 4 read-only stubs — expanded Phase 5)

| Permission | Description |
|---|---|
| `consent.read` | View consent records |
| `consent.manage` | Create/revoke consent |
| `safety.read` | View safety plan (non-L4 fields) |
| `safety.read_confidential` | View L4 safety/location data |

### Audit & reporting

| Permission | Description |
|---|---|
| `audit.review` | Query audit events for org |
| `report.generate` | Run authorized reports |
| `report.export` | Export report files |

### Platform

| Permission | Description |
|---|---|
| `platform.support_session` | Time-limited support impersonation (logged) |
| `platform.tenant_admin` | Cross-tenant ops (no case content) |

---

## 3. Matrix — organization & users (Phase 2)

| Permission | Platform Operator | Org Owner | Org Admin | Program Director | Supervisor | Advocate | Intake Specialist | Referral Partner | Report Analyst | Auditor | Read-Only Reviewer |
|---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| `organization.read` | 🔒 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ⚠️ | ✅ | ✅ | ✅ |
| `organization.update` | 🔒 | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| `organization.manage_users` | 🔒 | ✅ | ✅ | ⚠️ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| `organization.manage_programs` | 🔒 | ✅ | ✅ | ✅ | ⚠️ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| `membership.read` | 🔒 | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ |
| `membership.invite` | 🔒 | ✅ | ✅ | ⚠️ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| `membership.disable` | 🔒 | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |

⚠️ = org-configurable delegation (default off for Intake/Referral roles).

---

## 4. Matrix — clients & cases (Phase 3–4)

| Permission | Platform Operator | Org Owner | Org Admin | Program Director | Supervisor | Advocate | Intake Specialist | Referral Partner | Report Analyst | Auditor | Read-Only Reviewer |
|---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| `client.read` | ❌ | ✅ | ✅ | ✅ | ✅ | ⚠️ | ⚠️ | ❌ | ❌ | ⚠️ | ✅ |
| `client.create` | ❌ | ✅ | ✅ | ✅ | ✅ | ⚠️ | ✅ | ❌ | ❌ | ❌ | ❌ |
| `client.update` | ❌ | ✅ | ✅ | ✅ | ✅ | ⚠️ | ⚠️ | ❌ | ❌ | ❌ | ❌ |
| `client.update_identity` | ❌ | ✅ | ⚠️ | ⚠️ | ⚠️ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| `client.search` | ❌ | ✅ | ✅ | ✅ | ✅ | ⚠️ | ✅ | ❌ | ❌ | ❌ | ✅ |
| `case.read` | ❌ | ✅ | ✅ | ✅ | ✅ | ⚠️ | ⚠️ | ⚠️ | ❌ | ⚠️ | ✅ |
| `case.create` | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| `case.assign` | ❌ | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| `case.update` | ❌ | ✅ | ✅ | ✅ | ✅ | ⚠️ | ❌ | ❌ | ❌ | ❌ | ❌ |
| `case.close` | ❌ | ✅ | ⚠️ | ✅ | ✅ | ⚠️ | ❌ | ❌ | ❌ | ❌ | ❌ |
| `case.reopen` | ❌ | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |

⚠️ **Advocate / Intake:** default to **assigned cases only** unless org enables broader caseload visibility.

⚠️ **Referral Partner:** `case.read` only for referral-linked cases with active consent (Phase 6).

---

## 5. Matrix — notes, tasks, timeline (Phase 3–4)

| Permission | Platform Operator | Org Owner | Org Admin | Program Director | Supervisor | Advocate | Intake Specialist | Referral Partner | Report Analyst | Auditor | Read-Only Reviewer |
|---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| `note.create` | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ | ⚠️ | ❌ | ❌ | ❌ | ❌ |
| `note.read` | ❌ | ✅ | ✅ | ✅ | ✅ | ⚠️ | ⚠️ | ❌ | ❌ | ❌ | ✅ |
| `note.read_restricted` | ❌ | ⚠️ | ⚠️ | ✅ | ✅ | ⚠️ | ❌ | ❌ | ❌ | ❌ | ⚠️ |
| `note.update_own` | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ | ⚠️ | ❌ | ❌ | ❌ | ❌ |
| `timeline.read` | ❌ | ✅ | ✅ | ✅ | ✅ | ⚠️ | ⚠️ | ⚠️ | ❌ | ✅ | ✅ |
| `timeline.create` | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| `task.read` | ❌ | ✅ | ✅ | ✅ | ✅ | ⚠️ | ⚠️ | ❌ | ❌ | ❌ | ✅ |
| `task.create` | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| `task.assign` | ❌ | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| `task.complete` | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ | ⚠️ | ❌ | ❌ | ❌ | ❌ |

**L4 default:** Org Owner and Org Admin receive ⚠️ on `note.read_restricted` — default **deny**; grant explicitly for designated safety leads only.

---

## 6. Matrix — documents, consent, audit (Phase 4 stubs)

| Permission | Platform Operator | Org Owner | Org Admin | Program Director | Supervisor | Advocate | Intake Specialist | Referral Partner | Report Analyst | Auditor | Read-Only Reviewer |
|---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| `document.upload` | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| `document.read` | ❌ | ✅ | ✅ | ✅ | ✅ | ⚠️ | ⚠️ | ❌ | ❌ | ❌ | ✅ |
| `document.download` | ❌ | ✅ | ✅ | ✅ | ✅ | ⚠️ | ❌ | ❌ | ❌ | ❌ | ❌ |
| `consent.read` | ❌ | ✅ | ✅ | ✅ | ✅ | ⚠️ | ⚠️ | ⚠️ | ❌ | ✅ | ✅ |
| `consent.manage` | ❌ | ✅ | ✅ | ✅ | ✅ | ⚠️ | ❌ | ❌ | ❌ | ❌ | ❌ |
| `safety.read` | ❌ | ✅ | ✅ | ✅ | ✅ | ⚠️ | ❌ | ❌ | ❌ | ❌ | ⚠️ |
| `safety.read_confidential` | ❌ | ⚠️ | ⚠️ | ✅ | ✅ | ⚠️ | ❌ | ❌ | ❌ | ❌ | ❌ |
| `audit.review` | 🔒 | ✅ | ✅ | ⚠️ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ |
| `report.generate` | ❌ | ✅ | ✅ | ✅ | ⚠️ | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ |
| `report.export` | ❌ | ✅ | ⚠️ | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ |

---

## 7. Platform operator boundaries

Platform Operators **must not** have standing permissions to read client narratives, notes, or documents.

| Capability | Allowed | Mechanism |
|---|---|---|
| Deploy API / run migrations | ✅ | Azure RBAC, GH Actions OIDC |
| View tenant metadata (org name, IDs) | ✅ | Support console (TBD) |
| Impersonate user for debugging | ⚠️ | `platform.support_session` — time-boxed, audited, org-approved |
| Read case notes | ❌ | Emergency only via documented break-glass with legal review |
| Disable compromised account | ✅ | Entra + SafeCase membership disable |

---

## 8. Enforcement requirements

1. Every API route declares required permission(s).  
2. Organization context resolved from membership, not client-supplied headers alone.  
3. PostgreSQL session sets `app.current_organization_id` for RLS.  
4. Authorization integration tests cover cross-tenant denial and ID guessing.  
5. Permission changes audit to `membership.role_changed` events.  
6. Disabled membership → 403 on all org routes immediately (token may remain valid until expiry; API checks membership each request).

---

## 9. Phase 5+ additions (planned)

Not in Phase 2–4 enforcement but reserved in naming:

- `emergency.access` — break-glass L4 with reason code  
- `referral.share` — consent-controlled outbound share  
- `document.share` — external secure link  
- `export.client_record` — supervised full export  

Update this matrix when Phase 5–7 features ship.

---

## 10. Related documents

- [data-classification.md](./data-classification.md)  
- [identity/entra-external-id-runbook.md](./identity/entra-external-id-runbook.md)  
- [security-acceptance-criteria.md](./security-acceptance-criteria.md) — authorization test requirements  
