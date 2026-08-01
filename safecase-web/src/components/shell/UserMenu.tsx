"use client";

import Link from "next/link";

export function UserMenu() {
  return (
    <div className="user-menu">
      <div className="user-menu-identity">
        <span className="user-menu-name">Pilot User</span>
        <span className="user-menu-role">Case Manager</span>
      </div>
      <Link href="/login" className="user-menu-action">
        Sign in with Entra
      </Link>
    </div>
  );
}
