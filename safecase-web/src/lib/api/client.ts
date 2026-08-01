import { ApiProblemError } from "@/types/problem-details";
import { problemFromResponse } from "./problems";

export interface ApiClientOptions {
  baseUrl?: string;
  getAccessToken?: () => Promise<string | null>;
  defaultHeaders?: HeadersInit;
}

export interface RequestOptions extends Omit<RequestInit, "body"> {
  body?: unknown;
  params?: Record<string, string | number | boolean | undefined>;
}

function resolveUrl(
  path: string,
  baseUrl: string,
  params?: RequestOptions["params"],
): string {
  const url = new URL(path, baseUrl.endsWith("/") ? baseUrl : `${baseUrl}/`);

  if (params) {
    for (const [key, value] of Object.entries(params)) {
      if (value !== undefined) {
        url.searchParams.set(key, String(value));
      }
    }
  }

  return url.toString();
}

export class ApiClient {
  private readonly baseUrl: string;
  private readonly getAccessToken?: () => Promise<string | null>;
  private readonly defaultHeaders: HeadersInit;

  constructor(options: ApiClientOptions = {}) {
    this.baseUrl =
      options.baseUrl ??
      process.env.NEXT_PUBLIC_API_BASE_URL ??
      "http://localhost:8080";
    this.getAccessToken = options.getAccessToken;
    this.defaultHeaders = options.defaultHeaders ?? {};
  }

  async request<T>(path: string, options: RequestOptions = {}): Promise<T> {
    const { body, params, headers, ...init } = options;
    const url = resolveUrl(path, this.baseUrl, params);

    const requestHeaders = new Headers(this.defaultHeaders);
    if (headers) {
      new Headers(headers).forEach((value, key) => {
        requestHeaders.set(key, value);
      });
    }

    if (this.getAccessToken) {
      const token = await this.getAccessToken();
      if (token) {
        requestHeaders.set("Authorization", `Bearer ${token}`);
      }
    }

    let requestBody: BodyInit | undefined;
    if (body !== undefined) {
      requestHeaders.set("Content-Type", "application/json");
      requestBody = JSON.stringify(body);
    }

    requestHeaders.set("Accept", "application/json, application/problem+json");

    const response = await fetch(url, {
      ...init,
      headers: requestHeaders,
      body: requestBody,
    });

    if (!response.ok) {
      throw await problemFromResponse(response);
    }

    if (response.status === 204) {
      return undefined as T;
    }

    const contentType = response.headers.get("content-type") ?? "";
    if (!contentType.includes("json")) {
      return (await response.text()) as T;
    }

    return (await response.json()) as T;
  }

  get<T>(path: string, options?: Omit<RequestOptions, "method" | "body">) {
    return this.request<T>(path, { ...options, method: "GET" });
  }

  post<T>(
    path: string,
    body?: unknown,
    options?: Omit<RequestOptions, "method" | "body">,
  ) {
    return this.request<T>(path, { ...options, method: "POST", body });
  }

  put<T>(
    path: string,
    body?: unknown,
    options?: Omit<RequestOptions, "method" | "body">,
  ) {
    return this.request<T>(path, { ...options, method: "PUT", body });
  }

  patch<T>(
    path: string,
    body?: unknown,
    options?: Omit<RequestOptions, "method" | "body">,
  ) {
    return this.request<T>(path, { ...options, method: "PATCH", body });
  }

  delete<T>(path: string, options?: Omit<RequestOptions, "method" | "body">) {
    return this.request<T>(path, { ...options, method: "DELETE" });
  }
}

/** Default singleton for app-wide API calls */
export const apiClient = new ApiClient();

export { ApiProblemError };
