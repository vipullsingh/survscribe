/**
 * The API client.
 *
 * Every response from the backend is an ADR-0004 envelope, so unwrapping happens once,
 * here, and callers get either data or a typed ApiRequestError. No feature module should
 * ever touch `response.success` itself.
 *
 * Auth token attachment, refresh-on-401 rotation and the offline queue are NOT here yet:
 * they belong to sprint_0003 (auth) and sprint_0005 (sync engine). The seams are marked.
 */
import type { ApiError, ApiResponse, ErrorCode, Meta } from "@survscribe/types";

import { env } from "../../core/env";

/** A failed API call, carrying the machine-readable code clients branch on. */
export class ApiRequestError extends Error {
  readonly code: ErrorCode | "NETWORK_ERROR" | "TIMEOUT" | "MALFORMED_RESPONSE";
  readonly status: number;
  readonly details: ApiError["details"];
  /** X-Request-ID, so a user-visible failure can be traced to a server log line. */
  readonly requestId: string | null;

  constructor(init: {
    code: ApiRequestError["code"];
    message: string;
    status: number;
    details?: ApiError["details"];
    requestId?: string | null;
  }) {
    super(init.message);
    this.name = "ApiRequestError";
    this.code = init.code;
    this.status = init.status;
    this.details = init.details;
    this.requestId = init.requestId ?? null;
  }

  /**
   * True when the failure is a connectivity problem rather than a rejection.
   *
   * This is the signal the sync engine uses to decide between queueing the mutation for
   * retry and surfacing it to the surveyor. Getting it wrong in the offline direction
   * loses field work, so it is deliberately narrow: only transport failures count.
   */
  get isOffline(): boolean {
    return this.code === "NETWORK_ERROR" || this.code === "TIMEOUT";
  }
}

export interface Page<T> {
  data: T;
  meta: Meta | null;
}

interface RequestOptions {
  method?: "GET" | "POST" | "PATCH" | "PUT" | "DELETE";
  body?: unknown;
  query?: Record<string, string | number | boolean | undefined>;
  signal?: AbortSignal;
}

function buildUrl(path: string, query: RequestOptions["query"]): string {
  const url = new URL(`${env.apiBaseUrl}${path}`);
  for (const [key, value] of Object.entries(query ?? {})) {
    if (value !== undefined) url.searchParams.set(key, String(value));
  }
  return url.toString();
}

async function request<T>(path: string, options: RequestOptions = {}): Promise<Page<T>> {
  const { method = "GET", body, query, signal } = options;

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), env.requestTimeoutMs);
  signal?.addEventListener("abort", () => controller.abort());

  // Built rather than spread: under exactOptionalPropertyTypes, passing an explicit
  // `undefined` for an optional property is not the same as omitting it, and RequestInit
  // does not accept it.
  const init: RequestInit = {
    method,
    headers: {
      Accept: "application/json",
      // sprint_0003: Authorization: `Bearer ${accessToken}` from the Keychain/Keystore.
      ...(body === undefined ? {} : { "Content-Type": "application/json" }),
    },
    signal: controller.signal,
  };
  if (body !== undefined) {
    init.body = JSON.stringify(body);
  }

  let response: Response;
  try {
    response = await fetch(buildUrl(path, query), init);
  } catch (cause) {
    const aborted = cause instanceof Error && cause.name === "AbortError";
    throw new ApiRequestError({
      code: aborted ? "TIMEOUT" : "NETWORK_ERROR",
      message: aborted
        ? "The request timed out. Your work is saved on this device."
        : "No connection. Your work is saved on this device and will sync automatically.",
      status: 0,
    });
  } finally {
    clearTimeout(timeout);
  }

  const requestId = response.headers.get("X-Request-ID");

  if (response.status === 204) {
    return { data: undefined as T, meta: null };
  }

  let payload: ApiResponse<T>;
  try {
    payload = (await response.json()) as ApiResponse<T>;
  } catch {
    throw new ApiRequestError({
      code: "MALFORMED_RESPONSE",
      message: "The server sent a response this app could not read.",
      status: response.status,
      requestId,
    });
  }

  if (payload.success === false) {
    throw new ApiRequestError({
      code: payload.error.code,
      message: payload.error.message,
      status: response.status,
      details: payload.error.details,
      requestId,
    });
  }

  // sprint_0003: a 401 with TOKEN_EXPIRED triggers one refresh-and-retry here.
  return { data: payload.data, meta: payload.meta };
}

export const api = {
  get: <T>(path: string, query?: RequestOptions["query"]) =>
    request<T>(path, query === undefined ? {} : { query }),
  post: <T>(path: string, body?: unknown) =>
    request<T>(path, body === undefined ? { method: "POST" } : { method: "POST", body }),
  patch: <T>(path: string, body?: unknown) =>
    request<T>(path, body === undefined ? { method: "PATCH" } : { method: "PATCH", body }),
  put: <T>(path: string, body?: unknown) =>
    request<T>(path, body === undefined ? { method: "PUT" } : { method: "PUT", body }),
  delete: <T>(path: string) => request<T>(path, { method: "DELETE" }),
};
