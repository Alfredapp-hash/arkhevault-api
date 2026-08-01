# SafeCase Web — Pilot Application Shell

Next.js pilot shell for SafeCase, a victim services case management platform. This repository provides the authenticated app layout, navigation placeholders, Entra/MSAL auth configuration stubs, and a typed API client — ready for feature modules under `src/features/`.

## Prerequisites

- Node.js 20+
- [pnpm](https://pnpm.io/)

## Getting started

```bash
pnpm install
pnpm dev
```

Open [http://localhost:3000](http://localhost:3000) to view the dashboard shell.

### Production build

```bash
pnpm build
pnpm start
```

## Environment variables

Copy `.env.example` to `.env.local` and fill in values from your Microsoft Entra app registration:

```bash
cp .env.example .env.local
```

| Variable | Required | Description |
|----------|----------|-------------|
| `NEXT_PUBLIC_ENTRA_CLIENT_ID` | Yes (for auth) | Application (client) ID from Entra app registration |
| `NEXT_PUBLIC_ENTRA_TENANT_ID` | No | Directory (tenant) ID, or `organizations` / `common` (default: `organizations`) |
| `NEXT_PUBLIC_ENTRA_AUTHORITY` | No | Override authority URL (default: `https://login.microsoftonline.com/{tenant}`) |
| `NEXT_PUBLIC_ENTRA_REDIRECT_URI` | No | Post-login redirect (default: `http://localhost:3000`) |
| `NEXT_PUBLIC_ENTRA_POST_LOGOUT_REDIRECT_URI` | No | Post-logout redirect (defaults to redirect URI) |
| `NEXT_PUBLIC_ENTRA_SCOPES` | No | Space-separated scopes (default: `openid profile email`) |
| `NEXT_PUBLIC_API_BASE_URL` | No | Backend API base URL (default: `http://localhost:8080`) |

Never commit tenant IDs or secrets to source control. Use environment-specific `.env.local` files or your deployment platform's secret store.

## Project structure

```
src/
├── app/
│   ├── (app)/          # Authenticated shell (dashboard + module routes)
│   └── login/          # Entra login placeholder
├── components/shell/   # App shell, nav, org selector, branding
├── features/           # Future feature modules (clients, cases, …)
├── lib/
│   ├── api/            # API client + RFC7807 ProblemDetails handling
│   └── auth/           # Entra/MSAL env-based config
└── types/
```

## API client

`src/lib/api/client.ts` provides a fetch-based client that throws `ApiProblemError` with typed RFC 7807 `ProblemDetails` when the backend returns problem responses.

## End-to-end tests

Playwright smoke tests verify the shell loads and navigation placeholders render.

Install browsers (one-time):

```bash
npx playwright install
```

Run tests (builds the app and starts the server automatically):

```bash
pnpm build
pnpm test:e2e
```

## Auth (pilot)

The `/login` page documents Entra-hosted sign-in. MSAL integration is not yet wired — configure the environment variables above, then connect `@azure/msal-browser` using `src/lib/auth/config.ts` as the configuration source.
