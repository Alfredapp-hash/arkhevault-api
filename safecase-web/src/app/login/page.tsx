import Link from "next/link";
import { BrandMark } from "@/components/shell/BrandMark";
import { getEntraAuthConfig } from "@/lib/auth/config";

export default function LoginPage() {
  const entra = getEntraAuthConfig();

  return (
    <div className="login-page">
      <div className="login-card">
        <BrandMark variant="hero" />

        <h1 className="login-title">Sign in to SafeCase</h1>
        <p className="login-lead">
          SafeCase uses Microsoft Entra ID (Azure AD) for organization-hosted
          sign-in via MSAL. Users authenticate through your tenant&apos;s login
          page — credentials are never handled by this application directly.
        </p>

        <div className="login-status">
          <span
            className={`login-status-badge${entra.isConfigured ? " login-status-badge--ready" : ""}`}
          >
            {entra.isConfigured ? "Entra configured" : "Entra not configured"}
          </span>
          {!entra.isConfigured && (
            <p className="login-status-hint">
              Set <code className="inline-code">NEXT_PUBLIC_ENTRA_CLIENT_ID</code>{" "}
              and related variables (see README) before wiring MSAL.
            </p>
          )}
        </div>

        <button
          type="button"
          className="login-button"
          disabled={!entra.isConfigured}
          title={
            entra.isConfigured
              ? "MSAL redirect will be wired in a future iteration"
              : "Configure Entra environment variables first"
          }
        >
          Continue with Microsoft Entra
        </button>

        <p className="login-footnote">
          Authority:{" "}
          <code className="inline-code">{entra.authority}</code>
        </p>

        <Link href="/" className="login-back">
          Return to dashboard shell
        </Link>
      </div>
    </div>
  );
}
