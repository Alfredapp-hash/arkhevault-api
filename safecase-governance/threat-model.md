# SafeCase Threat Model (STRIDE v0)

> **Status:** DRAFT / PENDING LEGAL REVIEW  
> **Version:** 0.1  
> **Last updated:** 2026-08-01  
> **Methodology:** STRIDE (Spoofing, Tampering, Repudiation, Information disclosure, Denial of service, Elevation of privilege)

This document is a **version 0** threat model for the SafeCase Azure architecture at pilot. It supports Phase 8 pen test scoping and control prioritization. It is not a substitute for a formal security assessment.

---

## 1. System overview

```text
[Staff browser / MSAL SPA]
         │ HTTPS + OIDC
         ▼
[Microsoft Entra External ID]
         │ JWT (access token)
         ▼
[SafeCase API — ASP.NET Core on App Service]
         │
    ┌────┴────┬──────────────┐
    ▼         ▼              ▼
[PostgreSQL   [Blob         [Key Vault]
 + RLS]        Storage]
```

**Trust boundaries:**

- TB1: Internet → Entra / Web / API edge  
- TB2: API → data plane (Postgres, Blob, Key Vault)  
- TB3: Tenant A ↔ Tenant B (logical)  
- TB4: Authorized staff ↔ unauthorized staff (same org)  
- TB5: SafeCase platform ↔ pilot organization  

**Assets:**

- Client/survivor PII and L4 safety data  
- Authentication tokens and session context  
- Audit integrity  
- Document blobs  
- Org configuration and consent records  

---

## 2. Threat actors

| Actor | Motivation | Capability |
|---|---|---|
| Anonymous external attacker | Data theft, ransomware | Network scanning, credential stuffing |
| Authenticated user (wrong org) | Curiosity, fraud | Valid Entra account, API access |
| Authenticated staff (same org) | Insider curiosity, harassment | Legitimate low-privilege role |
| Privileged insider (admin) | Mass export, stalking | Admin roles, export tools |
| Referral partner (compromised) | Collateral data access | Narrow external account |
| Platform operator (malicious/negligent) | Support abuse | Azure/support tooling |
| Supply chain | Backdoor | Dependency, CI compromise |

---

## 3. STRIDE analysis by component

### 3.1 Microsoft Entra External ID

| STRIDE | Threat | Example | Mitigations (draft) |
|---|---|---|---|
| **S** | Token theft via XSS on SPA | Malicious script exfiltrates MSAL cache | CSP, short-lived tokens, secure cookie settings, MSAL best practices |
| **S** | Phishing fake login | Credential harvest | Entra branding, MFA, conditional access |
| **T** | Tampered JWT claims | Forged `org_id` in client | API validates signature, issuer, audience; org from membership DB not token alone |
| **R** | User denies login | Account shared | Sign-in audit in SafeCase + Entra logs |
| **I** | Token leakage in referrer/logs | Token in URL query | Auth code + PKCE; no tokens in URLs |
| **D** | Entra outage blocks all access | IdP down | Downtime procedure; no unsafe bypass |
| **E** | Guest user over-provisioned | External user in admin group | Least privilege; app roles in SafeCase not Entra group sprawl |

### 3.2 SafeCase API (ASP.NET Core)

| STRIDE | Threat | Example | Mitigations (draft) |
|---|---|---|---|
| **S** | Stolen bearer token replay | Token from compromised laptop | Short TTL, refresh rotation, membership check each request |
| **T** | IDOR on `/clients/{id}` | Guess UUID cross-tenant | Authz + RLS; no existence leak |
| **T** | Mass assignment on update DTO | Escalate `organizationId` | Immutable tenant on writes; validation |
| **R** | Delete audit to hide access | Insider SQL | Append-only audit; restricted DB roles |
| **I** | Verbose error reveals record exists | 404 vs 403 timing | Consistent error model; no stack traces |
| **I** | Log injection of client PII | Note body in exception | Scrub logging; classification policy |
| **D** | Expensive search/query | Regex DoS on search | Rate limits, pagination, query timeouts |
| **E** | Missing permission check on new endpoint | Dev forgets `[Authorize]` | Authorization tests in CI; policy handlers |

### 3.3 PostgreSQL + RLS

| STRIDE | Threat | Example | Mitigations (draft) |
|---|---|---|---|
| **S** | App uses superuser connection | Bypass RLS | App role without BYPASSRLS; separate migration role |
| **T** | SQL injection | Raw SQL in report | Parameterized queries; ORM |
| **T** | Session variable not set | `current_organization_id` empty → leak or deny-all bug | Middleware sets session; integration tests |
| **I** | Backup theft | Stolen backup file | Encryption at rest, private networking, access control |
| **I** | Replica exposed | Misconfigured firewall | Private endpoints prod |
| **E** | RLS policy gap on new table | Forgotten policy | Migration checklist; tenant isolation tests |

### 3.4 Azure Blob Storage

| STRIDE | Threat | Example | Mitigations (draft) |
|---|---|---|---|
| **S** | SAS token shared externally | Long-lived URL forwarded | Short TTL SAS; user-delegated keys; re-auth at API |
| **T** | Path traversal upload | `../../other-org/file` | Strict path convention; server-side path build |
| **I** | Public container misconfiguration | `container` set to blob public | IaC policy; periodic audit |
| **I** | Cross-tenant URL reuse | Org A SAS works for Org B path | Org prefix in path; authz before SAS mint |
| **D** | Large upload exhaustion | Multi-GB upload | Size limits, WAF (later) |
| **E** | Malware in document | Infected PDF | Scan pipeline; quarantine |

### 3.5 Azure Key Vault

| STRIDE | Threat | Example | Mitigations (draft) |
|---|---|---|---|
| **I** | Secret exfiltration via compromised API | MI over-permissioned | Least privilege RBAC on KV |
| **T** | Key rotation failure | Stale compromised key | Rotation runbook |
| **E** | Developer embeds secret in repo | `.env` committed | Secret scanning; no secrets in git |

### 3.6 Staff misuse (insider)

| STRIDE | Threat | Example | Mitigations (draft) |
|---|---|---|---|
| **I** | Advocate browses unassigned clients | Curiosity | Assignment-scoped permissions; audit reads |
| **I** | Supervisor exports caseload to personal email | Harassment prep | Export controls, watermark, DLP (future) |
| **I** | Admin grants self L4 access | Stalking | Separation of duties; alert on role change |
| **R** | Denies viewing restricted note | HR dispute | Immutable audit with actor |
| **E** | Intake specialist escalates to admin | Social engineering | Ticket-based role change; owner approval |

### 3.7 Export abuse

| STRIDE | Threat | Example | Mitigations (draft) |
|---|---|---|---|
| **I** | Bulk export for identity theft | CSV of all clients | Export permission narrow; rate limits; audit |
| **I** | Report re-identification | Small-N cell in grant report | Suppression rules; Report Analyst training |
| **I** | L4 in export bundle | Safety plan in PDF export | Classification filter; L4 blocked by default |
| **T** | Modified export after download | Out of scope — client-side | Watermark org/user/time |
| **R** | User denies export | Legal discovery | Export audit events |

---

## 4. Data flow threats (end-to-end)

### 4.1 Login → view client record

| Step | Risk | Control |
|---|---|---|
| OIDC login | Phishing | MFA, Entra CA |
| Token to API | XSS theft | CSP, MSAL |
| Resolve org | Wrong org selected | Explicit org picker; membership validation |
| Load client | Cross-tenant IDOR | Authz + RLS |
| Render UI | Shoulder surfing | Session timeout; org policy |
| Telemetry | PII in App Insights | Scrubber |

### 4.2 Upload document

| Step | Risk | Control |
|---|---|---|
| Client → API | Unauthorized upload | `document.upload` + case assignment |
| API → Blob | Wrong path | Server-built path with org id |
| Scan | Malware | Defender scan (TBD) |
| Download link | URL sharing | Short SAS + audit |

---

## 5. Out-of-scope (v0) — track for v1

- Survivor portal authentication  
- Full offline sync on devices  
- AI/LLM integration (see [data-classification.md](./data-classification.md) §4)  
- Mobile native apps  
- Azure Front Door + WAF (planned later)  
- Physical access to org devices  

---

## 6. Risk register (initial)

| ID | Threat | Likelihood | Impact | Priority | Owner |
|---|---|---|---|---|---|
| T-001 | Cross-tenant client IDOR | Medium | Critical | **P0** | API team |
| T-002 | L4 in application logs | Medium | Critical | **P0** | Platform |
| T-003 | Long-lived Blob SAS leak | Medium | High | **P1** | API + infra |
| T-004 | Insider mass export | Low | Critical | **P1** | Product + security |
| T-005 | Entra token via XSS | Low | High | **P1** | Web team |
| T-006 | Missing RLS on new table | Medium | Critical | **P0** | API team |
| T-007 | Support staff casual case browse | Medium | High | **P1** | Ops |
| T-008 | Synthetic → real data early | Medium | High | **P1** | Pilot ops |

---

## 7. Verification activities

| Activity | Phase | Output |
|---|---|---|
| Authorization integration tests | 2–4 | CI green |
| Tenant isolation manual test script | 3 | Signed run log |
| Penetration test | 8 | Report + remediation |
| Threat model review | 8 | Updated v1 |
| Tabletop IR exercise | 8 | Lessons learned |

---

## 8. Related documents

- [data-classification.md](./data-classification.md)  
- [access-control-matrix.md](./access-control-matrix.md)  
- [security-acceptance-criteria.md](./security-acceptance-criteria.md)  
- [incident-response.md](./incident-response.md)  

---

## 9. Revision history

| Version | Date | Notes |
|---|---|---|
| v0 | 2026-08-01 | Initial STRIDE draft for pilot scoping |
