/**
 * RFC 7807 Problem Details for HTTP APIs
 * @see https://datatracker.ietf.org/doc/html/rfc7807
 */
export interface ProblemDetails {
  type?: string;
  title?: string;
  status?: number;
  detail?: string;
  instance?: string;
  [key: string]: unknown;
}

export class ApiProblemError extends Error {
  readonly problem: ProblemDetails;
  readonly status: number;

  constructor(problem: ProblemDetails, status: number) {
    super(problem.detail ?? problem.title ?? "An API error occurred");
    this.name = "ApiProblemError";
    this.problem = problem;
    this.status = status;
  }
}
