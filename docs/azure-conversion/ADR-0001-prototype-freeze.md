# ADR-0001: Freeze macOS prototype; rebuild on Azure

**Status:** Accepted  
**Date:** 2026-08-01  

## Context

SafeCase currently exists as a SwiftUI macOS app with local Core Data, local authentication, and client-side optional AI calls. Stakeholders need a multi-organization victim-services SaaS on Azure with Entra External ID, centralized authorization, PostgreSQL RLS, Blob documents, and server-authoritative audit.

Azure cannot host the existing desktop app as that SaaS system.

## Decision

1. Treat this repository as a **design/workflow prototype** only (`safecase-macos-prototype`).  
2. Prohibit real survivor/client PII in this repository’s runtime data stores.  
3. Build production capabilities in new repositories: `safecase-api`, `safecase-web`, `safecase-governance`.  
4. Supersede AWS/Node/JWT planning docs and prior “cleared for live testing” conclusions.  
5. Deliver value through a vertical slice on Azure before broad feature parity.

## Consequences

- Faster clarity for agents and humans about where new code belongs  
- Short-term duplication of UI concepts while web catches up  
- Mac app may later become an optional API client, never the source of truth  
- Requires discipline not to keep shipping “security features” into the prototype  

## Alternatives rejected

- Upload/wrap the Mac app as the SaaS product  
- Continue AWS/Node plan from `UPGRADE_PASS_2_SAAS_INFRASTRUCTURE.md`  
- Add Azure SDKs directly into the Swift monolith as primary architecture  
