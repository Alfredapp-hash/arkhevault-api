# SafeCase Data Classification Policy

> **Status:** DRAFT / PENDING LEGAL REVIEW  
> **Version:** 0.1  
> **Last updated:** 2026-08-01  
> **Applies to:** All SafeCase environments (development, staging, production pilot)

---

## 1. Purpose

SafeCase stores information about survivors, clients, and confidential program operations. This policy defines five classification levels (0–4) so that storage, access, logging, export, analytics, and AI processing can apply appropriate controls **before** data is written.

Classification is mandatory at:

- Field/entity design time (schema documentation)
- API write paths (validate and tag)
- Document upload (guess + user confirmation)
- Log and telemetry emission (strip or block by level)
- Export and reporting (filter and watermark)

---

## 2. Classification levels

### Level 0 — Public

**Definition:** Information approved for public release with no expectation of confidentiality.

| SafeCase examples | Controls |
|---|---|
| Marketing product descriptions, public program names (non-identifying), published grant award totals (aggregate), open job postings | Standard web caching OK; no special RLS beyond tenant admin config |

**Storage:** Any appropriate store. **Logging:** Full content permitted in operational logs.

---

### Level 1 — Internal

**Definition:** Non-public operational information that would not typically harm individuals if disclosed, but is not intended for external audiences.

| SafeCase examples | Controls |
|---|---|
| Organization settings (non-client), feature flags, internal task templates, staff training schedules (no client linkage), API health metrics, anonymized usage counters | Tenant-scoped access; no cross-org visibility; avoid in client-facing exports |

**Storage:** PostgreSQL, configuration stores. **Logging:** Permitted with tenant ID; avoid coupling to client IDs in aggregate ops logs where unnecessary.

---

### Level 2 — Confidential (operational)

**Definition:** Business-sensitive or moderately sensitive operational data. Unauthorized disclosure could cause organizational harm or indirectly affect clients.

| SafeCase examples | Controls |
|---|---|
| Referral partner directory (contact info), program capacity metrics, non-identifying caseload statistics, volunteer rosters (no survivor linkage), internal org financial config for billing | Role-based permissions; audit sensitive reads; not included in default exports |

**Storage:** PostgreSQL with tenant RLS. **Logging:** Metadata only in App Insights (resource type, action, outcome — not full payload).

---

### Level 3 — Protected client information

**Definition:** Personally identifying or sensitive information about clients/survivors that requires strong access controls and audit. Typical victim-services casework data.

| SafeCase examples | Controls |
|---|---|
| Legal name, aliases, date of birth, phone, email, address, case notes (standard), intake records, appointment details, program enrollment, general safety concerns (non-location), consent records, document metadata | `client.read` / `case.read` permissions; assignment or program scope where configured; full audit on read/write/export; encrypted at rest (Azure platform + app layer for selected fields TBD); no content in telemetry |

**Storage:** PostgreSQL (RLS), Blob for documents classified L3 unless elevated. **Logging:** Audit events with actor and resource ID; **never** log note body or contact values in Application Insights.

**Export:** Watermarked; consent checks for third-party sharing; time-limited download links.

---

### Level 4 — Highly restricted

**Definition:** Information whose disclosure could reasonably lead to imminent physical harm, location compromise, or severe privacy violation. Requires the strictest technical and procedural controls.

| SafeCase examples | Controls |
|---|---|
| Safe house / confidential shelter location, current hiding place, escape plan details, active stalker location intelligence, unlisted contact methods explicitly marked safe-only, covert placement records, certain restraining-order adjacency details, emergency safety narratives | Separate permissions (`note.read_restricted`, `safety.read`, `location.read_confidential`); narrower role set; enhanced audit alerts; field-level redaction in UI for unauthorized roles; **no default export**; legal hold support; break-glass emergency access with mandatory reason + supervisor alert |

**Storage:** PostgreSQL with column-level or entity-level tagging; Blob in restricted container prefix; optional additional encryption (Key Vault CMK — implementation TBD). **Logging:** Audit metadata only; **never** in Application Insights, search indexes, or error reports.

---

## 3. Level 4 additional controls (mandatory)

The following apply to all Level 4 data in every environment:

1. **Permission narrowing** — Only roles explicitly granted L4 permissions may read or write; Org Owner does not automatically inherit all L4 reads unless policy explicitly allows (default: **deny** for Owner on L4 read; break-glass only).
2. **Dual control for export** — L4 export requires elevated permission + consent/safety review workflow (Phase 5+); default is **no export**.
3. **UI redaction** — Users without L4 permission see existence indicators only where clinically necessary (product decision per screen), never content.
4. **Audit alerting** — L4 read, failed access, emergency access, and export attempts generate high-severity audit events and operator notification (async).
5. **Session constraints** — Shorter idle timeout recommended for sessions that touch L4 (org-configurable, TBD).
6. **Document pipeline** — L4 uploads flagged at ingest; malware scan; restricted Blob path; download requires re-authorization per request.
7. **Search** — Full-text search indexes must exclude L4 body content or use separate restricted index with permission-filtered queries.
8. **Backup access** — Restore of L4-containing backups is ops-only with ticket and audit (see retention and IR docs).

---

## 4. Analytics and AI — default prohibition for Level 4

> **Policy (draft):** Level 4 data **must not** be sent to analytics pipelines, business intelligence tools, third-party AI services, or model training by default.

### Prohibited destinations (L4)

- Application Insights custom events containing field values
- Log Analytics queries over raw request bodies
- Aggregate report exports that could reconstruct location or identity
- External LLM APIs (OpenAI, Azure OpenAI, etc.) unless explicit Phase 8+ approved gateway with redaction
- Copilot or similar tools indexed on production databases
- Prototype `AIService` patterns from macOS app (client-held keys) — **deprecated**

### Permitted analytics (with constraints)

| Data level | Analytics use |
|---|---|
| L0–L1 | Standard operational metrics |
| L2 | Aggregated, k-anonymized counts (e.g., cases opened per program per month) |
| L3 | **De-identified** aggregates only with defined suppression rules (minimum cell size, no small-N program leaks) |
| L4 | **Excluded** unless counsel and security approve a specific documented exception with technical enforcement |

### AI feature gate (future)

When AI features are introduced (post–M4 per conversion plan):

1. Authenticate and authorize caller  
2. Resolve data classification per field  
3. Check consent and org AI policy  
4. Redact L4 and non-consented L3  
5. Route through approved gateway with prompt/response logging (metadata only)  
6. Human review before any client-facing automated action  
7. **Never** auto-send L4 content externally  

---

## 5. Classification assignment rules

| Scenario | Default level | User action |
|---|---|---|
| New client name | L3 | Auto |
| Case note (general) | L3 | Auto; user may mark subset L4 |
| Safe house address | L4 | Auto + confirmation |
| Organization billing email | L2 | Auto |
| Public-facing program description | L0/L1 | Admin marked |
| Uploaded PDF (unknown) | L3 guess | User confirms on upload |
| Audit event payload | L1 metadata | System; no client narrative |

When in doubt, classify **up** one level until reviewed.

---

## 6. Environment-specific rules

| Environment | Real client data | L4 synthetic rules |
|---|---|---|
| Development | **Prohibited** (synthetic only) | Use obviously fake locations ("Example City Shelter Test Site") |
| Staging | **Prohibited** unless approved scrubbed fixture | Same as dev |
| Production pilot | **Prohibited until Phase 8 signoff** | N/A until go-live |
| macOS prototype | **Always prohibited** | Never sync to cloud |

---

## 7. Implementation checklist (engineering)

- [ ] Schema documents mark each field with max classification  
- [ ] API rejects writes that downgrade classification without permission  
- [ ] RLS policies tenant-scoped for all L2+  
- [ ] L4 permission constants in authorization tests  
- [ ] Telemetry scrubber unit tests (no L3/L4 patterns in logs)  
- [ ] Export pipeline reads classification tags  
- [ ] Blob path convention includes classification segment (TBD in api docs)  

---

## 8. Review and exceptions

Exceptions to L4 analytics/AI ban require:

1. Written request with purpose and data elements  
2. Security + privacy review  
3. Legal counsel signoff for pilot/production  
4. Technical control implementation **before** enablement  
5. Time-bound approval with renewal date  

---

## 9. Related documents

- [access-control-matrix.md](./access-control-matrix.md) — L4 permissions by role  
- [retention-policy.md](./retention-policy.md) — retention by class  
- [pilot-operating-procedures.md](./pilot-operating-procedures.md) — synthetic data until Phase 8  
- [threat-model.md](./threat-model.md) — export and staff misuse  
