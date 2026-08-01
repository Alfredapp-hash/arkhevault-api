# ADR-002: ASP.NET Core 10 on Azure

**Status:** Accepted

## Decision

Implement the SafeCase API in ASP.NET Core 10 with EF Core and PostgreSQL, rejecting the earlier Node/Express AWS plan for the Azure production path.

## Consequences

- Strong fit for Entra, policy authz, OpenTelemetry, enterprise hosting
- Team must maintain .NET skills alongside Next.js frontend
