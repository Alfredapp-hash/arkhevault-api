"use client";

import Link from "next/link";
import { useSession } from "@/lib/session/SessionProvider";

export function UserMenu() {
  const { me, loading, isDevAuth } = useSession();

  const label = loading
    ? "Loading…"
    : (me?.displayName ?? me?.email ?? "Sign in");

  return (
    <div className="user-menu">
      <div className="user-menu-identity">
        <span className="user-menu-name">{label}</span>
        {isDevAuth ? (
          <span className="user-menu-meta">Dev auth</span>
        ) : (
          <span className="user-menu-meta">Entra</span>
        )}
      </div>
      <Link className="user-menu-link" href="/login">
        Account
      </Link>
    </div>
  );
}
