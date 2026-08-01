const LAST_CASE_STORAGE_KEY = "safecase.lastCaseId";

export function getLastCaseId(): string | null {
  if (typeof window === "undefined") {
    return null;
  }
  return window.sessionStorage.getItem(LAST_CASE_STORAGE_KEY);
}

export function setLastCaseId(caseId: string): void {
  if (typeof window === "undefined") {
    return;
  }
  window.sessionStorage.setItem(LAST_CASE_STORAGE_KEY, caseId);
}
