"use client";

import Link from "next/link";
import { useState } from "react";
import { runVerticalSlice } from "@/lib/api/casework";
import { setLastCaseId } from "@/lib/session/lastCase";
import { useSession } from "@/lib/session/SessionProvider";
import { ApiProblemError } from "@/types/problem-details";

function syntheticName(): { firstName: string; lastName: string } {
  const suffix = Math.random().toString(36).slice(2, 7);
  return {
    firstName: "Pilot",
    lastName: `Client-${suffix}`,
  };
}

export function VerticalSliceButton() {
  const { selectedOrganizationId, loading: sessionLoading } = useSession();
  const [running, setRunning] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [caseId, setCaseId] = useState<string | null>(null);
  const [clientName, setClientName] = useState<string | null>(null);

  async function handleRun() {
    if (!selectedOrganizationId) {
      return;
    }

    setRunning(true);
    setError(null);
    setCaseId(null);
    setClientName(null);

    const { firstName, lastName } = syntheticName();

    try {
      const result = await runVerticalSlice(selectedOrganizationId, {
        firstName,
        lastName,
        riskLevel: "moderate",
        openInitialCase: true,
        caseTitle: "Pilot intake",
      });
      setLastCaseId(result.case.id);
      setCaseId(result.case.id);
      setClientName(`${result.client.firstName} ${result.client.lastName}`);
    } catch (err) {
      setError(
        err instanceof ApiProblemError
          ? err.message
          : err instanceof Error
            ? err.message
            : "Vertical slice failed",
      );
    } finally {
      setRunning(false);
    }
  }

  if (sessionLoading) {
    return null;
  }

  return (
    <div className="dashboard-action">
      <p className="dashboard-focus-text">
        Run the end-to-end pilot workflow: create a client, open a case, assign
        yourself, add a note and task, and populate the timeline.
      </p>
      <div className="form-actions">
        <button
          className="btn-primary"
          type="button"
          onClick={() => void handleRun()}
          disabled={running || !selectedOrganizationId}
        >
          {running ? "Running…" : "Run vertical slice"}
        </button>
      </div>
      {error ? (
        <p className="status-message status-message--error">{error}</p>
      ) : null}
      {caseId ? (
        <p className="status-message status-message--success">
          Created {clientName}.{" "}
          <Link className="text-link" href={`/cases/${caseId}`}>
            Open case →
          </Link>
        </p>
      ) : null}
    </div>
  );
}
