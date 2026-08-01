"use client";

import Link from "next/link";
import { useCallback, useEffect, useState } from "react";
import { getCase, getTimeline } from "@/lib/api/casework";
import { getLastCaseId } from "@/lib/session/lastCase";
import { useSession } from "@/lib/session/SessionProvider";
import type { Case, TimelineEvent } from "@/types/casework";
import { ApiProblemError } from "@/types/problem-details";

function formatDate(value: string): string {
  return new Date(value).toLocaleString(undefined, {
    dateStyle: "medium",
    timeStyle: "short",
  });
}

export function TimelinePageContent() {
  const { selectedOrganizationId, loading: sessionLoading, error: sessionError } =
    useSession();
  const [lastCaseId, setLastCaseIdState] = useState<string | null>(null);
  const [caseRecord, setCaseRecord] = useState<Case | null>(null);
  const [timeline, setTimeline] = useState<TimelineEvent[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    setLastCaseIdState(getLastCaseId());
  }, []);

  const loadTimeline = useCallback(async (caseId: string) => {
    if (!selectedOrganizationId) {
      return;
    }

    setLoading(true);
    setError(null);
    try {
      const [caseData, timelineData] = await Promise.all([
        getCase(selectedOrganizationId, caseId),
        getTimeline(selectedOrganizationId, caseId),
      ]);
      setCaseRecord(caseData);
      setTimeline(timelineData);
    } catch (err) {
      setCaseRecord(null);
      setTimeline([]);
      setError(
        err instanceof ApiProblemError
          ? err.message
          : err instanceof Error
            ? err.message
            : "Unable to load timeline",
      );
    } finally {
      setLoading(false);
    }
  }, [selectedOrganizationId]);

  useEffect(() => {
    if (!sessionLoading && lastCaseId && selectedOrganizationId) {
      void loadTimeline(lastCaseId);
    }
  }, [sessionLoading, lastCaseId, selectedOrganizationId, loadTimeline]);

  if (sessionLoading) {
    return <p className="status-message">Loading session…</p>;
  }

  if (sessionError) {
    return <p className="status-message status-message--error">{sessionError}</p>;
  }

  if (!lastCaseId) {
    return (
      <section className="module-section">
        <p className="module-section-lead">
          Open a case from{" "}
          <Link className="text-link" href="/clients">
            Clients
          </Link>{" "}
          or run the vertical slice from the{" "}
          <Link className="text-link" href="/">
            Dashboard
          </Link>
          . The most recently opened case will appear here automatically.
        </p>
      </section>
    );
  }

  return (
    <>
      <p className="page-lead">
        Showing timeline for the last case you opened.{" "}
        <Link className="text-link" href={`/cases/${lastCaseId}`}>
          Open case detail →
        </Link>
      </p>

      {error ? <p className="status-message status-message--error">{error}</p> : null}

      {loading ? (
        <p className="status-message">Loading timeline…</p>
      ) : caseRecord ? (
        <section className="module-section">
          <h2 className="module-section-title">
            {caseRecord.title ?? "Untitled case"}
          </h2>
          {timeline.length === 0 ? (
            <p className="status-message">No timeline events yet.</p>
          ) : (
            <ul className="timeline-list">
              {timeline.map((event) => (
                <li key={event.id} className="timeline-item">
                  <time className="timeline-time" dateTime={event.createdAt}>
                    {formatDate(event.createdAt)}
                  </time>
                  <span className="timeline-type">{event.eventType}</span>
                  <p className="timeline-summary">{event.summary}</p>
                </li>
              ))}
            </ul>
          )}
        </section>
      ) : null}
    </>
  );
}
