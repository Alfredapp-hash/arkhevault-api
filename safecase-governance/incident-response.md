# SafeCase Incident Response Plan (Outline)

> **Status:** DRAFT / PENDING LEGAL REVIEW  
> **Version:** 0.1  
> **Last updated:** 2026-08-01  

This document outlines roles, severity levels, and notification steps for security and privacy incidents affecting SafeCase. It must be exercised in a tabletop before Phase 8 pilot signoff.

**SafeCase is not an emergency services provider.** Life-safety emergencies follow each organization's local protocol first (see [pilot-operating-procedures.md](./pilot-operating-procedures.md) §7.2).

---

## 1. Objectives

1. Contain harm to survivors, clients, and organizations  
2. Preserve evidence for investigation  
3. Meet contractual and legal notification obligations  
4. Restore secure service  
5. Document lessons learned and improve controls  

---

## 2. Incident types (in scope)

| Type | Examples |
|---|---|
| **Unauthorized access** | Cross-tenant data view, stolen token, compromised account |
| **Data disclosure** | Email mis-send, public Blob URL, export to wrong party |
| **Insider abuse** | Staff browsing outside assignment, mass export |
| **Malware** | Infected document upload affecting storage or users |
| **Availability** | API/DB outage affecting casework (see also operational incident) |
| **Integrity** | Audit tampering, unauthorized record modification |
| **Policy violation** | Real data in pre–Phase 8 environment, L4 in analytics |
| **Supply chain** | Compromised dependency, CI/CD breach |

---

## 3. Roles and responsibilities

| Role | Responsibility | Primary contact (TBD) |
|---|---|---|
| **Incident Commander (IC)** | Overall coordination, severity calls | SafeCase security lead |
| **Platform Operator** | Azure containment, log preservation, restore | Engineering on-call |
| **Security Lead** | Investigation, forensics coordination | SafeCase security |
| **Privacy / Legal** | Breach determination, regulator/client notice | External counsel |
| **Comms Lead** | Org and user messaging (approved text only) | Product / exec |
| **Org Point of Contact** | Pilot org admin — local user actions | Per onboarding doc |
| **Scribe** | Timeline, decisions, evidence chain | Rotating staff |

**RACI summary:**

- **Contain:** Platform Operator (R), IC (A)  
- **Notify org:** Comms + Privacy (R), IC (A)  
- **Notify regulators:** Legal (R), exec (A)  
- **Disable accounts:** Org admin + Platform Operator (R)  

Fill named contacts and 24/7 reachability before pilot.

---

## 4. Severity levels

| Level | Definition | Examples | Initial response target |
|---|---|---|---|
| **SEV-1 Critical** | Active exploitation of client L3/L4 data or cross-tenant breach | Confirmed IDOR exfiltration, ransomware in prod DB | **15 min** acknowledge; **1 hr** containment start |
| **SEV-2 High** | Likely breach or major control failure | Lost admin credential, public Blob misconfig (fixed), real data in dev | **1 hr** acknowledge; **4 hr** plan |
| **SEV-3 Medium** | Limited impact or contained issue | Single account phishing, failed pen test finding in staging | **1 business day** |
| **SEV-4 Low** | Near miss, policy deviation without exposure | Synthetic data naming violation, audit gap in non-prod | **3 business days** |

Escalate severity if survivor safety could be imminently affected by disclosure (e.g., L4 shelter location leak → treat as SEV-1).

---

## 5. Response phases

### Phase A — Detect & triage

1. Report received via security contact, monitoring alert, org report, or pen test.  
2. IC assigned; scribe starts timeline.  
3. Initial classification (type + severity).  
4. Preserve logs: Application Insights, Entra sign-in, audit table, Azure Activity Log — **do not** mass-delete.

### Phase B — Contain

| Action | When |
|---|---|
| Disable compromised Entra accounts | Stolen credentials |
| Disable SafeCase membership | Insider or partner abuse |
| Revoke SAS / rotate keys | Blob or secret leak |
| Block IP / WAF rule | Active attack (when WAF available) |
| Take affected API slot offline | Active exploitation unpatched |

Document every containment action with timestamp and operator.

### Phase C — Investigate

- Scope: which orgs, clients, fields, time window  
- Root cause: vulnerability, misconfig, process failure  
- Evidence: audit export, access logs (metadata only in tickets)  
- Engage external forensics if SEV-1/2 and counsel approves  

### Phase D — Notify

**Notification outline (not legal advice):**

| Stakeholder | Trigger (draft) | Lead |
|---|---|---|
| Affected pilot org(s) | Confirmed or likely unauthorized access to their tenant data | Comms + IC |
| Affected individuals (clients/survivors) | Legal determination of reportable breach | Legal + org |
| Regulators | Per applicable law (HIPAA, state breach laws, PIPEDA, etc.) | Legal |
| SafeCase leadership / board | SEV-1/2 | IC |
| Microsoft / Azure | If platform compromise suspected | Platform Operator |

Notification content (draft sections):

1. What happened ( factual, no speculation)  
2. What data types involved (classification levels)  
3. What SafeCase and org have done  
4. Recommended user actions (password reset, MFA, monitoring)  
5. Contact for questions  
6. Timeline of next update  

**Timing:** Legal determines statutory deadlines. Internal goal: org notification within **24 hours** of confirmed SEV-1 affecting their tenant.

### Phase E — Recover

- Patch/deploy fix  
- Validate with authorization tests  
- Monitor elevated logging  
- Confirm service health with org POC  

### Phase F — Post-incident review

Within 10 business days for SEV-1/2:

- Root cause analysis  
- Control gaps mapped to [threat-model.md](./threat-model.md)  
- Action items with owners  
- Update governance docs and acceptance criteria if needed  

---

## 6. Communication rules

- **Do not** discuss active incidents on public channels or social media.  
- **Do not** include client PII or L4 details in Slack/email tickets — use internal incident system with access control.  
- Org-facing messages require Legal/Comms approval.  
- Preserve privilege where counsel engaged.  

---

## 7. Evidence handling

| Evidence | Handling |
|---|---|
| Audit database | Read-only export; chain of custody log |
| Application logs | Export window documented; restrict access |
| Entra logs | Via Azure portal / Graph; IC authorization |
| User reports | Screenshots — redact third-party PII |

Retention: see [retention-policy.md](./retention-policy.md) §2.4.

---

## 8. Playbooks (short)

### PB-001 — Suspected cross-tenant access

1. SEV-1 until proven otherwise  
2. Capture request trace IDs from reporter  
3. Platform Operator reviews API logs and audit  
4. If confirmed: disable affected accounts, notify orgs, emergency patch  
5. Run full tenant isolation test suite before close  

### PB-002 — L4 data in telemetry

1. SEV-2 minimum  
2. Stop offending log pipeline / deployment rollback  
3. Purge contaminated log segments where possible (Azure support)  
4. Assess whether disclosure constitutes breach  
5. Fix scrubber + add regression test  

### PB-003 — Real data entered pre–Phase 8

1. SEV-2  
2. Halt further entry; identify scope  
3. Legal assesses breach notification  
4. Secure delete or migrate per org direction after approval  

---

## 9. Testing schedule

| Exercise | Frequency |
|---|---|
| Tabletop (SEV-1 scenario) | Before Phase 8; then annual |
| Contact tree drill | Semi-annual |
| Backup restore | Annual |
| Tenant isolation retest | Each major release |

---

## 10. External resources

- Microsoft security incident reporting (if Azure compromise): via Azure Support portal  
- Law enforcement: org decision with legal counsel — SafeCase does not contact law enforcement for orgs without direction  

---

## 11. Related documents

- [pilot-operating-procedures.md](./pilot-operating-procedures.md)  
- [security-acceptance-criteria.md](./security-acceptance-criteria.md)  
- [privacy-impact-assessment.md](./privacy-impact-assessment.md)  
- [data-classification.md](./data-classification.md)  

---

## 12. Document activation

This plan is **draft** until:

- [ ] Named IC and backups assigned  
- [ ] 24/7 contact tree published internally  
- [ ] Org notification template approved by counsel  
- [ ] Tabletop completed with pilot org representative  
