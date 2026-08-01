"use client";

import Link from "next/link";
import { useCallback, useEffect, useState } from "react";
import {
  createCase,
  getClient,
  listCasesForClient,
} from "@/lib/api/casework";
import { useSession } from "@/lib/session/SessionProvider";
import type { Case, Client } from "@/types/casework";
import { ApiProblemError } from "@/types/problem-details";

interface ClientDetailContentProps {
  clientId: string;
}

export function ClientDetailContent({ clientId }: ClientDetailContentProps) {
  const { selectedOrganizationId, loading: sessionLoading, error: sessionError } =
    useSession();
  const [client, setClient] = useState<Client | null>(null);
  const [cases, setCases] = useState<Case[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [caseTitle, setCaseTitle] = useState("");
  const [submitting, setSubmitting] = useState(false);

  const loadData = useCallback(async () => {
    if (!selectedOrganizationId) {
      setLoading(false);
      return;
    }

    setLoading(true);
    setError(null);
    try {
      const [clientData, casesData] = await Promise.all([
        getClient(selectedOrganizationId, clientId),
        listCasesForClient(selectedOrganizationId, clientId),
      ]);
      setClient(clientData);
      setCases(casesData);
    } catch (err) {
      setError(
        err instanceof ApiProblemError
          ? err.message
          : err instanceof Error
            ? err.message
            : "Unable to load client",
      );
    } finally {
      setLoading(false);
    }
  }, [selectedOrganizationId, clientId]);

  useEffect(() => {
    if (!sessionLoading) {
      void loadData();
    }
  }, [sessionLoading, loadData]);

  async function handleCreateCase(event: React.FormEvent) {
    event.preventDefault();
    if (!selectedOrganizationId) {
      return;
    }

    setSubmitting(true);
    setError(null);
    try {
      const created = await createCase(selectedOrganizationId, clientId, {
        title: caseTitle.trim() || undefined,
      });
      setCaseTitle("");
      setCases((prev) => [created, ...prev]);
    } catch (err) {
      setError(
        err instanceof ApiProblemError
          ? err.message
          : err instanceof Error
            ? err.message
            : "Unable to create case",
      );
    } finally {
      setSubmitting(false);
    }
  }

  if (sessionLoading || loading) {
    return <p className="status-message">Loading…</p>;
  }

  if (sessionError) {
    return <p className="status-message status-message--error">{sessionError}</p>;
  }

  if (!selectedOrganizationId) {
    return (
      <p className="status-message">Select an organization to view this client.</p>
    );
  }

  if (!client) {
    return <p className="status-message status-message--error">{error ?? "Client not found."}</p>;
  }

  return (
    <>
      <p className="page-lead">
        <Link className="text-link" href="/clients">
          ← Back to clients
        </Link>
      </p>

      {error ? <p className="status-message status-message--error">{error}</p> : null}

      <section className="module-section">
        <h2 className="module-section-title">Client</h2>
        <dl className="detail-list">
          <div className="detail-row">
            <dt>Name</dt>
            <dd>
              {client.firstName} {client.lastName}
            </dd>
          </div>
          <div className="detail-row">
            <dt>Status</dt>
            <dd>{client.status}</dd>
          </div>
          {client.riskLevel ? (
            <div className="detail-row">
              <dt>Risk level</dt>
              <dd>{client.riskLevel}</dd>
            </div>
          ) : null}
        </dl>
      </section>

      <section className="module-section">
        <h2 className="module-section-title">Open case</h2>
        <form className="module-form" onSubmit={handleCreateCase}>
          <label className="form-field">
            <span className="form-label">Case title (optional)</span>
            <input
              className="form-input"
              value={caseTitle}
              onChange={(e) => setCaseTitle(e.target.value)}
              placeholder="Intake follow-up"
            />
          </label>
          <div className="form-actions">
            <button className="btn-primary" type="submit" disabled={submitting}>
              {submitting ? "Creating…" : "Create case"}
            </button>
          </div>
        </form>
      </section>

      <section className="module-section">
        <h2 className="module-section-title">Cases</h2>
        {cases.length === 0 ? (
          <p className="status-message">No cases for this client yet.</p>
        ) : (
          <ul className="data-list">
            {cases.map((caseItem) => (
              <li key={caseItem.id} className="data-list-item">
                <Link className="data-list-link" href={`/cases/${caseItem.id}`}>
                  <span className="data-list-primary">
                    {caseItem.title ?? "Untitled case"}
                  </span>
                  <span className="data-list-meta">{caseItem.status}</span>
                </Link>
              </li>
            ))}
          </ul>
        )}
      </section>
    </>
  );
}
