# Microsoft Entra External ID — SafeCase Identity Runbook

> **Status:** DRAFT / PENDING LEGAL REVIEW  
> **Version:** 0.1  
> **Last updated:** 2026-08-01  
> **Audience:** Identity administrators, backend engineers, frontend engineers

This runbook describes how SafeCase uses **Microsoft Entra External ID** for customer identity and access management (CIAM). It covers app registration, token flow, SafeCase user mapping, MFA, account disablement, and local development patterns.

**Do not store Azure client secrets in git.** Use Key Vault and managed identities in deployed environments; use user secrets or local dev app registrations for development.

---

## 1. Why Entra External ID (not Azure AD B2C)

| Factor | Entra External ID | Legacy Azure AD B2C |
|---|---|---|
| **Microsoft direction** | Current CIAM offering for external identities | **No longer sold to new customers** |
| **SafeCase users** | Organization staff, partners — external to SafeCase tenant | B2C was alternative; avoid greenfield B2C |
| **Integration** | MSAL, OIDC, Conditional Access, MFA | Similar protocols but deprecated path for new workloads |
| **Multi-tenant SaaS** | External tenant + app registrations per environment | Would incur migration debt |

SafeCase standardizes on **Entra External ID external tenants** for pilot and production. Existing B2C tenants (if any legacy) are out of scope for this runbook.

---

## 2. Architecture overview

```text
┌─────────────┐     OIDC Auth Code + PKCE      ┌──────────────────────┐
│ safecase-web│ ─────────────────────────────►│ Entra External ID     │
│ (SPA, MSAL) │◄───────────────────────────────│ (external tenant)     │
└──────┬──────┘     ID token + access token     └──────────────────────┘
       │
       │  Authorization: Bearer {access_token}
       │  + SafeCase org context header (after login)
       ▼
┌─────────────┐     validate JWT, resolve user   ┌──────────────────────┐
│ safecase-api│ ───────────────────────────────►│ PostgreSQL            │
│             │     membership + permissions      │ User, Membership, …  │
└─────────────┘                                   └──────────────────────┘
```

**Critical rule:** Entra proves **who** the person is (authentication). SafeCase decides **what** they may do in **which organization** (authorization).

---

## 3. Identity mapping model

### 3.1 Entra → SafeCase chain

```text
Entra OID (object ID) ──► User.entra_object_id
                              │
                              ├── Membership (User + Organization)
                              │        │
                              │        └── Role → Permissions
                              │
                              └── (optional) PlatformOperator flag
```

| Entity | Source of truth | Key fields |
|---|---|---|
| **Entra user** | Entra External ID | `oid`, `email`, `name`, MFA status |
| **SafeCase User** | SafeCase PostgreSQL | `id`, `entra_object_id`, `display_name`, `email`, `is_disabled` |
| **Organization** | SafeCase PostgreSQL | `id`, `name`, settings |
| **Membership** | SafeCase PostgreSQL | `user_id`, `organization_id`, `role_id`, `is_disabled`, `invited_at` |
| **Role / Permission** | SafeCase PostgreSQL | Application-defined ([access-control-matrix.md](../access-control-matrix.md)) |

### 3.2 First login flow

1. User completes Entra OIDC login (MSAL in browser).  
2. SPA sends access token to API `GET /api/v1/me` (or equivalent).  
3. API validates JWT signature, issuer, audience, expiry.  
4. API looks up `User` by `oid` claim (`entra_object_id`).  
5. If no user:  
   - If valid invitation token → create User + Membership  
   - Else → 403 (no auto-provision without invite)  
6. API returns user profile + list of organizations + permissions per org.  
7. User selects organization (if multiple); SPA stores `currentOrganizationId` for subsequent calls.  
8. API middleware resolves membership for `currentOrganizationId` on every request.

### 3.3 Claims used (typical)

| Claim | Use |
|---|---|
| `oid` | Primary key link to SafeCase User |
| `sub` | Subject (fallback diagnostic) |
| `email` / `preferred_username` | Display, invitation matching |
| `name` | Display name sync (optional) |
| `tid` | Entra tenant ID — validate expected external tenant |

**Do not** put `organization_id` or permissions in Entra app roles alone without SafeCase membership verification — app roles may supplement but not replace membership checks.

---

## 4. App registration checklist

Create registrations per environment: **dev**, **staging**, **prod**.

### 4.1 SPA application (`safecase-web`)

| Setting | Value / action |
|---|---|
| **Name** | `SafeCase Web (dev|staging|prod)` |
| **Supported account types** | Accounts in this organizational directory only (external tenant) **or** per Entra External ID wizard for customer accounts |
| **Platform** | Single-page application |
| **Redirect URIs** | `https://localhost:3000/auth/callback` (dev), `https://{staging-host}/auth/callback`, `https://{prod-host}/auth/callback` |
| **Front-channel logout URL** | Optional — `/auth/logout` |
| **Implicit grant** | **Off** — use auth code + PKCE |
| **API permissions** | `openid`, `profile`, `email`, custom API scope (see below) |
| **Certificates & secrets** | **None for SPA** (public client) |

### 4.2 API application (`safecase-api`)

| Setting | Value / action |
|---|---|
| **Name** | `SafeCase API (dev|staging|prod)` |
| **Expose an API** | Application ID URI: `api://safecase-{env}` |
| **Scope** | `access_as_user` (user-delegated) |
| **Authorized client applications** | Link SPA client ID to scope |
| **App roles** | Optional platform-only roles — avoid duplicating org roles |
| **Authentication** | No redirect needed for API resource |

### 4.3 Token configuration

| Setting | Recommendation |
|---|---|
| Access token version | v2 |
| ID token optional claims | `email`, `preferred_username` |
| Access token lifetime | Default or org policy — balance UX vs security |

### 4.4 Post-registration documentation

Record in secure ops doc (not git):

- Tenant ID  
- SPA client ID  
- API client ID / application ID URI  
- Authority URL: `https://{tenant}.ciamlogin.com/{tenant-id}/v2.0` (External ID format — confirm in portal)  

---

## 5. API JWT validation (ASP.NET Core)

Implementation checklist:

- [ ] `Microsoft.Identity.Web` or manual JWT bearer middleware  
- [ ] Validate issuer matches External ID tenant  
- [ ] Validate audience = API application ID URI  
- [ ] Validate signing keys via OIDC metadata  
- [ ] Clock skew configured (≤ 5 min)  
- [ ] On success: resolve SafeCase User by `oid`  
- [ ] On missing/disabled membership: 403  
- [ ] Log authentication failures without token content  

**Never** trust org ID from unauthenticated query parameters.

---

## 6. Browser-delegated authentication

SafeCase uses **browser-delegated** OAuth 2.0 authorization code flow with PKCE:

| Property | Detail |
|---|---|
| Token storage | MSAL `sessionStorage` or memory — follow MSAL guidance; avoid localStorage for high-risk if policy requires |
| Refresh | MSAL silent token acquisition |
| Logout | MSAL logout redirect + clear org context |
| CSRF | PKCE + state parameter |

SPA **must not** use client secrets. All privileged operations go through the API with user-delegated token.

---

## 7. MFA guidance

| Environment | MFA policy |
|---|---|
| **Production pilot** | **Required** for all org users |
| **Staging** | Required for SafeCase staff; encouraged for org champions |
| **Development** | Required for shared dev tenant |

Configure via Entra **Conditional Access** (External ID):

- Require MFA for all users, or  
- Require MFA for SafeCase API scope authentication  

Document org exception process (none for pilot without exec + security approval).

**SafeCase does not implement TOTP/SMS itself** — MFA is Entra-hosted.

---

## 8. User invitation and provisioning

1. Org admin with `membership.invite` enters email + role in SafeCase.  
2. API creates `OrganizationInvitation` (token, expiry, role).  
3. Email sent with link to SPA onboarding (email provider TBD).  
4. User signs in with Entra (or registers if External ID self-service enabled — **policy decision**).  
5. API validates invitation token, creates User + Membership.  
6. Audit: `membership.created`.

**Self-service signup:** Default **off** for pilot — invite-only.

---

## 9. Account disablement

Disable access at **two layers**:

| Layer | Action | Effect |
|---|---|---|
| **Entra** | Block sign-in / disable user | Cannot obtain new tokens |
| **SafeCase** | `Membership.is_disabled = true` | API returns 403 even if token valid |

Procedures:

1. Org admin disables member in SafeCase UI → API disables membership (+ optional Entra guest disable via Graph — TBD).  
2. Compromised account → org admin + SafeCase security disable immediately.  
3. Platform Operator may disable membership for ToS violation — audit required.  
4. Re-enable requires org admin action + MFA verification.

Test disablement in staging before each pilot org go-live.

---

## 10. Multi-organization users

A single Entra identity may hold memberships in multiple SafeCase organizations (e.g., consultant, multi-site staff):

- `/me` returns all active memberships  
- User selects active org in UI  
- API validates membership on every request for selected org  
- Audit events include `organization_id`  

Cross-org data aggregation is **denied** unless Platform Operator tooling explicitly allows metadata-only views.

---

## 11. Local development without SafeCase passwords

**There are no SafeCase-native passwords.** Local dev options:

### Option A — Shared dev Entra tenant (recommended)

1. Use dev External ID tenant and dev app registrations.  
2. Developers sign in with `@yourcompany.onmicrosoft.com` test accounts.  
3. Seed script creates matching `User` + `Membership` rows for dev orgs.  
4. MSAL config in `safecase-web/.env.local` (gitignored):

```env
NEXT_PUBLIC_AZURE_CLIENT_ID=<dev-spa-client-id>
NEXT_PUBLIC_AZURE_AUTHORITY=https://<tenant>.ciamlogin.com/<tenant-id>
NEXT_PUBLIC_AZURE_API_SCOPE=api://safecase-dev/access_as_user
```

### Option B — API integration tests

- Use Testcontainers + test auth handler that injects synthetic `ClaimsPrincipal`  
- Authorization tests do not call live Entra  

### Option C — Stub auth (local only, never staging/prod)

- Development-only middleware accepting fixed bearer token  
- **Must compile out or hard-block in non-Development environments**  

### Prohibited

- Storing passwords in SafeCase database  
- Basic auth to production API  
- Shared personal Microsoft accounts for production tenants  
- Long-lived PAT tokens in frontend  

---

## 12. Platform Operator access

- Platform Operators authenticate via Entra like other users.  
- Elevated capabilities via SafeCase `platform.*` permissions, not global Entra admin for daily work.  
- Azure subscription RBAC separate from application roles.  
- Break-glass Azure Global Admin accounts stored offline per Microsoft guidance — not used for routine ops.

---

## 13. Audit and logging

| Event | Logged where |
|---|---|
| Sign-in success/failure | Entra sign-in logs + SafeCase audit |
| Token validation failure | API logs (no token body) |
| Membership created/disabled | SafeCase audit |
| Role changed | SafeCase audit |
| MFA registration changes | Entra logs |

Do not log access tokens, refresh tokens, or ID tokens.

---

## 14. Troubleshooting

| Symptom | Checks |
|---|---|
| `AADSTS50011` redirect URI mismatch | SPA redirect URIs in app registration |
| `401` from API | Audience/scope, clock skew, expired token |
| `403` with valid token | Missing membership, disabled user, wrong org |
| User not provisioned | Invitation expired or email mismatch |
| MFA loop | Conditional Access policy vs registered methods |

---

## 15. Security review checklist

- [ ] Separate app registrations per environment  
- [ ] No client secrets in SPA  
- [ ] PKCE enforced  
- [ ] Invite-only provisioning for pilot  
- [ ] MFA policy active for prod  
- [ ] Disablement tested end-to-end  
- [ ] JWT validation unit/integration tests  
- [ ] Graph API permissions minimal if used for guest disable  

---

## 16. Related documents

- [access-control-matrix.md](../access-control-matrix.md)  
- [security-acceptance-criteria.md](../security-acceptance-criteria.md) §4  
- [threat-model.md](../threat-model.md) §3.1  
- [pilot-operating-procedures.md](../pilot-operating-procedures.md)  
- `safecase-macos-prototype/docs/azure-conversion/02-CONVERSION-PLAN.md` §6  

---

## 17. Revision history

| Version | Date | Notes |
|---|---|---|
| 0.1 | 2026-08-01 | Initial draft for Phase 2 |
