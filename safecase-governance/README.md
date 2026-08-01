# SafeCase Governance Documentation

> **Status:** DRAFT / PENDING LEGAL REVIEW  
> **Version:** 0.1  
> **Last updated:** 2026-08-01  
> **Owner:** SafeCase Security & Privacy (interim engineering-led)

This repository holds security, privacy, and pilot-operating documentation for SafeCase — a victim-services multi-tenant SaaS platform converting from a macOS prototype to Azure (Microsoft Entra External ID, ASP.NET Core API, PostgreSQL with row-level security, Azure Blob Storage, Azure Key Vault).

**These documents are not legal advice.** They are engineering and operations drafts intended for counsel, compliance, and pilot organization review before production pilot signoff (Phase 8).

---

## Purpose

SafeCase handles sensitive survivor and client information. Governance docs define:

- How data is classified and protected (Levels 0–4)
- Who may perform which actions (roles × permissions)
- What must be true before pilot use ("Azure-compatible" / pilot-ready)
- How pilot organizations operate before real client data is permitted
- Threat assumptions, retention, incident response, onboarding, and privacy impact

Until Phase 8 hardening is complete and written approval is obtained, **only synthetic data** may be used in any SafeCase environment.

---

## Document index

| Document | Description | Primary audience |
|---|---|---|
| [REPO_MAP.md](./REPO_MAP.md) | Relationship among SafeCase repositories | Engineering, product |
| [data-classification.md](./data-classification.md) | Levels 0–4, SafeCase examples, L4 controls, analytics/AI ban | Engineering, ops, counsel |
| [access-control-matrix.md](./access-control-matrix.md) | Roles × permissions for Phase 2–4 features | Engineering, security, org admins |
| [security-acceptance-criteria.md](./security-acceptance-criteria.md) | Pilot-ready checklist (Azure-compatible definition) | Engineering, security, pilot leads |
| [pilot-operating-procedures.md](./pilot-operating-procedures.md) | Synthetic-data rules, escalation, Phase 8 gate | Pilot orgs, support, ops |
| [threat-model.md](./threat-model.md) | STRIDE v0 against core platform components | Security, engineering |
| [retention-policy.md](./retention-policy.md) | Operational, client, audit, and document retention outline | Ops, counsel, org admins |
| [incident-response.md](./incident-response.md) | Roles, severity, notification outline | Security, ops, pilot orgs |
| [organization-onboarding.md](./organization-onboarding.md) | Pilot organization checklist | Customer success, org owners |
| [privacy-impact-assessment.md](./privacy-impact-assessment.md) | PIA outline for victim-services SaaS | Privacy, counsel, product |
| [identity/entra-external-id-runbook.md](./identity/entra-external-id-runbook.md) | Entra External ID setup, OID mapping, MFA, local dev | Identity, backend, frontend |

---

## Related authoritative sources

| Source | Location |
|---|---|
| Azure conversion plan | `safecase-macos-prototype/docs/azure-conversion/02-CONVERSION-PLAN.md` |
| Fresh security audit | `safecase-macos-prototype/docs/azure-conversion/01-FRESH-AUDIT.md` |
| Domain mapping | `safecase-macos-prototype/docs/azure-conversion/04-DOMAIN-MAPPING.md` |

---

## Review and signoff checklist

The following require explicit review before treating any document as binding:

- [ ] **Legal counsel** — privacy, contracts, breach notification, retention
- [ ] **Compliance / risk** — victim-services sector requirements, grant/funder terms
- [ ] **Pilot organization representatives** — operational feasibility, escalation paths
- [ ] **SafeCase Platform Operator** — technical enforceability in API, RLS, and Entra
- [ ] **Phase 8 security signoff** — pen test, DR exercise, threat model, PIA completion

---

## Change control

1. Open a pull request in `safecase-governance` with rationale and affected phases.
2. Tag `@safecase-security` (or interim owner) for review.
3. Do not deploy policy changes to production without matching API/RLS enforcement.
4. Version significant changes in document headers; link to ADRs in `safecase-api` when behavior changes.

---

## Contact (placeholder)

Define before pilot:

- **Security incidents:** `security@safecase.org` (TBD)
- **Privacy / DPA questions:** `privacy@safecase.org` (TBD)
- **Pilot support:** `pilot@safecase.org` (TBD)
