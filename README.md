# Arkhe Vault

**Protecting Data. Empowering Missions.**

Arkhe Vault is a native macOS client and case management platform built for nonprofit and trauma-informed organizations — domestic violence shelters, safe housing programs, victim advocacy, and similar missions.

Built by **Arkhe Holdings**.

## Features

- Client 360 profiles with notes, documents, timeline, and program enrollment
- Safety management and risk assessment
- Task queues, calendar, referrals, and volunteer coordination
- Safe house placement tracking
- Grant reporting and analytics dashboards
- Document extraction (Vision OCR) with field learning
- Offline mode scaffolding and AI assistance (Claude API)
- Security: Keychain, biometrics, session timeout, rate limiting, security event logging

## Requirements

- macOS 13.0+
- Xcode 15+
- Swift 5.9+

## Getting Started

1. Clone the repository and open the project:

```bash
open ArkheVault.xcodeproj
```

2. Set environment variables for development (Xcode scheme → Edit Scheme → Run → Arguments → Environment Variables):

| Variable | Description |
|----------|-------------|
| `CLAUDE_API_KEY` | Claude API key for AI features |
| `APP_ENV` | `development`, `staging`, or `production` |
| `RATE_LIMITING_ENABLED` | `true` / `false` |

3. Build and run the `ArkheVault` scheme (⌘R).

## Project Structure

```
App/           Entry point, login, main window shell
Core/          Core Data stack, authentication, AI, security services
Features/      Feature modules (Dashboard, Clients, Safety, Tasks, etc.)
Shared/        Reusable UI components and branding
Tests/         Unit and UI test targets
```

## Running Tests

```bash
./Tests/test_runner.sh
```

Or in Xcode: Product → Test (⌘U).

## Regenerating the Xcode Project

If you add new Swift files, regenerate `project.pbxproj`:

```bash
python3 scripts/generate_xcode_project.py
```

## Documentation

Additional guides are in the repository root:

- `DEPLOYMENT_GUIDE.md` — build, archive, and App Store submission
- `CODE_SIGNING_GUIDE.md` — signing and notarization
- `MASTER_UPGRADE_ROADMAP.md` — SaaS/multi-tenant roadmap
- `LOGO_ASSET_GUIDE.md` — branding assets setup
- `CORE_DATA_MIGRATION_GUIDE.md` — schema migrations

## License

Proprietary — Arkhe Holdings. All rights reserved.
