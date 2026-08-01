# SafeCase Retention Policy (Outline)

> **Status:** DRAFT / PENDING LEGAL REVIEW  
> **Version:** 0.1  
> **Last updated:** 2026-08-01  

This outline defines retention categories for SafeCase data. **Final retention periods require legal counsel** input — victim-services organizations may have statutory, grant, and ethical obligations that override defaults below.

---

## 1. Purpose

- Meet legal, contractual, and funder requirements  
- Minimize data held beyond necessity (data minimization)  
- Preserve audit integrity for accountability  
- Support legal hold during litigation or investigation  

---

## 2. Retention categories

### 2.1 Operational / platform data

| Data type | Examples | Draft retention | Notes |
|---|---|---|---|
| Application logs (scrubbed) | Request metrics, trace IDs | 90 days hot, 1 year archive | No L3/L4 content |
| Infrastructure metrics | CPU, availability | 90 days | Azure Monitor defaults |
| Deployment artifacts | Container images, packages | Per release policy (e.g., 2 years) | Immutable prod tags |
| Synthetic test data | Dev/staging seeds | Until environment refresh | Destroy with environment |
| Support tickets (no client content) | Bug reports | 3 years | Redact if PII added |

### 2.2 Client / casework data

| Data type | Examples | Draft retention | Notes |
|---|---|---|---|
| Active client record | Profile, open cases | Duration of service + **org-configured period** | Default TBD with counsel |
| Closed case | Notes, timeline, tasks | **X years after closure** (org/funder rule) | Typical range 3–7 years — **not finalized** |
| Intake not converted | Abandoned intake | 90 days unless org policy longer | Auto-purge job |
| Consent records | Sharing authorizations | Life of case + retention period | Needed for dispute defense |
| L4 safety / location | Restricted fields | **Minimum necessary**; delete when safety purpose ends | Org safety policy |
| Referral artifacts | Outbound shares | Per consent scope + retention | Phase 6+ |

**Org override:** Organization Owner may request shorter retention where law permits, not longer without contract amendment.

### 2.3 Documents (Blob)

| Data type | Examples | Draft retention | Notes |
|---|---|---|---|
| Case documents | PDFs, images | Linked to case retention | Blob lifecycle rules |
| Malware quarantine | Failed scan objects | 30 days | Then secure delete |
| Temporary upload staging | Pre-scan buffer | 24 hours | Automatic cleanup |
| Legal hold objects | Any | **Indefinite until hold released** | Override lifecycle |

Blob path convention (from conversion plan):  
`organizations/{org}/clients/{client}/documents/{doc}`

### 2.4 Audit and security data

| Data type | Examples | Draft retention | Notes |
|---|---|---|---|
| Authentication audit | Sign-in success/fail | 2 years minimum | May extend for compliance |
| Authorization / data access audit | Read/write/export | **7 years** (draft) | Immutability required |
| Admin / role change audit | Membership, permissions | 7 years | |
| Security incident records | IR tickets, forensics | 7 years post-close | Counsel guidance |
| Export audit | Who exported what | 7 years | |

Audit retention **must not** be shorter than the longest client record retention without legal approval.

---

## 3. Deletion mechanics

| Mechanism | Description |
|---|---|
| **Soft delete** | User-facing delete marks record; recovery window (e.g., 30 days) for accidental deletion |
| **Hard delete** | Scheduled job purges after retention; cryptographic erasure for Blob |
| **Org offboarding** | Full tenant export window → delete all org-scoped data per DPA |
| **Backup expiry** | Backup retention aligned; restored backups must re-run purge jobs |

Deletion jobs must:

1. Respect legal hold flags  
2. Emit audit events (`data.purged`)  
3. Be idempotent  
4. Preserve aggregate de-identified statistics only if approved  

---

## 4. Legal hold

When hold is active for org, client, or case:

- Suspend automated purge for scoped records  
- Document hold reason, authority, and release date  
- Notify org admin and SafeCase ops  
- Hold overrides default retention until explicitly released  

---

## 5. Backup and disaster recovery retention

| Item | Draft policy |
|---|---|
| PostgreSQL PITR | 35 days (Azure configurable) |
| Geo-redundant backup | Per prod Bicep — staging/dev reduced |
| Restore testing | Annually; synthetic or scrubbed prod copy |

Restored environments containing real data require same access controls as production and must not be used for dev experimentation.

---

## 6. macOS prototype data

| Item | Policy |
|---|---|
| Local Core Data | Not migrated to Azure (Scenario A) |
| Retention | User responsibility on local device; recommend delete before decommission |
| Cloud sync | **None** — prototype must not sync to SafeCase Azure |

---

## 7. Pilot phase (pre–Phase 8)

All environments: **synthetic data only**. Retention focuses on operational hygiene — purge staging/dev frequently (e.g., monthly refresh). No long-term archival obligation for fictional clients.

---

## 8. Implementation checklist

- [ ] Retention periods confirmed with counsel  
- [ ] EF Core soft-delete pattern documented  
- [ ] Blob lifecycle management rules in Bicep  
- [ ] Scheduled purge workers with tenant context  
- [ ] Legal hold API (Phase 7+)  
- [ ] Org-facing retention summary in admin UI  
- [ ] DPA schedules reference this policy  

---

## 9. Related documents

- [data-classification.md](./data-classification.md)  
- [privacy-impact-assessment.md](./privacy-impact-assessment.md)  
- [incident-response.md](./incident-response.md) — evidence preservation  
- [pilot-operating-procedures.md](./pilot-operating-procedures.md)  

---

## 10. Open questions for counsel

1. Minimum retention for closed cases in `[jurisdiction]`?  
2. Grant funder audit trail requirements?  
3. Minor records special handling?  
4. Cross-border data residency (Canada, EU orgs)?  
5. Right-to-erasure vs mandatory retention conflict resolution?  
