# Core Data → Azure Domain Mapping

**Source:** `Core/Data/ForgedInFireDataModel.xcdatamodeld/contents`  
**Strategy:** Scenario A — reference extraction only; clean PostgreSQL migrations; no prototype DB migration.

---

## 1. Entity mapping overview

| Core Data entity | Target Azure entities | Notes |
|---|---|---|
| *(missing)* | Organization, OrganizationSettings, OrganizationLocation, OrganizationProgram | Must invent; not in prototype |
| Staff | User + OrganizationMembership + Role bindings | Staff must not remain auth source of truth |
| Client | Client, ClientIdentity, ClientContactMethod, ClientAddress, ClientRiskProfile, ClientCommunicationPreference | Split identity from casework profile |
| *(missing Case)* | Case, CaseAssignment, CaseStatus, CaseTimelineEvent | Introduce first-class Case; prototype folds casework into Client |
| CaseNote | CaseNote | Add org_id, visibility, audit; narrative is L3/L4 by content |
| SafetyFlag | SafetyConcern / RiskAssessment linkage | Elevate toward SafetyPlan model in Phase 5 |
| Program / ProgramEnrollment / ProgramOutcome | OrganizationProgram + enrollment/outcome tables | Tenant-scope |
| Task | Task, TaskAssignment, Deadline, Reminder, Escalation | Keep MVP subset first |
| Appointment | Appointment, Reminder | EventKit sync is client-only convenience later |
| Referral | Referral, ReferralRecipient, ReferralStatus, ReferralFollowUp, ExternalProvider | Requires Consent gates |
| Document | Document, DocumentVersion, DocumentClassification, DocumentAccessGrant, DocumentRetentionRule, DocumentDownloadEvent | filePath → Blob key |
| SafeHouse / SafeHousePlacement | ConfidentialLocation + placement records | **Level 4** |
| Communication | Communication preference + contact attempts | Respect safe-contact windows |
| *(missing)* | ConsentRecord, ConsentScope, ConsentRevocation, InformationSharingAuthorization | Required before referrals/share |
| *(missing)* | AuditEvent, AccessEvent, ExportEvent, AuthenticationEvent | Server-authoritative |
| PendingChange (referenced, not in model) | **Retire for v1** | No full offline DB |

---

## 2. Client field mapping

| Core Data field | Target | Classification | Action |
|---|---|---|---|
| id | clients.id (uuid) | L1 | Keep UUID |
| firstName, lastName | client_identities.* | L3 | Separate identity table |
| dateOfBirth | client_identities.date_of_birth | L3 | |
| contactEmail, contactPhone | client_contact_methods | L3 | Typed methods + safe flags |
| biography | clients.biography or note | L3 | Consider note-type instead |
| emergencyContact* | emergency_contacts | L3/L4 if safety-linked | |
| householdMembers, dependents | normalized child tables or JSONB with policy | L3 | Prefer normalized later |
| veteranStatus | clients.veteran_status | L2/L3 | |
| housing/employment/transportationStatus | clients.* | L3 | |
| legal/medical/mentalHealth/recoveryNeeds | service_needs | L3/L4 | Do not log contents |
| safetyConcerns | safety_concerns | **L4** | Restricted |
| riskLevel | client_risk_profiles | L3/L4 | Server-calculated optional |
| safeContactRules | safe_contact_windows / preferences | **L4** | |
| confidentialAddress + address* | client_addresses + confidential flag | L3/L4 | |
| lastContactDate, status | clients.* / derived | L2/L3 | |
| createdAt, updatedAt | audit columns + concurrency token | L1 | Add xmin/rowversion |
| assignedAdvocate, createdBy | case_assignments / actors as membership ids | L2 | Use membership IDs not raw staff |

---

## 3. Document mapping

| Core Data | Azure |
|---|---|
| filePath | storage_container + storage_key (Blob) |
| documentName | original_filename + display_filename (normalized) |
| documentType / mimeType | content_type allowlist |
| fileSize | size + checksum sha256 |
| visibilityLevel / accessRestrictions | document_access_grants + classification |
| uploadDate / uploadedBy | uploaded_at / uploaded_by membership |
| version | document_versions |
| *(missing)* | malware_scan_status, retention_rule, legal_hold |

Blob path:

```text
organizations/{organizationUuid}/clients/{clientUuid}/documents/{documentUuid}
```

---

## 4. AuthZ mapping

| Prototype | Azure |
|---|---|
| Staff.email + Keychain password hash | Entra External ID user |
| Staff.role string | OrganizationMembership + Role |
| Staff.permissions transformable | Permission grants (normalized) |
| Staff.mfaEnabled flag | Entra MFA / Conditional Access |
| isAdmin helper in Swift | API policy handlers |

---

## 5. MVP schema slice (Phase 3–4)

Minimum tables for the vertical slice:

```text
organizations
users
organization_memberships
roles
permissions
role_permissions
membership_roles
clients
client_identities
client_contact_methods
cases
case_assignments
case_notes
tasks
case_timeline_events
audit_events
```

Every tenant table includes `organization_id uuid not null`.

---

## 6. RLS sketch

```sql
ALTER TABLE cases ENABLE ROW LEVEL SECURITY;
CREATE POLICY cases_tenant_policy ON cases
USING (organization_id = current_setting('app.current_organization_id')::uuid);
```

API must `SET LOCAL app.current_organization_id` per request/transaction after authorization.

---

## 7. Explicit retire list from prototype storage

- Local password hashes  
- Keychain Claude API key as production path  
- Document filePath as authoritative content  
- Local security_events.log as compliance audit  
- Offline PendingChange queue as v1 sync  
- Transformable “encrypted” string fields without cryptography  
- Client-side rate limiter as security boundary  
