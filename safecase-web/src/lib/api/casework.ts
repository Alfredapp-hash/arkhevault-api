import { apiClient } from "@/lib/api/client";
import { buildSessionHeaders } from "@/lib/api/sessionHeaders";
import type {
  Assignment,
  Case,
  CaseNote,
  CaseTask,
  Client,
  CreateAssignmentInput,
  CreateCaseInput,
  CreateClientInput,
  CreateNoteInput,
  CreateTaskInput,
  TimelineEvent,
  VerticalSliceResult,
} from "@/types/casework";

function orgPath(organizationId: string, suffix: string): string {
  return `/api/v1/organizations/${organizationId}${suffix}`;
}

function withOrgHeaders(organizationId: string) {
  return { headers: buildSessionHeaders(organizationId) };
}

export async function listClients(organizationId: string): Promise<Client[]> {
  return apiClient.get<Client[]>(orgPath(organizationId, "/clients"), withOrgHeaders(organizationId));
}

export async function createClient(
  organizationId: string,
  input: CreateClientInput,
): Promise<Client> {
  return apiClient.post<Client>(
    orgPath(organizationId, "/clients"),
    input,
    withOrgHeaders(organizationId),
  );
}

export async function getClient(
  organizationId: string,
  clientId: string,
): Promise<Client> {
  return apiClient.get<Client>(
    orgPath(organizationId, `/clients/${clientId}`),
    withOrgHeaders(organizationId),
  );
}

export async function listCasesForClient(
  organizationId: string,
  clientId: string,
): Promise<Case[]> {
  return apiClient.get<Case[]>(
    orgPath(organizationId, `/clients/${clientId}/cases`),
    withOrgHeaders(organizationId),
  );
}

export async function createCase(
  organizationId: string,
  clientId: string,
  input: CreateCaseInput,
): Promise<Case> {
  return apiClient.post<Case>(
    orgPath(organizationId, `/clients/${clientId}/cases`),
    input,
    withOrgHeaders(organizationId),
  );
}

export async function getCase(
  organizationId: string,
  caseId: string,
): Promise<Case> {
  return apiClient.get<Case>(
    orgPath(organizationId, `/cases/${caseId}`),
    withOrgHeaders(organizationId),
  );
}

export async function createAssignment(
  organizationId: string,
  caseId: string,
  input: CreateAssignmentInput,
): Promise<Assignment> {
  return apiClient.post<Assignment>(
    orgPath(organizationId, `/cases/${caseId}/assignments`),
    input,
    withOrgHeaders(organizationId),
  );
}

export async function listNotes(
  organizationId: string,
  caseId: string,
): Promise<CaseNote[]> {
  return apiClient.get<CaseNote[]>(
    orgPath(organizationId, `/cases/${caseId}/notes`),
    withOrgHeaders(organizationId),
  );
}

export async function createNote(
  organizationId: string,
  caseId: string,
  input: CreateNoteInput,
): Promise<CaseNote> {
  return apiClient.post<CaseNote>(
    orgPath(organizationId, `/cases/${caseId}/notes`),
    input,
    withOrgHeaders(organizationId),
  );
}

export async function listTasks(
  organizationId: string,
  caseId: string,
): Promise<CaseTask[]> {
  return apiClient.get<CaseTask[]>(
    orgPath(organizationId, `/cases/${caseId}/tasks`),
    withOrgHeaders(organizationId),
  );
}

export async function createTask(
  organizationId: string,
  caseId: string,
  input: CreateTaskInput,
): Promise<CaseTask> {
  return apiClient.post<CaseTask>(
    orgPath(organizationId, `/cases/${caseId}/tasks`),
    input,
    withOrgHeaders(organizationId),
  );
}

export async function getTimeline(
  organizationId: string,
  caseId: string,
): Promise<TimelineEvent[]> {
  return apiClient.get<TimelineEvent[]>(
    orgPath(organizationId, `/cases/${caseId}/timeline`),
    withOrgHeaders(organizationId),
  );
}

export async function runVerticalSlice(
  organizationId: string,
  input: CreateClientInput,
): Promise<VerticalSliceResult> {
  return apiClient.post<VerticalSliceResult>(
    orgPath(organizationId, "/workflows/vertical-slice"),
    input,
    withOrgHeaders(organizationId),
  );
}
