/**
 * Builds request headers for authenticated API calls using dev auth and org context.
 */
export function buildSessionHeaders(
  organizationId: string | null,
): Record<string, string> {
  const headers: Record<string, string> = {};

  if (process.env.NEXT_PUBLIC_USE_DEV_AUTH !== "false") {
    headers["X-Dev-User"] =
      process.env.NEXT_PUBLIC_DEV_USER ?? "dev-org-a-admin";
    headers["X-Dev-Email"] =
      process.env.NEXT_PUBLIC_DEV_EMAIL ?? "admin.a@safecase.local";
    headers["X-Dev-Name"] =
      process.env.NEXT_PUBLIC_DEV_NAME ?? "Org A Administrator";
  }

  if (organizationId) {
    headers["X-Organization-Id"] = organizationId;
  }

  return headers;
}
