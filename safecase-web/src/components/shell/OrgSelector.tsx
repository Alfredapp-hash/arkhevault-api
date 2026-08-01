"use client";

import { useSession } from "@/lib/session/SessionProvider";

export function OrgSelector() {
  const { me, loading, selectedOrganizationId, setSelectedOrganizationId, error } =
    useSession();

  const organizations = (me?.memberships ?? [])
    .filter((m) => m.isActive)
    .map((m) => ({
      id: m.organizationId,
      name: m.organizationName,
    }));

  if (loading) {
    return (
      <label className="org-selector">
        <span className="org-selector-label">Organization</span>
        <select className="org-selector-control" disabled aria-label="Select organization">
          <option>Loading…</option>
        </select>
      </label>
    );
  }

  if (error || organizations.length === 0) {
    return (
      <label className="org-selector">
        <span className="org-selector-label">Organization</span>
        <select
          className="org-selector-control"
          disabled
          aria-label="Select organization"
          title={error ?? "No organization memberships"}
        >
          <option>{error ? "API unavailable" : "No organizations"}</option>
        </select>
      </label>
    );
  }

  return (
    <label className="org-selector">
      <span className="org-selector-label">Organization</span>
      <select
        className="org-selector-control"
        value={selectedOrganizationId ?? organizations[0]?.id}
        aria-label="Select organization"
        onChange={(event) => setSelectedOrganizationId(event.target.value)}
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
