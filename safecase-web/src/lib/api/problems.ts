import {
  ApiProblemError,
  type ProblemDetails,
} from "@/types/problem-details";

const PROBLEM_JSON = "application/problem+json";
const PROBLEM_JSON_LEGACY = "application/json";

export function isProblemDetails(value: unknown): value is ProblemDetails {
  if (!value || typeof value !== "object") return false;
  const record = value as Record<string, unknown>;
  return (
    typeof record.title === "string" ||
    typeof record.detail === "string" ||
    typeof record.status === "number" ||
    typeof record.type === "string"
  );
}

export async function parseProblemResponse(
  response: Response,
): Promise<ProblemDetails | null> {
  const contentType = response.headers.get("content-type") ?? "";

  if (
    !contentType.includes(PROBLEM_JSON) &&
    !contentType.includes(PROBLEM_JSON_LEGACY)
  ) {
    return null;
  }

  try {
    const body: unknown = await response.json();
    if (!isProblemDetails(body)) return null;

    return {
      ...body,
      status: body.status ?? response.status,
    };
  } catch {
    return null;
  }
}

export async function problemFromResponse(
  response: Response,
): Promise<ApiProblemError> {
  const parsed = await parseProblemResponse(response);

  if (parsed) {
    return new ApiProblemError(parsed, parsed.status ?? response.status);
  }

  const fallback: ProblemDetails = {
    type: "about:blank",
    title: response.statusText || "Request failed",
    status: response.status,
    detail: `HTTP ${response.status}`,
  };

  return new ApiProblemError(fallback, response.status);
}
