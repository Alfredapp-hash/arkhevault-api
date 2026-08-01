# Core Data Inventory (prototype reference)

Source: `Core/Data/ForgedInFireDataModel.xcdatamodeld/contents` in the macOS prototype.

## Entities (14)

1. Client — identity + demographics + needs + address + risk
2. SafetyFlag — flagType, severity, active/resolved
3. Program — capacity, eligibility transformables
4. ProgramEnrollment — goals, dates, status
5. CaseNote — narrative, visibility, supervisor review
6. Task — due, priority, auto triggers
7. Appointment — schedule fields
8. SafeHouse — confidentialLocation (**L4**), capacity
9. SafeHousePlacement — placement/exit plans (**L4**)
10. Staff — email/role/permissions (auth SoT today — **retire**)
11. Referral — destination, consentConfirmed, documentsShared
12. Document — filePath (local), visibility
13. Communication — content, safeContactWarningsRespected
14. ProgramOutcome — metrics

## Missing vs Azure target

Organization, Membership, Consent*, AuditEvent*, Case (first-class), Document Blob metadata, AccessPolicy, EmergencyAccessEvent.

## Migration stance

**Scenario A:** do not migrate prototype SQLite. Use this inventory for field requirements only.
