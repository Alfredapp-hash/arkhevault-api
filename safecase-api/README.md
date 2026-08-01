# SafeCase API

ASP.NET Core 10 Web API for the SafeCase Azure SaaS platform.

> Synthetic / development data only until Phase 8 pilot signoff.

## Solution layout

```text
src/
  SafeCase.Api/             HTTP host, health, Entra JWT hook
  SafeCase.Application/     Permissions and use-case services
  SafeCase.Domain/          Entities (orgs, users, clients, cases, audit)
  SafeCase.Infrastructure/  EF Core + PostgreSQL + tenant interceptor
  SafeCase.Workers/         Async processing (stub)
tests/
  SafeCase.UnitTests/
  SafeCase.IntegrationTests/
  SafeCase.AuthorizationTests/
  SafeCase.ArchitectureTests/
infrastructure/bicep/       Azure baseline
```

## Local development

Prerequisites: .NET 10 SDK, Docker (for Postgres).

```bash
docker compose up -d
dotnet restore SafeCase.sln
dotnet build SafeCase.sln
dotnet test SafeCase.sln --filter FullyQualifiedName~SafeCase.UnitTests
dotnet ef migrations add InitialCreate \
  --project src/SafeCase.Infrastructure \
  --startup-project src/SafeCase.Api \
  --output-dir Persistence/Migrations
dotnet ef database update \
  --project src/SafeCase.Infrastructure \
  --startup-project src/SafeCase.Api
dotnet run --project src/SafeCase.Api
```

- Liveness: `GET /health`
- Readiness (Postgres): `GET /health/ready`
- Session: `GET /api/v1/me` (provisions user)
- Organizations / memberships under `/api/v1/organizations...`
- Dev auth header (Development only): `X-Dev-User: dev-org-a-admin` plus optional `X-Organization-Id`

### Entra External ID

Set when ready (do not commit secrets):

```json
"Entra": {
  "TenantId": "<external-tenant-id>",
  "Audience": "api://safecase-api",
  "AuthorityHost": "<tenant>.ciamlogin.com"
}
```

Until Entra is configured, Development uses `Auth:UseDevAuth=true` with `X-Dev-User` headers. Never enable dev auth against real data.

## Infrastructure

See `infrastructure/bicep/`. Deploy example:

```bash
az group create -n rg-safecase-app-dev -l eastus
az deployment group create \
  -g rg-safecase-app-dev \
  -f infrastructure/bicep/main.bicep \
  -p environment=dev postgresAdminPassword='***'
```

GitHub Actions should use OIDC federated credentials — never long-lived Azure client secrets.

## Related docs

- `../docs/azure-conversion/` — conversion plan and audit
- `../safecase-governance/` — security/privacy drafts
- `docs/architecture/` — schema and RLS notes
