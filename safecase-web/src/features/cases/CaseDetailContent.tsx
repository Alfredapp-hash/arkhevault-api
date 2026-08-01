"use client";

import Link from "next/link";
import { useCallback, useEffect, useState } from "react";
import {
  createAssignment,
  createNote,
  createTask,
  getCase,
  getTimeline,
  listNotes,
  listTasks,
} from "@/lib/api/casework";
import { setLastCaseId } from "@/lib/session/lastCase";
import { useSession } from "@/lib/session/SessionProvider";
import type { Case, CaseNote, CaseTask, TimelineEvent } from "@/types/casework";
import { ApiProblemError } from "@/types/problem-details";

interface CaseDetailContentProps {
  caseId: string;
}

function formatDate(value: string): string {
  return new Date(value).toLocaleString(undefined, {
    dateStyle: "medium",
    timeStyle: "short",
  });
}

export function CaseDetailContent({ caseId }: CaseDetailContentProps) {
  const {
    me,
    selectedOrganizationId,
    loading: sessionLoading,
    error: sessionError,
  } = useSession();
  const [caseRecord, setCaseRecord] = useState<Case | null>(null);
  const [notes, setNotes] = useState<CaseNote[]>([]);
  const [tasks, setTasks] = useState<CaseTask[]>([]);
  const [timeline, setTimeline] = useState<TimelineEvent[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);

  const [assigning, setAssigning] = useState(false);
  const [narrative, setNarrative] = useState("");
  const [addingNote, setAddingNote] = useState(false);
  const [taskTitle, setTaskTitle] = useState("");
  const [taskPriority, setTaskPriority] = useState("normal");
  const [addingTask, setAddingTask] = useState(false);

  const membershipId =
    me?.selectedMembershipId ??
    me?.memberships.find(
      (m) => m.organizationId === selectedOrganizationId && m.isActive,
    )?.membershipId ??
    null;

  const loadData = useCallback(async () => {
    if (!selectedOrganizationId) {
      setLoading(false);
      return;
    }

    setLoading(true);
    setError(null);
    try {
      const [caseData, notesData, tasksData, timelineData] = await Promise.all([
        getCase(selectedOrganizationId, caseId),
        listNotes(selectedOrganizationId, caseId),
        listTasks(selectedOrganizationId, caseId),
        getTimeline(selectedOrganizationId, caseId),
      ]);
      setCaseRecord(caseData);
      setNotes(notesData);
      setTasks(tasksData);
      setTimeline(timelineData);
    } catch (err) {
      setError(
        err instanceof ApiProblemError
          ? err.message
          : err instanceof Error
            ? err.message
            : "Unable to load case",
      );
    } finally {
      setLoading(false);
    }
  }, [selectedOrganizationId, caseId]);

  useEffect(() => {
    setLastCaseId(caseId);
  }, [caseId]);

  useEffect(() => {
    if (!sessionLoading) {
      void loadData();
    }
  }, [sessionLoading, loadData]);

  async function handleAssign() {
    if (!selectedOrganizationId || !membershipId) {
      return;
    }

    setAssigning(true);
    setError(null);
    setSuccess(null);
    try {
      await createAssignment(selectedOrganizationId, caseId, {
        membershipId,
        roleOnCase: "advocate",
      });
      setSuccess("You have been assigned to this case.");
      await loadData();
    } catch (err) {
      setError(
        err instanceof ApiProblemError
          ? err.message
          : err instanceof Error
            ? err.message
            : "Unable to assign case",
      );
    } finally {
      setAssigning(false);
    }
  }

  async function handleAddNote(event: React.FormEvent) {
    event.preventDefault();
    if (!selectedOrganizationId || !narrative.trim()) {
      return;
    }

    setAddingNote(true);
    setError(null);
    setSuccess(null);
    try {
      await createNote(selectedOrganizationId, caseId, {
        narrative: narrative.trim(),
        noteType: "general",
        visibilityLevel: "standard",
      });
      setNarrative("");
      setSuccess("Note added.");
      await loadData();
    } catch (err) {
      setError(
        err instanceof ApiProblemError
          ? err.message
          : err instanceof Error
            ? err.message
            : "Unable to add note",
      );
    } finally {
      setAddingNote(false);
    }
  }

  async function handleAddTask(event: React.FormEvent) {
    event.preventDefault();
    if (!selectedOrganizationId || !taskTitle.trim()) {
      return;
    }

    setAddingTask(true);
    setError(null);
    setSuccess(null);
    try {
      await createTask(selectedOrganizationId, caseId, {
        title: taskTitle.trim(),
        priority: taskPriority,
        assignedMembershipId: membershipId ?? undefined,
      });
      setTaskTitle("");
      setSuccess("Task added.");
      await loadData();
    } catch (err) {
      setError(
        err instanceof ApiProblemError
          ? err.message
          : err instanceof Error
            ? err.message
            : "Unable to add task",
      );
    } finally {
      setAddingTask(false);
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
      <p className="status-message">Select an organization to view this case.</p>
    );
  }

  if (!caseRecord) {
    return <p className="status-message status-message--error">{error ?? "Case not found."}</p>;
  }

  return (
    <>
      <p className="page-lead">
        <Link className="text-link" href={`/clients/${caseRecord.clientId}`}>
          ← Back to client
        </Link>
      </p>

      {error ? <p className="status-message status-message--error">{error}</p> : null}
      {success ? (
        <p className="status-message status-message--success">{success}</p>
      ) : null}

      <section className="module-section">
        <h2 className="module-section-title">Case overview</h2>
        <dl className="detail-list">
          <div className="detail-row">
            <dt>Title</dt>
            <dd>{caseRecord.title ?? "Untitled case"}</dd>
          </div>
          <div className="detail-row">
            <dt>Status</dt>
            <dd>{caseRecord.status}</dd>
          </div>
          <div className="detail-row">
            <dt>Opened</dt>
            <dd>{formatDate(caseRecord.createdAt)}</dd>
          </div>
        </dl>
      </section>

      <section className="module-section">
        <h2 className="module-section-title">Assign</h2>
        <p className="module-section-lead">
          Assign yourself as advocate using your current membership.
        </p>
        <div className="form-actions">
          <button
            className="btn-primary"
            type="button"
            onClick={() => void handleAssign()}
            disabled={assigning || !membershipId}
          >
            {assigning ? "Assigning…" : "Assign me to this case"}
          </button>
        </div>
        {!membershipId ? (
          <p className="status-message">No active membership for this organization.</p>
        ) : null}
      </section>

      <section className="module-section">
        <h2 className="module-section-title">Add note</h2>
        <form className="module-form" onSubmit={handleAddNote}>
          <label className="form-field">
            <span className="form-label">Narrative</span>
            <textarea
              className="form-textarea"
              value={narrative}
              onChange={(e) => setNarrative(e.target.value)}
              rows={4}
              required
            />
          </label>
          <div className="form-actions">
            <button className="btn-primary" type="submit" disabled={addingNote}>
              {addingNote ? "Saving…" : "Add note"}
            </button>
          </div>
        </form>
        {notes.length > 0 ? (
          <ul className="compact-list">
            {notes.map((note) => (
              <li key={note.id} className="compact-list-item">
                <span className="compact-list-meta">
                  {formatDate(note.createdAt)} · {note.noteType}
                </span>
                <p className="compact-list-body">{note.narrative}</p>
              </li>
            ))}
          </ul>
        ) : null}
      </section>

      <section className="module-section">
        <h2 className="module-section-title">Add task</h2>
        <form className="module-form" onSubmit={handleAddTask}>
          <label className="form-field">
            <span className="form-label">Title</span>
            <input
              className="form-input"
              value={taskTitle}
              onChange={(e) => setTaskTitle(e.target.value)}
              required
            />
          </label>
          <label className="form-field">
            <span className="form-label">Priority</span>
            <select
              className="form-select"
              value={taskPriority}
              onChange={(e) => setTaskPriority(e.target.value)}
            >
              <option value="low">Low</option>
              <option value="normal">Normal</option>
              <option value="high">High</option>
            </select>
          </label>
          <div className="form-actions">
            <button className="btn-primary" type="submit" disabled={addingTask}>
              {addingTask ? "Saving…" : "Add task"}
            </button>
          </div>
        </form>
        {tasks.length > 0 ? (
          <ul className="compact-list">
            {tasks.map((task) => (
              <li key={task.id} className="compact-list-item">
                <span className="compact-list-primary">{task.title}</span>
                <span className="compact-list-meta">
                  {task.status} · {task.priority}
                </span>
              </li>
            ))}
          </ul>
        ) : null}
      </section>

      <section className="module-section">
        <h2 className="module-section-title">Timeline</h2>
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
    </>
  );
}
