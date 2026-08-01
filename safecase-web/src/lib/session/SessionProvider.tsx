"use client";

import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
} from "react";
import { apiClient } from "@/lib/api/client";
import type { MeResponse } from "@/types/auth";

const ORG_STORAGE_KEY = "safecase.selectedOrganizationId";

interface SessionContextValue {
  me: MeResponse | null;
  loading: boolean;
  error: string | null;
  selectedOrganizationId: string | null;
  setSelectedOrganizationId: (organizationId: string) => void;
  refresh: () => Promise<void>;
  isDevAuth: boolean;
}

const SessionContext = createContext<SessionContextValue | null>(null);

function buildDevHeaders(organizationId: string | null): HeadersInit {
  const headers: Record<string, string> = {};
  if (process.env.NEXT_PUBLIC_USE_DEV_AUTH === "false") {
    if (organizationId) {
      headers["X-Organization-Id"] = organizationId;
    }
    return headers;
  }

  headers["X-Dev-User"] =
    process.env.NEXT_PUBLIC_DEV_USER ?? "dev-org-a-admin";
  headers["X-Dev-Email"] =
    process.env.NEXT_PUBLIC_DEV_EMAIL ?? "admin.a@safecase.local";
  headers["X-Dev-Name"] =
    process.env.NEXT_PUBLIC_DEV_NAME ?? "Org A Administrator";
  if (organizationId) {
    headers["X-Organization-Id"] = organizationId;
  }
  return headers;
}

export function SessionProvider({ children }: { children: React.ReactNode }) {
  const [me, setMe] = useState<MeResponse | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [selectedOrganizationId, setSelectedOrganizationIdState] = useState<
    string | null
  >(null);
  const isDevAuth = process.env.NEXT_PUBLIC_USE_DEV_AUTH !== "false";

  const loadSession = useCallback(async (organizationId: string | null) => {
    setLoading(true);
    setError(null);
    try {
      const response = await apiClient.get<MeResponse>("/api/v1/me", {
        headers: buildDevHeaders(organizationId),
      });
      setMe(response);

      const preferred =
        organizationId &&
        response.memberships.some(
          (m) => m.organizationId === organizationId && m.isActive,
        )
          ? organizationId
          : (response.selectedOrganizationId ??
            response.memberships.find((m) => m.isActive)?.organizationId ??
            null);

      setSelectedOrganizationIdState(preferred);
      if (preferred) {
        window.localStorage.setItem(ORG_STORAGE_KEY, preferred);
      }
    } catch (err) {
      setMe(null);
      setError(err instanceof Error ? err.message : "Unable to load session");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    const stored = window.localStorage.getItem(ORG_STORAGE_KEY);
    void loadSession(stored);
  }, [loadSession]);

  const setSelectedOrganizationId = useCallback(
    (organizationId: string) => {
      window.localStorage.setItem(ORG_STORAGE_KEY, organizationId);
      setSelectedOrganizationIdState(organizationId);
      void loadSession(organizationId);
    },
    [loadSession],
  );

  const refresh = useCallback(async () => {
    await loadSession(selectedOrganizationId);
  }, [loadSession, selectedOrganizationId]);

  const value = useMemo(
    () => ({
      me,
      loading,
      error,
      selectedOrganizationId,
      setSelectedOrganizationId,
      refresh,
      isDevAuth,
    }),
    [
      me,
      loading,
      error,
      selectedOrganizationId,
      setSelectedOrganizationId,
      refresh,
      isDevAuth,
    ],
  );

  return (
    <SessionContext.Provider value={value}>{children}</SessionContext.Provider>
  );
}

export function useSession() {
  const ctx = useContext(SessionContext);
  if (!ctx) {
    throw new Error("useSession must be used within SessionProvider");
  }
  return ctx;
}
