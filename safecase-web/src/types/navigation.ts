import type { SafeCaseRole } from "./auth";

export interface NavItem {
  label: string;
  href: string;
  /** Roles that can see this item. Empty means all authenticated users. */
  roles?: SafeCaseRole[];
}

export const NAV_ITEMS: NavItem[] = [
  { label: "Dashboard", href: "/" },
  {
    label: "Clients",
    href: "/clients",
    roles: ["admin", "case_manager", "advocate"],
  },
  {
    label: "Cases",
    href: "/cases",
    roles: ["admin", "case_manager", "advocate", "viewer"],
  },
  {
    label: "Tasks",
    href: "/tasks",
    roles: ["admin", "case_manager", "advocate"],
  },
  {
    label: "Timeline",
    href: "/timeline",
    roles: ["admin", "case_manager", "advocate", "viewer"],
  },
  { label: "Settings", href: "/settings", roles: ["admin"] },
];
