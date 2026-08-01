# SafeCase Pilot Organization Onboarding Checklist

> **Status:** DRAFT / PENDING LEGAL REVIEW  
> **Version:** 0.1  
> **Last updated:** 2026-08-01  

Use this checklist when onboarding a victim-services organization to the SafeCase pilot program. Two tracks: **pre–Phase 8 (synthetic)** and **Phase 8 go-live (real data)**.

---

## 1. Eligibility (draft criteria)

Pilot organizations should:

- [ ] Provide victim-services, advocacy, shelter, or related programs  
- [ ] Designate an executive sponsor and primary org admin  
- [ ] Accept DRAFT policies pending final legal review for early synthetic phases  
- [ ] Commit to MFA for all users  
- [ ] Agree to no real client data until written Phase 8 signoff  
- [ ] Have contingency plan for platform downtime (not primary emergency dispatch)  

---

## 2. Pre-onboarding (SafeCase team)

| Step | Owner | Done |
|---|---|---|
| Execute mutual NDA (if not covered by MSA) | Legal | ☐ |
| Confirm pilot tier (free pilot scope per commercial plan) | Product | ☐ |
| Create organization record in SafeCase (staging/prod as appropriate) | Engineering | ☐ |
| Configure Entra External ID tenant relationship / invitation policy | Identity | ☐ |
| Assign Platform Operator support contacts | Ops | ☐ |
| Send governance packet link (this repo) | Customer success | ☐ |

---

## 3. Organization profile setup

| Item | Detail | Done |
|---|---|---|
| Legal organization name | | ☐ |
| Display name in SafeCase | | ☐ |
| Primary timezone | | ☐ |
| Programs to configure (names only pre-data) | | ☐ |
| Locations (non-L4 addresses for offices) | | ☐ |
| Default caseload visibility policy (assigned-only vs program-wide) | | ☐ |
| Retention preference (within counsel-approved bounds) | | ☐ |

---

## 4. People and roles

| Step | Done |
|---|---|
| Identify **Organization Owner** (1–2) | ☐ |
| Identify **Organization Administrator(s)** | ☐ |
| Map staff to roles per [access-control-matrix.md](./access-control-matrix.md) | ☐ |
| Document who may receive L4 permissions (minimal set) | ☐ |
| Identify Referral Partners (if any) — separate onboarding | ☐ |
| Identify Report Analysts and Auditors | ☐ |

### Role assignment principles

- Default advocates to **assigned cases only**  
- Do not grant Org Owner automatic L4 read unless explicitly approved  
- Referral partners: separate Entra guest accounts, narrowest role  
- No shared user accounts  

---

## 5. Identity and access

| Step | Done |
|---|---|
| Entra invitation emails sent to all users | ☐ |
| MFA enforced (per [identity/entra-external-id-runbook.md](./identity/entra-external-id-runbook.md)) | ☐ |
| Users complete first login and org selection | ☐ |
| Verify disabled test account cannot access API | ☐ |
| Document offboarding process with HR contact | ☐ |

---

## 6. Training and acknowledgments

| Training topic | Audience | Done |
|---|---|---|
| Synthetic data only (pre–Phase 8) | All | ☐ |
| Data classification L3/L4 | Advocates, supervisors | ☐ |
| Escalation and IR contacts | Admins | ☐ |
| Export and sharing rules | Supervisors+ | ☐ |
| Audit review basics | Org Owner, admin | ☐ |

| Acknowledgment | Done |
|---|---|
| Signed pilot operating procedures acceptance | ☐ |
| Acceptable use policy (AUP) | ☐ |
| No real data until Phase 8 signoff | ☐ |

---

## 7. Synthetic pilot validation (pre–Phase 8)

Org completes end-to-end workflow in **staging** with synthetic clients:

| Workflow step | Done |
|---|---|
| Sign in via Entra | ☐ |
| Select organization | ☐ |
| Create synthetic client | ☐ |
| Open case | ☐ |
| Assign advocate | ☐ |
| Add case note | ☐ |
| Create task | ☐ |
| View timeline | ☐ |
| Admin reviews audit entry | ☐ |

| Validation | Done |
|---|---|
| Confirm no real PII entered during training | ☐ |
| Submit feedback / bug reports via approved channel | ☐ |

---

## 8. Phase 8 go-live gate (real data)

**Do not proceed until all are complete.**

### SafeCase deliverables

| Item | Done |
|---|---|
| [security-acceptance-criteria.md](./security-acceptance-criteria.md) signed for production pilot | ☐ |
| Pen test critical/high remediated | ☐ |
| DR / backup restore tested | ☐ |
| [incident-response.md](./incident-response.md) contacts exchanged | ☐ |
| Support channels live | ☐ |

### Legal / contractual

| Item | Done |
|---|---|
| Data Processing Agreement (DPA) executed | ☐ |
| Subprocessor list provided | ☐ |
| Retention schedule agreed ([retention-policy.md](./retention-policy.md)) | ☐ |
| Breach notification terms understood | ☐ |

### Organization deliverables

| Item | Done |
|---|---|
| Executive sponsor written approval for real data | ☐ |
| All users trained on live data handling | ☐ |
| Local emergency / downtime contingency documented | ☐ |
| Designated IR point of contact | ☐ |
| Caseload migration plan (if any) — **not** from macOS prototype SQLite by default | ☐ |

### Go-live signoff

| Signer | Role | Date | Signature |
|---|---|---|---|
| | Org executive sponsor | | |
| | Org admin | | |
| | SafeCase Platform Operator | | |

---

## 9. Post-go-live (first 30 days)

| Activity | Week | Done |
|---|---|---|
| Check-in call | 1 | ☐ |
| Audit sample review (access patterns) | 2 | ☐ |
| User access review (role appropriateness) | 4 | ☐ |
| Feedback survey | 4 | ☐ |

---

## 10. Offboarding (pilot end)

| Step | Done |
|---|---|
| Export org data per DPA | ☐ |
| Disable all memberships | ☐ |
| Revoke Entra guest accounts | ☐ |
| Confirm retention/deletion schedule | ☐ |
| Exit interview / lessons learned | ☐ |

---

## 11. Contacts template

| Role | Organization | SafeCase |
|---|---|---|
| Executive sponsor | Name / email / phone | |
| Primary admin | | |
| Security / IR POC | | security@safecase.org (TBD) |
| Pilot support | | pilot@safecase.org (TBD) |
| Billing (if applicable) | | |

---

## 12. Related documents

- [pilot-operating-procedures.md](./pilot-operating-procedures.md)  
- [access-control-matrix.md](./access-control-matrix.md)  
- [privacy-impact-assessment.md](./privacy-impact-assessment.md)  
- [REPO_MAP.md](./REPO_MAP.md)  
