"use client";

import Link from "next/link";
import { useCallback, useEffect, useState } from "react";
import { createClient, listClients } from "@/lib/api/casework";
import { useSession } from "@/lib/session/SessionProvider";
import type { Client } from "@/types/casework";
import { ApiProblemError } from "@/types/problem-details";

function formatClientName(client: Client): string {
  return `${client.firstName} ${client.lastName}`.trim();
}

export function ClientsPageContent() {
  const { selectedOrganizationId, loading: sessionLoading, error: sessionError } =
    useSession();
  const [clients, setClients] = useState<Client[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [firstName, setFirstName] = useState("");
  const [lastName, setLastName] = useState("");
  const [submitting, setSubmitting] = useState(false);

  const loadClients = useCallback(async () => {
    if (!selectedOrganizationId) {
      setClients([]);
      setLoading(false);
      return;
    }

    setLoading(true);
    setError(null);
    try {
      const data = await listClients(selectedOrganizationId);
      setClients(data);
    } catch (err) {
      setError(
        err instanceof ApiProblemError
          ? err.message
          : err instanceof Error
            ? err.message
            : "Unable to load clients",
      );
    } finally {
      setLoading(false);
    }
  }, [selectedOrganizationId]);

  useEffect(() => {
    if (!sessionLoading) {
      void loadClients();
    }
  }, [sessionLoading, loadClients]);

  async function handleCreate(event: React.FormEvent) {
    event.preventDefault();
    if (!selectedOrganizationId || !firstName.trim() || !lastName.trim()) {
      return;
    }

    setSubmitting(true);
    setError(null);
    try {
      const created = await createClient(selectedOrganizationId, {
        firstName: firstName.trim(),
        lastName: lastName.trim(),
      });
      setFirstName("");
      setLastName("");
      setClients((prev) => [created, ...prev]);
    } catch (err) {
      setError(
        err instanceof ApiProblemError
          ? err.message
          : err instanceof Error
            ? err.message
            : "Unable to create client",
      );
    } finally {
      setSubmitting(false);
    }
  }

  if (sessionLoading) {
    return <p className="status-message">Loading session…</p>;
  }

  if (sessionError) {
    return <p className="status-message status-message--error">{sessionError}</p>;
  }

  if (!selectedOrganizationId) {
    return (
      <p className="status-message">
        Select an organization to view and create clients.
      </p>
    );
  }

  return (
    <>
      {error ? <p className="status-message status-message--error">{error}</p> : null}

      <section className="module-section">
        <h2 className="module-section-title">Add client</h2>
        <form className="module-form" onSubmit={handleCreate}>
          <div className="form-row">
            <label className="form-field">
              <span className="form-label">First name</span>
              <input
                className="form-input"
                value={firstName}
                onChange={(e) => setFirstName(e.target.value)}
                required
              />
            </label>
            <label className="form-field">
              <span className="form-label">Last name</span>
              <input
                className="form-input"
                value={lastName}
                onChange={(e) => setLastName(e.target.value)}
                required
              />
            </label>
          </div>
          <div className="form-actions">
            <button
              className="btn-primary"
              type="submit"
              disabled={submitting}
            >
              {submitting ? "Creating…" : "Create client"}
            </button>
          </div>
        </form>
      </section>

      <section className="module-section">
        <h2 className="module-section-title">Clients</h2>
        {loading ? (
          <p className="status-message">Loading clients…</p>
        ) : clients.length === 0 ? (
          <p className="status-message">No clients yet.</p>
        ) : (
          <ul className="data-list">
            {clients.map((client) => (
              <li key={client.id} className="data-list-item">
                <Link className="data-list-link" href={`/clients/${client.id}`}>
                  <span className="data-list-primary">{formatClientName(client)}</span>
                  <span className="data-list-meta">
                    {client.status}
                    {client.riskLevel ? ` · ${client.riskLevel}` : ""}
                  </span>
                </Link>
              </li>
            ))}
          </ul>
        )}
      </section>
    </>
  );
}
