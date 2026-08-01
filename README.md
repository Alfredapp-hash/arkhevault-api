# SafeCase macOS Prototype

> **Prototype Status**  
> This repository is a **design and workflow prototype**.  
> It is **not approved** for real survivor, victim, health, legal, confidential, or personally identifying information.  
> Use synthetic data only.

Formerly known as Forged In Fire Client Manager / Arkhe Vault. This codebase preserves SwiftUI screens, Core Data domain concepts, and operational workflows as a reference for the Azure SaaS rebuild.

## What this repository is

- A **macOS SwiftUI prototype** for victim-services case management workflows
- A **feature discovery** and UX reference for the SafeCase web application
- A **local Core Data** schema that informs the PostgreSQL domain model

## What this repository is not

- Not a multi-tenant SaaS system
- Not Azure-compatible production software
- Not an authoritative source of client records
- Not approved for live organization data

## Azure conversion

The authoritative conversion plan lives in:

- [`docs/azure-conversion/`](docs/azure-conversion/)

Target architecture:

```text
Browser / approved client
        │  OpenID Connect
        ▼
Microsoft Entra External ID
        │  Access token
        ▼
SafeCase API (ASP.NET Core on Azure App Service)
        │
        ├── Azure Database for PostgreSQL (RLS)
        ├── Azure Blob Storage
        ├── Azure Key Vault
        ├── Azure Monitor / Application Insights
        ├── Azure Service Bus
        └── Azure Functions
```

Planned sibling repositories:

| Repository | Purpose |
|---|---|
| `safecase-macos-prototype` | This repo (rename target) |
| `safecase-api` | ASP.NET Core 10 API + Bicep + tests |
| `safecase-web` | Next.js pilot web application |
| `safecase-governance` | Security, privacy, and pilot operating docs |

## Important supersession notice

Older planning documents in this repository describe an AWS / Node.js / custom JWT path (`UPGRADE_PASS_2_SAAS_INFRASTRUCTURE.md`, parts of `MASTER_UPGRADE_ROADMAP.md`, `EXECUTION_CHECKLIST_ORDERED.md`). Those plans are **superseded** by the Azure conversion package under `docs/azure-conversion/`.

Security claims in `SECURITY_AUDIT_REPORT.md` and production-readiness claims in `PROGRESS_AUDIT.md` / `IMPLEMENTATION_SUMMARY.md` are **not accurate** for a multi-organization SaaS product. See the fresh audit for current findings.

## Local development (prototype only)

This is a SwiftUI macOS project. Do not connect it to production identities, provider keys used for real casework, or any real client data.

## License / use

Internal prototype reference. Treat all sample content as fictional.
