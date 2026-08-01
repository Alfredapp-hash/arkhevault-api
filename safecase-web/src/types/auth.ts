export type SafeCaseRole =
  | "admin"
  | "case_manager"
  | "advocate"
  | "viewer"
  | string;

export interface AuthUser {
  id: string;
  displayName: string;
  email: string;
  roles: SafeCaseRole[];
}

export interface Organization {
  id: string;
  name: string;
  slug?: string;
}

export interface MembershipSummary {
  membershipId: string;
  organizationId: string;
  organizationName: string;
  organizationSlug: string;
  isActive: boolean;
  roles: string[];
}

export interface MeResponse {
  userId: string;
  entraObjectId: string;
  email: string;
  displayName: string;
  isPlatformOperator: boolean;
  memberships: MembershipSummary[];
  selectedOrganizationId?: string | null;
  selectedMembershipId?: string | null;
  permissions: string[];
}
