"use client";

import type { Organization } from "@/types/auth";

const PLACEHOLDER_ORGS: Organization[] = [
  { id: "org-1", name: "North County Victim Services" },
  { id: "org-2", name: "Metro Family Justice Center" },
];

interface OrgSelectorProps {
  organizations?: Organization[];
  selectedOrgId?: string;
}

export function OrgSelector({
  organizations = PLACEHOLDER_ORGS,
  selectedOrgId = organizations[0]?.id,
}: OrgSelectorProps) {
  return (
    <label className="org-selector">
      <span className="org-selector-label">Organization</span>
      <select
        className="org-selector-control"
        defaultValue={selectedOrgId}
        aria-label="Select organization"
        disabled
        title="Organization switching will be enabled after Entra sign-in"
      >
        {organizations.map((org) => (
          <option key={org.id} value={org.id}>
            {org.name}
          </option>
        ))}
      </select>
    </label>
  );
}
