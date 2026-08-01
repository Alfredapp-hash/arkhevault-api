# SafeCase

> **Prototype + conversion workspace**  
> The macOS SwiftUI app in this repository is a **design and workflow prototype**.  
> It is **not approved** for real survivor, victim, health, legal, confidential, or personally identifying information.  
> Use synthetic data only.

## Layout

| Path | Role |
|---|---|
| `App/`, `Core/`, `Features/`, `Shared/`, `Tests/` | macOS SwiftUI prototype (reference) |
| `docs/azure-conversion/` | Authoritative Azure conversion audit, plan, agent prompts |
| `safecase-api/` | ASP.NET Core 10 API + EF Core + Bicep (Milestone 1 scaffold) |
| `safecase-web/` | Next.js pilot application shell |
| `safecase-governance/` | Draft security/privacy/pilot operating docs |
| `docs/STATUS.md` | Honest completion status |

These folders are the conversion plan’s sibling repositories, scaffolded in-tree so delivery can start before GitHub repo splits.

## Target architecture

```text
Browser (safecase-web)
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

## Quick start (scaffolds)

### API

```bash
cd safecase-api
# docker compose up -d   # when Docker is available
dotnet restore SafeCase.sln
dotnet build SafeCase.sln
dotnet test SafeCase.sln --filter "FullyQualifiedName~UnitTests|FullyQualifiedName~ArchitectureTests"
dotnet run --project src/SafeCase.Api
```

### Web

```bash
cd safecase-web
pnpm install
pnpm dev
```

## Conversion docs

Start here: [`docs/azure-conversion/README.md`](docs/azure-conversion/README.md)

Parallel agent prompts: [`docs/azure-conversion/03-PARALLEL-AGENT-PROMPTS.md`](docs/azure-conversion/03-PARALLEL-AGENT-PROMPTS.md)

## Supersession

Older AWS/Node plans and “cleared for live testing” claims in root markdown files are **superseded** by `docs/azure-conversion/`.
