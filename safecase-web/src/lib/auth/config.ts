/**
 * Microsoft Entra ID (Azure AD) / MSAL configuration.
 * Values are read from environment variables — never hardcode tenant IDs.
 */

function required(name: string, value: string | undefined): string {
  if (!value) {
    throw new Error(
      `Missing required environment variable: ${name}. See README for Entra setup.`,
    );
  }
  return value;
}

function optional(value: string | undefined, fallback: string): string {
  return value?.trim() ? value.trim() : fallback;
}

export interface EntraAuthConfig {
  clientId: string;
  tenantId: string;
  authority: string;
  redirectUri: string;
  postLogoutRedirectUri: string;
  scopes: string[];
  /** True when all required vars are present for MSAL initialization */
  isConfigured: boolean;
}

function buildConfig(): EntraAuthConfig {
  const clientId = process.env.NEXT_PUBLIC_ENTRA_CLIENT_ID;
  const tenantId = optional(
    process.env.NEXT_PUBLIC_ENTRA_TENANT_ID,
    "organizations",
  );
  const authority = optional(
    process.env.NEXT_PUBLIC_ENTRA_AUTHORITY,
    `https://login.microsoftonline.com/${tenantId}`,
  );
  const redirectUri = optional(
    process.env.NEXT_PUBLIC_ENTRA_REDIRECT_URI,
    "http://localhost:3000",
  );
  const postLogoutRedirectUri = optional(
    process.env.NEXT_PUBLIC_ENTRA_POST_LOGOUT_REDIRECT_URI,
    redirectUri,
  );
  const scopesRaw = optional(
    process.env.NEXT_PUBLIC_ENTRA_SCOPES,
    "openid profile email",
  );

  const isConfigured = Boolean(clientId);

  return {
    clientId: clientId ?? "",
    tenantId,
    authority,
    redirectUri,
    postLogoutRedirectUri,
    scopes: scopesRaw.split(/\s+/).filter(Boolean),
    isConfigured,
  };
}

/** Server-safe config snapshot (may be partially empty in dev). */
export function getEntraAuthConfig(): EntraAuthConfig {
  return buildConfig();
}

/** Throws if MSAL cannot be initialized — use before wiring real auth. */
export function getRequiredEntraAuthConfig(): EntraAuthConfig {
  const config = buildConfig();
  return {
    ...config,
    clientId: required("NEXT_PUBLIC_ENTRA_CLIENT_ID", config.clientId),
  };
}
