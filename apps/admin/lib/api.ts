export type HealthState = "healthy" | "degraded" | "offline";

export interface DashboardOverview {
  generatedAt: string;
  users: {
    total: number;
    active24h: number;
    pendingVerification: number;
    newThisWeek: number;
  };
  reports: {
    open: number;
    urgent: number;
    resolvedToday: number;
    medianResponseMinutes: number;
  };
  content: {
    pendingReview: number;
    removedToday: number;
    flaggedMedia: number;
    appeals: number;
  };
  mesh: {
    state: HealthState;
    healthyNodes: number;
    totalNodes: number;
    averageLatencyMs: number;
    lastSyncAt: string;
  };
  activity: Array<{
    id: string;
    kind: "report" | "user" | "content" | "mesh";
    title: string;
    detail: string;
    occurredAt: string;
  }>;
}

export interface AdminUser {
  id: string;
  email: string;
  displayName: string;
  createdAt: string;
  deletedAt: string | null;
}

export interface AdminReport {
  id: string;
  reporterId: string;
  reportedId: string | null;
  messageId: string | null;
  reason: string;
  details: string | null;
  status: string;
  createdAt: string;
}

export interface EdgeNode {
  id: string;
  name: string;
  meshHost: string;
  meshPort: number;
  status: string;
  lastSeenAt: string | null;
  createdAt: string;
}

export interface SupportTicket {
  id: string;
  subject: string;
  body: string;
  status: string;
  reply: string | null;
  aiDraft: string | null;
  createdAt: string;
  user?: { id: string; displayName: string };
}

export interface CreatedEdgeNode extends EdgeNode {
  joinToken: string;
}

export class AdminApiError extends Error {
  readonly status: number;
  readonly requestId?: string;

  constructor(message: string, status: number, requestId?: string) {
    super(message);
    this.name = "AdminApiError";
    this.status = status;
    this.requestId = requestId;
  }
}

function readCookie(name: string): string | undefined {
  if (typeof document === "undefined") return undefined;
  const prefix = `${encodeURIComponent(name)}=`;
  const cookie = document.cookie
    .split(";")
    .map((item) => item.trim())
    .find((item) => item.startsWith(prefix));
  return cookie ? decodeURIComponent(cookie.slice(prefix.length)) : undefined;
}

function getApiBaseUrl(): string {
  const configured = (process.env.NEXT_PUBLIC_ADMIN_API_URL?.trim() || "/v1/admin").replace(/\/$/, "");
  // Ornekler: "/v1/admin" (ayni origin) veya "https://api.sonalis.com.tr" (mutlak kok).
  const root = configured.endsWith("/v1/admin") ? configured : `${configured}/v1/admin`;
  return root;
}

let inMemoryToken: string | null = null;

export function setAdminToken(token: string | null): void {
  inMemoryToken = token;
}

/**
 * Browser-side admin API client.
 *
 * Kimlik dogrulama: giriste alinan kisa omurlu Bearer jeton yalnizca
 * bellek degiskeninde tutulur (localStorage/sessionStorage YOK).
 * Sayfa yenilenince oturum duser, yeniden giris gerekir.
 */
export class AdminApiClient {
  constructor(private readonly baseUrl = getApiBaseUrl()) {}

  private async request<T>(path: string, init: RequestInit = {}): Promise<T> {
    const headers = new Headers(init.headers);
    headers.set("Accept", "application/json");
    if (inMemoryToken) headers.set("Authorization", `Bearer ${inMemoryToken}`);
    if (init.body && !headers.has("Content-Type")) {
      headers.set("Content-Type", "application/json");
    }

    // Mutating API calls can use a double-submit CSRF cookie. GET requests do
    // not need it, but adding the header when present keeps the client generic.
    if (init.method && !["GET", "HEAD", "OPTIONS"].includes(init.method.toUpperCase())) {
      const csrf = readCookie("csrf_token") ?? readCookie("XSRF-TOKEN");
      if (csrf) headers.set("X-CSRF-Token", csrf);
    }

    const response = await fetch(`${this.baseUrl}${path}`, {
      ...init,
      headers,
      credentials: "include",
      cache: "no-store"
    });

    if (!response.ok) {
      let message = `Admin API isteği başarısız (${response.status})`;
      try {
        const body = (await response.json()) as { message?: string };
        if (body.message) message = body.message;
      } catch {
        // Error body is optional; keep the status-based message.
      }
      throw new AdminApiError(message, response.status, response.headers.get("x-request-id") ?? undefined);
    }

    if (response.status === 204) return undefined as T;
    const rawBody = await response.text();
    if (!rawBody.trim()) return undefined as T;
    try {
      return JSON.parse(rawBody) as T;
    } catch {
      throw new AdminApiError("Admin API geçersiz JSON döndürdü", 502, response.headers.get("x-request-id") ?? undefined);
    }
  }

  getOverview(): Promise<DashboardOverview> {
    return this.request<DashboardOverview>("/overview");
  }

  async adminLogin(email: string, password: string): Promise<void> {
    const authUrl = this.baseUrl.replace(/\/v1\/admin$/, "/v1/auth/admin-login");
    const response = await fetch(authUrl, {
      method: "POST",
      headers: { "Content-Type": "application/json", Accept: "application/json" },
      body: JSON.stringify({ email, password })
    });
    if (!response.ok) throw new AdminApiError("E-posta veya şifre hatalı", response.status);
    const body = (await response.json()) as { data: { accessToken: string } };
    setAdminToken(body.data.accessToken);
  }

  async getUsers(limit = 20): Promise<AdminUser[]> {
    const body = await this.request<{ data: AdminUser[] } | AdminUser[]>(`/users?limit=${encodeURIComponent(String(limit))}`);
    return Array.isArray(body) ? body : body.data;
  }

  async getReports(): Promise<AdminReport[]> {
    const body = await this.request<{ data: AdminReport[] } | AdminReport[]>("/reports");
    return Array.isArray(body) ? body : body.data;
  }

  getMeshHealth(): Promise<DashboardOverview["mesh"]> {
    return this.request<DashboardOverview["mesh"]>("/mesh/health");
  }

  async suspendUser(userId: string, reason: string): Promise<void> {
    await this.request<unknown>(`/users/${encodeURIComponent(userId)}/suspend`, {
      method: "POST",
      body: JSON.stringify({ reason })
    });
  }

  async resolveReport(reportId: string, action: "dismiss" | "remove" | "suspend"): Promise<void> {
    await this.request<unknown>(`/reports/${encodeURIComponent(reportId)}/resolve`, {
      method: "POST",
      body: JSON.stringify({ action })
    });
  }

  async getEdges(): Promise<EdgeNode[]> {
    const body = await this.request<{ data: EdgeNode[] } | EdgeNode[]>("/edge");
    return Array.isArray(body) ? body : body.data;
  }

  async createEdge(input: { name: string; meshHost: string; meshPort: number }): Promise<CreatedEdgeNode> {
    const body = await this.request<{ data: CreatedEdgeNode }>("/edge", {
      method: "POST",
      body: JSON.stringify(input)
    });
    return body.data;
  }

  async deleteEdge(edgeId: string): Promise<void> {
    await this.request<unknown>(`/edge/${encodeURIComponent(edgeId)}`, { method: "DELETE" });
  }

  async getTickets(): Promise<SupportTicket[]> {
    const body = await this.request<{ data: SupportTicket[] } | SupportTicket[]>("/tickets");
    return Array.isArray(body) ? body : body.data;
  }

  async replyTicket(ticketId: string, message: string): Promise<void> {
    await this.request<unknown>(`/tickets/${encodeURIComponent(ticketId)}/reply`, {
      method: "POST",
      body: JSON.stringify({ message })
    });
  }

  async closeTicket(ticketId: string): Promise<void> {
    await this.request<unknown>(`/tickets/${encodeURIComponent(ticketId)}/close`, { method: "POST" });
  }
}

export const adminApi = new AdminApiClient();
