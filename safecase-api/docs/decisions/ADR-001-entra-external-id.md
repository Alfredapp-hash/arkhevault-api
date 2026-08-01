# ADR-001: Microsoft Entra External ID

**Status:** Accepted

## Decision

Use Microsoft Entra External ID with browser-delegated OIDC for staff authentication. SafeCase will not store passwords.

## Consequences

- No custom password reset
- MFA/Conditional Access centrally managed
- Application roles/permissions remain in SafeCase DB
