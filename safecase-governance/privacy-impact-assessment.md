# SafeCase Privacy Impact Assessment (PIA Outline)

> **Status:** DRAFT / PENDING LEGAL REVIEW  
> **Version:** 0.1  
> **Last updated:** 2026-08-01  
> **Product:** SafeCase — victim-services multi-tenant SaaS (Azure)

This document is a **Privacy Impact Assessment outline** for counsel and privacy reviewers. It is not a completed PIA. Each section requires factual completion, jurisdictional analysis, and signoff before pilot production use with real client data.

---

## 1. Executive summary

| Item | Draft content |
|---|---|
| **Project** | SafeCase cloud platform for case management, intake, safety planning, referrals, and reporting for victim-services organizations |
| **Data subjects** | Survivors/clients, organization staff, referral partners, volunteers (future) |
| **Sensitive data** | Yes — includes L3 PII and L4 highly restricted safety/location data ([data-classification.md](./data-classification.md)) |
| **Hosting** | Microsoft Azure (region TBD per contract); Entra External ID |
| **Pilot approach** | Synthetic data Phases 0–7; real data only after Phase 8 signoff |

**Preliminary conclusion (draft):** Processing presents **elevated privacy risk** requiring strong access controls, audit, breach procedures, and counsel-reviewed notices before production pilot.

---

## 2. Scope and purpose

### 2.1 Purpose of processing

- Enable authorized staff to manage client cases, services, and safety planning  
- Support referrals with consent controls  
- Generate de-identified program and grant reports  
- Maintain immutable audit trail for accountability  

### 2.2 In scope

- SafeCase web application (`safecase-web`)  
- SafeCase API and workers (`safecase-api`)  
- Azure PostgreSQL, Blob, Key Vault, monitoring  
- Entra External ID authentication  
- Pilot organization staff and configured partners  

### 2.3 Out of scope (v0)

- macOS prototype (local synthetic reference only)  
- Survivor self-service portal  
- AI/LLM features (deferred)  
- Offline full-database sync  

---

## 3. Roles under privacy law (to be confirmed by counsel)

| Role | Entity (draft) |
|---|---|
| **Data controller** | Each pilot **organization** for client/survivor data |
| **Data processor** | SafeCase (platform operator) on behalf of orgs |
| **Subprocessors** | Microsoft (Azure, Entra), [others listed in DPA schedule] |

Organizations may be joint controllers for certain flows (e.g., referrals) — **legal determination required**.

---

## 4. Data inventory

### 4.1 Categories of personal data

| Category | Examples | Classification | Special category? |
|---|---|---|---|
| Identity | Name, aliases, DOB, government ID (if collected) | L3 | Possibly |
| Contact | Phone, email, address | L3 | No |
| Case narrative | Notes, timeline | L3–L4 | Possibly |
| Safety | Safety plans, risk assessments | L3–L4 | Possibly — **legal review** |
| Location | Shelter/safe house, hiding place | L4 | Possibly |
| Staff | Name, work email, role | L2 | No |
| Technical | IP, user agent, audit metadata | L1–L2 | No |
| Consent | Sharing preferences, signatures | L3 | No |

### 4.2 Data subjects

- Adults and minors (minor handling — **counsel review**)  
- Vulnerable individuals including domestic violence survivors  

### 4.3 Sources

- Direct from client/survivor (via staff entry)  
- Referral partners (with consent)  
- Organization historical migration (post-pilot, controlled import only)  

---

## 5. Lawful basis and consent (outline — jurisdiction-specific)

**Counsel must complete for each jurisdiction.**

| Processing activity | Potential basis (examples) | Notes |
|---|---|---|
| Casework record keeping | Legitimate interest / legal obligation / contract | Org-dependent |
| Safety planning | Vital interests / explicit consent | High sensitivity |
| Referral sharing | Explicit consent | Consent module Phase 5+ |
| Audit logging | Legitimate interest / legal obligation | Processor + controller duties |
| De-identified reporting | Legitimate interest | Must exclude L4; suppress small-N |

### Consent management (technical)

- Consent records stored server-side  
- Revocation immediately enforced in API  
- Versioning of consent text (TBD)  

---

## 6. Necessity and proportionality

| Principle | SafeCase approach |
|---|---|
| Data minimization | Role-based access; assigned caseload defaults; no gratuitous fields |
| Purpose limitation | No marketing use of client data; no sale of data |
| Storage limitation | [retention-policy.md](./retention-policy.md) |
| Accuracy | Org responsible for correction; audit trail on identity changes |
| Integrity & confidentiality | Encryption, RLS, classification |

**Open question:** Which optional fields should be disabled by default for pilot orgs?

---

## 7. Risk assessment (summary)

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Unauthorized cross-tenant access | Medium | Critical | Authz + RLS + testing |
| Insider abuse | Medium | Critical | Least privilege, audit, export controls |
| L4 disclosure (safety harm) | Low–Medium | Critical | L4 permissions, no analytics/AI default ban |
| Breach via stolen credentials | Medium | High | MFA, session timeout |
| Subprocessor breach (Azure) | Low | High | DPA with Microsoft, encryption |
| Re-identification in reports | Medium | Medium | Suppression rules, analyst training |
| Pre–Phase 8 real data entry | Medium | High | Pilot procedures, monitoring |

Detailed threats: [threat-model.md](./threat-model.md).

---

## 8. Technical and organizational measures

| Measure | Reference |
|---|---|
| Authentication (Entra External ID, MFA) | [identity/entra-external-id-runbook.md](./identity/entra-external-id-runbook.md) |
| Authorization matrix | [access-control-matrix.md](./access-control-matrix.md) |
| Classification | [data-classification.md](./data-classification.md) |
| Encryption in transit | TLS 1.2+ |
| Encryption at rest | Azure platform defaults; CMK TBD |
| Tenant isolation | PostgreSQL RLS |
| Audit | Server-authoritative audit events |
| Incident response | [incident-response.md](./incident-response.md) |
| Retention & deletion | [retention-policy.md](./retention-policy.md) |
| Staff training | [organization-onboarding.md](./organization-onboarding.md) |

---

## 9. Data subject rights (outline)

Organizations (as controllers) typically must support:

| Right | SafeCase support (planned) |
|---|---|
| Access | Export per org admin process (Phase 7+) |
| Rectification | Client update permissions |
| Erasure | Retention/hold conflicts — org + legal decision |
| Restrict processing | Case hold flags (TBD) |
| Portability | Structured export (TBD format) |
| Object | Org-managed |

SafeCase provides **tools**; orgs remain responsible for responding to requests unless DPA states otherwise.

---

## 10. International transfers

| Item | Status |
|---|---|
| Primary Azure region | TBD in contract |
| US / Canada / EU orgs | Data residency requirements — **counsel** |
| Microsoft DPA / SCCs | Standard Azure contractual package |

---

## 11. Subprocessors

| Subprocessor | Service | Due diligence |
|---|---|---|
| Microsoft Corporation | Azure, Entra | Azure DPA, SOC reports |
| [Email provider TBD] | Transactional email | ☐ |
| [Support tooling TBD] | Tickets | No client content policy |

Maintain public subprocessor list with change notification per DPA.

---

## 12. Privacy by design checkpoints

| Phase | Checkpoint |
|---|---|
| 2 | No SafeCase passwords; membership model |
| 3 | RLS + classification tags in schema |
| 5 | Consent enforcement |
| 6 | Document classification at upload |
| 7 | De-identified reporting review |
| 8 | PIA signoff, DPIA if required (EU) |

---

## 13. Documentation and notices

| Document | Audience | Status |
|---|---|---|
| Organization DPA | Pilot org + SafeCase | Draft needed |
| Privacy policy (SafeCase corporate) | Public | Draft needed |
| Org-facing privacy notice template | End clients (via org) | Org responsibility — template TBD |
| Cookie / analytics notice | Web users | Minimal cookies if MSAL only — confirm |

---

## 14. Consultation

| Stakeholder | Consultation needed |
|---|---|
| Legal counsel | **Required** — full PIA |
| Pilot org privacy lead | Recommended |
| Survivor advocacy advisors | Recommended for L4 and safety flows |
| DPO (if org has one) | Per org |

---

## 15. Approval record (blank)

| Reviewer | Role | Date | Approved |
|---|---|---|---|
| | Privacy counsel | | ☐ |
| | SafeCase security lead | | ☐ |
| | Product executive | | ☐ |
| | Pilot org DPO/representative | | ☐ |

---

## 16. Related documents

- [security-acceptance-criteria.md](./security-acceptance-criteria.md)  
- [pilot-operating-procedures.md](./pilot-operating-procedures.md)  
- [organization-onboarding.md](./organization-onboarding.md)  
- [data-classification.md](./data-classification.md)  

---

## 17. PIA completion checklist (for counsel)

- [ ] Jurisdiction map completed  
- [ ] Lawful basis documented per processing activity  
- [ ] Special category data analysis (if applicable)  
- [ ] DPIA required? (EU/UK high risk)  
- [ ] Breach notification thresholds documented  
- [ ] Data subject rights procedures agreed  
- [ ] Subprocessor list finalized  
- [ ] Privacy notices published  
- [ ] Signoff attached to Phase 8 gate  
