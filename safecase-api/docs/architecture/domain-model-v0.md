# Domain Model v0 (MVP vertical slice)

## Aggregates

| Aggregate | Tables | Notes |
|---|---|---|
| Organization | organizations, organization_memberships, roles, permissions | Multi-tenant root |
| User | users | Linked by Entra object ID; no password fields |
| Client | clients, client_identities, client_contact_methods | Identity separated from operational client row |
| Case | cases, case_assignments, case_notes, case_timeline_events | First-class case (not present in Core Data) |
| Task | tasks | Org-scoped; optional case/client link |
| Audit | audit_events | Append-only; hash fields reserved |

## Classification highlights

- `client_identities.*`, contact methods → Level 3
- `case_notes.narrative` → Level 3 (may be Level 4 by content; visibility_level=restricted)
- `audit_events` must not store narratives/PII payloads

## Optimistic concurrency

`RowVersion` (`xmin` via EF) on mutable entities.

## Out of scope for v0

Consent, safety plans, documents/Blob metadata, referrals, reporting marts.
