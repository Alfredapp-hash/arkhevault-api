export type SafeCaseRole =
  | "admin"
  | "case_manager"
  | "advocate"
  | "viewer";

export interface AuthUser {
  id: string;
  displayName: string;
  email: string;
  roles: SafeCaseRole[];
}

export interface Organization {
  id: string;
  name: string;
}
