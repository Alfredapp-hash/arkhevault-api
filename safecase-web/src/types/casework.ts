export interface Client {
  id: string;
  organizationId: string;
  firstName: string;
  lastName: string;
  status: string;
  riskLevel: string | null;
  createdAt: string;
}

export interface Case {
  id: string;
  organizationId: string;
  clientId: string;
  status: string;
  title: string | null;
  createdAt: string;
}

export interface Assignment {
  id: string;
  caseId: string;
  membershipId: string;
  roleOnCase: string;
  assignedAt: string;
}

export interface CaseNote {
  id: string;
  caseId: string;
  authorMembershipId: string;
  noteType: string;
  visibilityLevel: string;
  narrative: string | null;
  isRedacted: boolean;
  createdAt: string;
}

export interface CaseTask {
  id: string;
  caseId: string | null;
  clientId: string | null;
  title: string;
  status: string;
  priority: string;
  dueAt: string | null;
  assignedMembershipId: string | null;
  createdAt: string;
}

export interface TimelineEvent {
  id: string;
  caseId: string;
  clientId: string | null;
  eventType: string;
  summary: string;
  actorMembershipId: string | null;
  relatedResourceId: string | null;
  relatedResourceType: string | null;
  createdAt: string;
}

export interface VerticalSliceResult {
  client: Client;
  case: Case;
  assignment: Assignment;
  note: CaseNote;
  task: CaseTask;
  timeline: TimelineEvent[];
}

export interface CreateClientInput {
  firstName: string;
  lastName: string;
  riskLevel?: string;
  openInitialCase?: boolean;
  caseTitle?: string;
}

export interface CreateCaseInput {
  title?: string;
}

export interface CreateAssignmentInput {
  membershipId: string;
  roleOnCase?: string;
}

export interface CreateNoteInput {
  narrative: string;
  noteType?: string;
  visibilityLevel?: string;
}

export interface CreateTaskInput {
  title: string;
  priority?: string;
  dueAt?: string;
  assignedMembershipId?: string;
}
