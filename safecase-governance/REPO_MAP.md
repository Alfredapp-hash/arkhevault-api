# SafeCase Repository Map

> **Note:** Until GitHub repository splits, these projects live as folders in the current monorepo (`safecase-api/`, `safecase-web/`, `safecase-governance/`, with the Swift prototype at repo root).

> **Status:** DRAFT / PENDING LEGAL REVIEW  
> **Version:** 0.1  
> **Last updated:** 2026-08-01

This document explains how the four SafeCase repositories relate during the Azure conversion. It is a navigation aid for engineers, security reviewers, and pilot stakeholders.

---

## Overview

```text
┌─────────────────────────────────────────────────────────────────┐
│                     SafeCase product surface                     │
├─────────────────┬─────────────────┬─────────────────────────────┤
│ safecase-web    │ safecase-api    │ safecase-macos-prototype    │
│ (Next.js pilot  │ (ASP.NET Core   │ (SwiftUI + Core Data        │
│  UI, MSAL)      │  API, Bicep)    │  workflow reference)        │
└────────┬────────┴────────┬────────┴──────────────┬──────────────┘
         │                 │                        │
         │    OIDC/JWT     │                        │ (no prod auth)
         └────────────────►│◄───────────────────────┘
                           │
         ┌─────────────────┼─────────────────┐
         ▼                 ▼                 ▼
   Entra External ID   PostgreSQL+RLS    Blob / Key Vault
                           │
                           ▼
              safecase-governance (this repo)
              policies, threat model, pilot ops, PIA
```

**Rule:** The API is authoritative for identity resolution, authorization, business rules, audit, and data. Clients display and request; they do not decide access.

---

## Repository roles

### `safecase-macos-prototype`

| Attribute | Detail |
|---|---|
| **Current location** | Repository root at `/workspace` (rename target: `safecase-macos-prototype`) |
| **Stack** | SwiftUI, Core Data, local macOS app |
| **Purpose** | Preserve workflow and UX concepts from the original Forged In Fire / Arkhe Vault prototype |
| **Authority** | **None** for production data, auth, or multi-tenant isolation |
| **Data** | Synthetic only; real survivor/client data prohibited |
| **Future** | Optional approved desktop client **after** API is pilot-ready |

**Contains:** Feature screens (clients, intake, safety, referrals, reports), Core Data schema as domain reference, superseded AWS/Node planning docs, Azure conversion package under `docs/azure-conversion/`.

**Does not contain:** Entra integration, PostgreSQL, server-side RLS, authoritative audit, or pilot-ready security controls.

---

### `safecase-api`

| Attribute | Detail |
|---|---|
| **Purpose** | Production SafeCase backend — ASP.NET Core 10 Web API, workers, infrastructure |
| **Stack** | C#, EF Core, PostgreSQL, Azure App Service, Bicep, xUnit + Testcontainers |
| **Authority** | **Source of truth** for users (linked to Entra OID), memberships, roles, permissions, clients, cases, audit |
| **Enforcement** | JWT validation, permission checks, tenant query filters, PostgreSQL RLS (`app.current_organization_id`) |
| **Related docs** | OpenAPI spec, ADRs, authorization tests, Bicep modules |

**Typical layout:**

```text
safecase-api/
├── src/SafeCase.{Api,Application,Domain,Infrastructure,Workers}/
├── tests/{Unit,Integration,Authorization,Architecture}Tests/
├── infrastructure/bicep/
└── docs/
```

Governance docs here describe **what** must be enforced; `safecase-api` implements **how**.

---

### `safecase-web`

| Attribute | Detail |
|---|---|
| **Purpose** | Browser-based pilot application for victim-services staff |
| **Stack** | Next.js, TypeScript, React, Tailwind, shadcn/ui, MSAL, Playwright |
| **Authority** | **None** — UI only; all mutations and reads go through the API |
| **Auth** | Browser-delegated OIDC via Entra External ID; no SafeCase-stored passwords |
| **Related docs** | Feature maps from SwiftUI screens, accessibility baseline, E2E tests |

The web app is the primary pilot surface for Phases 4–8. It must not cache authoritative client records offline beyond approved patterns (see governance retention and pilot procedures).

---

### `safecase-governance`

| Attribute | Detail |
|---|---|
| **Purpose** | Security, privacy, and pilot-operating documentation |
| **Stack** | Markdown only (no runtime) |
| **Authority** | Defines policies and acceptance criteria; **does not enforce** them |
| **Audience** | Legal, compliance, pilot orgs, platform operators, engineers |

**Contains:** Data classification, access matrix, threat model, PIA outline, incident response, onboarding checklists, Entra runbook.

Changes in governance should drive corresponding tests and implementation in `safecase-api` and configuration in Entra/Azure.

---

## Data and trust boundaries

| Boundary | Trusted side | Untrusted / client side |
|---|---|---|
| Browser ↔ Entra | Entra-hosted login, MFA | SPA holds tokens in memory/session per MSAL guidance |
| Browser ↔ API | API validates JWT, org context, permissions | Web must not bypass API for data access |
| API ↔ PostgreSQL | RLS + app filters enforce `organization_id` | Direct DB access is ops-only, not for app users |
| API ↔ Blob | Short-lived SAS or user-delegated download after authz | Blob URLs must not be long-lived or cross-tenant |
| Prototype app | Local synthetic demo only | Must not connect to pilot/production API with real tokens |

---

## Phase alignment

| Phase | Primary repos | Governance touchpoints |
|---|---|---|
| 0 — Freeze | macOS prototype rename, bootstrap api/web/governance | This repo created; synthetic-data rules |
| 1 — Azure foundation | safecase-api (Bicep) | Security acceptance criteria (infra section) |
| 2 — Identity & orgs | safecase-api, safecase-web, Entra | Access matrix, Entra runbook |
| 3 — Core data platform | safecase-api | Data classification, RLS tenant tests |
| 4 — First web workflow | safecase-web + api | Pilot procedures, acceptance criteria |
| 5–7 — Safety, docs, reports | api + web | L4 controls, retention, expanded matrix |
| 8 — Pilot hardening | All + governance signoff | PIA, IR, pen test, onboarding, **real data gate** |

---

## Where to start

| If you are… | Start in… |
|---|---|
| Understanding UX/workflows from the prototype | `safecase-macos-prototype/Features/` |
| Implementing auth or permissions | `safecase-governance/identity/`, `access-control-matrix.md`, `safecase-api` |
| Building pilot UI | `safecase-web`, conversion plan §14 web map |
| Reviewing pilot readiness | `security-acceptance-criteria.md`, `pilot-operating-procedures.md` |
| Onboarding a pilot org | `organization-onboarding.md` |

---

## Naming note

The macOS prototype may still appear under legacy names (`ForgedInFireClientManager`, Arkhe Vault) in paths and Xcode project files until Phase 0 rename is complete. Treat **`SafeCase`** as the product name and **`safecase-macos-prototype`** as the target repository name throughout new work.
