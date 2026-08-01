"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import type { SafeCaseRole } from "@/types/auth";
import { NAV_ITEMS } from "@/types/navigation";

interface AppNavProps {
  /** Placeholder role until MSAL session is wired */
  currentRole?: SafeCaseRole;
}

function isActive(href: string, pathname: string): boolean {
  if (href === "/") return pathname === "/";
  return pathname === href || pathname.startsWith(`${href}/`);
}

function canAccess(roles: SafeCaseRole[] | undefined, currentRole: SafeCaseRole) {
  if (!roles || roles.length === 0) return true;
  return roles.includes(currentRole);
}

export function AppNav({ currentRole = "case_manager" }: AppNavProps) {
  const pathname = usePathname();
  const visibleItems = NAV_ITEMS.filter((item) =>
    canAccess(item.roles, currentRole),
  );

  return (
    <nav className="app-nav" aria-label="Main">
      <ul className="app-nav-list">
        {visibleItems.map((item) => {
          const active = isActive(item.href, pathname);
          return (
            <li key={item.href}>
              <Link
                href={item.href}
                className={`app-nav-link${active ? " app-nav-link--active" : ""}`}
                aria-current={active ? "page" : undefined}
              >
                {item.label}
              </Link>
            </li>
          );
        })}
      </ul>
    </nav>
  );
}
