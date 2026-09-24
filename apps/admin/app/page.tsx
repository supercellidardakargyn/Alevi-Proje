"use client";

import { memo, useCallback, useEffect, useMemo, useState } from "react";
import { AdminApiError, adminApi, setAdminToken, type AdminReport, type AdminUser, type CreatedEdgeNode, type DashboardOverview, type EdgeNode, type HealthState, type SupportTicket } from "../lib/api";
import { adminSecurityNotes } from "../lib/security";

const numberFormatter = new Intl.NumberFormat("tr-TR");
const dateFormatter = new Intl.DateTimeFormat("tr-TR", {
  day: "2-digit",
  month: "long",
  year: "numeric",
  hour: "2-digit",
  minute: "2-digit",
  timeZone: "Europe/Istanbul",
  timeZoneName: "short"
});

const navItems: ReadonlyArray<{ label: string; icon: string; href: string; count?: "users" | "reports" | "content" | "mesh" }> = [
  { label: "Genel bakış", icon: "grid", href: "#genel-bakis" },
  { label: "Kullanıcılar", icon: "users", href: "#kullanicilar", count: "users" },
  { label: "Şikâyetler", icon: "flag", href: "#sikayetler", count: "reports" },
  { label: "Destek", icon: "layers", href: "#destek" },
  { label: "Sunucular", icon: "pulse", href: "#sunucular", count: "mesh" }
];

const emptyOverview: DashboardOverview = {
  generatedAt: "",
  users: { total: 0, active24h: 0, pendingVerification: 0, newThisWeek: 0 },
  reports: { open: 0, urgent: 0, resolvedToday: 0, medianResponseMinutes: 0 },
  content: { pendingReview: 0, removedToday: 0, flaggedMedia: 0, appeals: 0 },
  mesh: { state: "offline", healthyNodes: 0, totalNodes: 0, averageLatencyMs: 0, lastSyncAt: "" },
  activity: []
};

function formatNumber(value: number): string {
  return numberFormatter.format(value);
}

function formatTime(value: string): string {
  if (!value) return "—";
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? "—" : dateFormatter.format(date);
}

function relativeTime(value: string): string {
  if (!value) return "—";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "—";
  const elapsedMinutes = Math.max(0, Math.floor((Date.now() - date.getTime()) / 60000));
  if (elapsedMinutes < 1) return "az önce";
  if (elapsedMinutes < 60) return `${elapsedMinutes} dk önce`;
  const elapsedHours = Math.floor(elapsedMinutes / 60);
  if (elapsedHours < 24) return `${elapsedHours} sa önce`;
  const elapsedDays = Math.floor(elapsedHours / 24);
  return `${elapsedDays} gün önce`;
}

const resolveActionLabels: Record<string, string> = { dismiss: "Kapatıldı", remove: "Kaldırıldı", suspend: "Askıya alındı" };

function Icon({ name }: { name: string }) {
  const common = { width: 20, height: 20, viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", strokeWidth: 1.8, strokeLinecap: "round" as const, strokeLinejoin: "round" as const, "aria-hidden": true as const };
  if (name === "grid") return <svg {...common}><rect x="3" y="3" width="7" height="7" rx="1" /><rect x="14" y="3" width="7" height="7" rx="1" /><rect x="3" y="14" width="7" height="7" rx="1" /><rect x="14" y="14" width="7" height="7" rx="1" /></svg>;
  if (name === "users") return <svg {...common}><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2" /><circle cx="9" cy="7" r="4" /><path d="M22 21v-2a4 4 0 0 0-3-3.87M16 3.13a4 4 0 0 1 0 7.75" /></svg>;
  if (name === "flag") return <svg {...common}><path d="M5 21V4" /><path d="M5 4c5-3 9 3 14 0v10c-5 3-9-3-14 0" /></svg>;
  if (name === "layers") return <svg {...common}><path d="m12 2 9 5-9 5-9-5 9-5Z" /><path d="m3 12 9 5 9-5" /><path d="m3 17 9 5 9-5" /></svg>;
  if (name === "pulse") return <svg {...common}><path d="M3 12h4l3-8 4 16 3-8h4" /></svg>;
  if (name === "settings") return <svg {...common}><circle cx="12" cy="12" r="3" /><path d="M19.4 15a1.7 1.7 0 0 0 .34 1.88l.06.06-1.4 1.4-.06-.06a1.7 1.7 0 0 0-1.88-.34 1.7 1.7 0 0 0-1.03 1.56V21h-2v-.5a1.7 1.7 0 0 0-1.03-1.56 1.7 1.7 0 0 0-1.88.34l-.06.06-1.4-1.4.06-.06A1.7 1.7 0 0 0 9.4 15a1.7 1.7 0 0 0-1.56-1.03H7v-2h.5A1.7 1.7 0 0 0 9.06 11a1.7 1.7 0 0 0-.34-1.88l-.06-.06 1.4-1.4.06.06A1.7 1.7 0 0 0 12 8.06 1.7 1.7 0 0 0 13.03 6.5V6h2v.5A1.7 1.7 0 0 0 16.06 8a1.7 1.7 0 0 0 1.88-.34L18 7.6l1.4 1.4-.06.06A1.7 1.7 0 0 0 19.4 11c.17.62.75 1.03 1.39 1.03H21v2h-.21c-.64 0-1.22.4-1.39.97Z" /></svg>;
  if (name === "search") return <svg {...common}><circle cx="11" cy="11" r="7" /><path d="m20 20-4-4" /></svg>;
  if (name === "shield") return <svg {...common}><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10Z" /><path d="m9 12 2 2 4-4" /></svg>;
  return <svg {...common}><circle cx="12" cy="12" r="9" /></svg>;
}

function healthLabel(state: HealthState): string {
  return state === "healthy" ? "Sağlıklı" : state === "degraded" ? "Kısmi sorun" : "Çevrimdışı";
}

function HealthPill({ state }: { state: HealthState }) {
  return <span className={`health-pill ${state}`}><span className="health-dot" />{healthLabel(state)}</span>;
}

const MetricCard = memo(function MetricCard({ title, value, caption, icon, tone, footer }: { title: string; value: string; caption: string; icon: string; tone: string; footer?: string }) {
  return (
    <article className="metric-card">
      <div className={`metric-icon ${tone}`} aria-hidden="true"><Icon name={icon} /></div>
      <div className="metric-heading"><span>{title}</span></div>
      <strong className="metric-value">{value}</strong>
      <div className="metric-caption">{caption}</div>
      {footer && <div className="metric-footer">{footer}</div>}
    </article>
  );
});

export default function AdminDashboard() {
  const [overview, setOverview] = useState<DashboardOverview>(emptyOverview);
  const [users, setUsers] = useState<AdminUser[]>([]);
  const [reports, setReports] = useState<AdminReport[]>([]);
  const [edges, setEdges] = useState<EdgeNode[]>([]);
  const [tickets, setTickets] = useState<SupportTicket[]>([]);
  const [replyTarget, setReplyTarget] = useState<SupportTicket | null>(null);
  const [replyText, setReplyText] = useState("");
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [lastRefresh, setLastRefresh] = useState<Date | null>(null);
  const [actionMessage, setActionMessage] = useState<string | null>(null);
  const [actionError, setActionError] = useState<string | null>(null);
  const [pendingAction, setPendingAction] = useState<string | null>(null);
  const [needsLogin, setNeedsLogin] = useState(false);
  const [loginEmail, setLoginEmail] = useState("");
  const [loginPassword, setLoginPassword] = useState("");
  const [loginBusy, setLoginBusy] = useState(false);
  const [edgeName, setEdgeName] = useState("");
  const [edgeHost, setEdgeHost] = useState("");
  const [edgePort, setEdgePort] = useState("25763");
  const [createdEdge, setCreatedEdge] = useState<CreatedEdgeNode | null>(null);
  const [userFilter, setUserFilter] = useState("");
  const [reportFilter, setReportFilter] = useState<"all" | "OPEN" | "REVIEWING">("all");
  const [userLimit, setUserLimit] = useState(20);
  const [meshRefreshing, setMeshRefreshing] = useState(false);
  const [suspendTarget, setSuspendTarget] = useState<AdminUser | null>(null);
  const [suspendReason, setSuspendReason] = useState("Güvenlik incelemesi");
  const [deleteTarget, setDeleteTarget] = useState<EdgeNode | null>(null);
  const [copied, setCopied] = useState(false);

  const loadDashboard = useCallback(async (signal: { mounted: boolean }) => {
    setLoading(true);
    setError(null);
    try {
      const [dashboard, userList, reportList, edgeList, ticketList] = await Promise.all([
        adminApi.getOverview(),
        adminApi.getUsers(20).catch(() => [] as AdminUser[]),
        adminApi.getReports().catch(() => [] as AdminReport[]),
        adminApi.getEdges().catch(() => [] as EdgeNode[]),
        adminApi.getTickets().catch(() => [] as SupportTicket[])
      ]);
      if (!signal.mounted) return;
      setOverview(dashboard);
      setUsers(userList);
      setReports(reportList);
      setEdges(edgeList);
      setTickets(ticketList);
      setLastRefresh(new Date());
    } catch (reason: unknown) {
      if (!signal.mounted) return;
      if (reason instanceof AdminApiError && reason.status === 401) {
        setAdminToken(null);
        setNeedsLogin(true);
        setError(null);
      } else {
        const message = reason instanceof AdminApiError && reason.status === 403
          ? "Bu hesap yönetici değil. Yetkili hesapla giriş yapın."
          : "API'ye ulaşılamadı. Operasyon verileri canlı bağlantı kurulunca görünecek.";
        setError(message);
      }
    } finally {
      if (signal.mounted) setLoading(false);
    }
  }, []);

  async function handleLogin(event: React.FormEvent): Promise<void> {
    event.preventDefault();
    if (!loginEmail.trim() || !loginPassword) return;
    setLoginBusy(true);
    setActionError(null);
    try {
      await adminApi.adminLogin(loginEmail.trim(), loginPassword);
      setNeedsLogin(false);
      setLoginPassword("");
      await loadDashboard({ mounted: true });
      setActionMessage("Yönetici girişi başarılı.");
    } catch {
      setActionError("E-posta veya şifre hatalı.");
    } finally {
      setLoginBusy(false);
    }
  }

  useEffect(() => {
    const signal = { mounted: true };
    // Dashboard verisi harici sistemden (API) senkronize ediliyor.
    // eslint-disable-next-line react-hooks/set-state-in-effect
    void loadDashboard(signal);
    return () => { signal.mounted = false; };
  }, [loadDashboard]);

  async function handleSuspend(userId: string): Promise<void> {
    if (suspendReason.trim().length < 3) {
      setActionError("Suspend gerekçesi en az 3 karakter olmalı.");
      return;
    }
    setPendingAction(`suspend:${userId}`);
    setActionError(null);
    try {
      await adminApi.suspendUser(userId, suspendReason.trim());
      setUsers((current) => current.filter((user) => user.id !== userId));
      setSuspendTarget(null);
      setActionMessage("Kullanıcı askıya alındı ve denetim izine yazıldı.");
    } catch {
      setActionError("Askıya alma başarısız. Yetkinizi ve bağlantıyı kontrol edin.");
    } finally {
      setPendingAction(null);
    }
  }

  async function handleResolve(reportId: string, action: "dismiss" | "remove" | "suspend"): Promise<void> {
    setPendingAction(`report:${reportId}`);
    setActionError(null);
    try {
      await adminApi.resolveReport(reportId, action);
      setReports((current) => current.filter((report) => report.id !== reportId));
      setActionMessage(`Şikâyet ${resolveActionLabels[action].toLocaleLowerCase("tr-TR")}.`);
    } catch {
      setActionError("Şikâyet kapatılamadı. Bağlantıyı kontrol edin.");
    } finally {
      setPendingAction(null);
    }
  }

  async function handleMeshRefresh(): Promise<void> {
    setMeshRefreshing(true);
    try {
      const mesh = await adminApi.getMeshHealth();
      setOverview((current) => ({ ...current, mesh: { ...current.mesh, ...mesh } }));
      setLastRefresh(new Date());
    } catch {
      setActionError("Mesh durumu alınamadı.");
    } finally {
      setMeshRefreshing(false);
    }
  }

  function handleLogout(): void {
    setAdminToken(null);
    setNeedsLogin(true);
    setOverview(emptyOverview);
    setUsers([]);
    setReports([]);
    setEdges([]);
    setTickets([]);
  }

  async function handleReplyTicket(): Promise<void> {
    if (!replyTarget || replyText.trim().length < 1) return;
    setPendingAction(`ticket:${replyTarget.id}`);
    try {
      await adminApi.replyTicket(replyTarget.id, replyText.trim());
      setTickets((current) =>
        current.map((ticket) =>
          ticket.id === replyTarget.id ? { ...ticket, status: "ANSWERED", reply: replyText.trim() } : ticket
        )
      );
      setReplyTarget(null);
      setReplyText("");
      setActionMessage("Yanıt gönderildi.");
    } catch {
      setActionError("Yanıt gönderilemedi.");
    } finally {
      setPendingAction(null);
    }
  }

  async function handleCloseTicket(ticketId: string): Promise<void> {
    setPendingAction(`ticket:${ticketId}`);
    try {
      await adminApi.closeTicket(ticketId);
      setTickets((current) => current.filter((ticket) => ticket.id !== ticketId));
      setActionMessage("Talep kapatıldı.");
    } catch {
      setActionError("Talep kapatılamadı. Önce yanıt gönderin.");
    } finally {
      setPendingAction(null);
    }
  }

  async function handleCopyToken(): Promise<void> {
    if (!createdEdge) return;
    try {
      await navigator.clipboard.writeText(createdEdge.joinToken);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } catch {
      setActionError("Kopyalanamadı, anahtarı elle seçip kopyalayın.");
    }
  }

  async function handleCreateEdge(event: React.FormEvent): Promise<void> {
    event.preventDefault();
    const port = Number(edgePort);
    if (edgeName.trim().length < 2 || !edgeHost.trim() || !Number.isInteger(port) || port < 1 || port > 65535) {
      setActionError("Sunucu adı (2+ karakter), mesh adresi ve geçerli port girin.");
      return;
    }
    setPendingAction("edge:create");
    setActionError(null);
    try {
      const created = await adminApi.createEdge({ name: edgeName.trim(), meshHost: edgeHost.trim(), meshPort: port });
      setCreatedEdge(created);
      setEdges((current) => [...current, created]);
      setEdgeName("");
      setEdgeHost("");
      setActionMessage(`"${created.name}" kaydedildi. Katılım anahtarını yan sunucuya girin.`);
    } catch {
      setActionError("Sunucu eklenemedi. Bağlantıyı ve yetkini kontrol edin.");
    } finally {
      setPendingAction(null);
    }
  }

  async function handleDeleteEdge(edgeId: string): Promise<void> {
    setPendingAction(`edge:${edgeId}`);
    try {
      await adminApi.deleteEdge(edgeId);
      setEdges((current) => current.filter((edge) => edge.id !== edgeId));
      setDeleteTarget(null);
      setActionMessage("Sunucu silindi.");
    } catch {
      setActionError("Sunucu silinemedi.");
    } finally {
      setPendingAction(null);
    }
  }

  async function handleUserLimit(limit: number): Promise<void> {
    setUserLimit(limit);
    try {
      const userList = await adminApi.getUsers(limit);
      setUsers(userList);
    } catch {
      setActionError("Kullanıcı listesi alınamadı.");
    }
  }

  const filteredUsers = useMemo(() => {
    const query = userFilter.trim().toLocaleLowerCase("tr-TR");
    if (!query) return users;
    return users.filter((user) =>
      user.displayName.toLocaleLowerCase("tr-TR").includes(query) ||
      user.email.toLocaleLowerCase("tr-TR").includes(query)
    );
  }, [users, userFilter]);

  const filteredReports = useMemo(() => {
    if (reportFilter === "all") return reports;
    return reports.filter((report) => report.status === reportFilter);
  }, [reports, reportFilter]);

  const securityScore = useMemo(() => {
    const good = adminSecurityNotes.filter((note) => note.tone === "good").length;
    return `${good}/${adminSecurityNotes.length}`;
  }, []);

  const greetingHour = useMemo(() => {
    const source = overview.generatedAt || lastRefresh?.toISOString() || "";
    const date = new Date(source);
    return Number.isNaN(date.getTime()) ? new Date().getHours() : date.getHours();
  }, [overview.generatedAt, lastRefresh]);

  const meshSummary = useMemo(() => `${overview.mesh.healthyNodes}/${overview.mesh.totalNodes}`, [overview.mesh]);
  const updatedLabel = lastRefresh ? formatTime(lastRefresh.toISOString()) : "Bağlantı bekleniyor";
  const todayLabel = useMemo(() => {
    const source = overview.generatedAt || lastRefresh?.toISOString() || new Date().toISOString();
    const date = new Date(source);
    return Number.isNaN(date.getTime())
      ? "BUGÜN"
      : new Intl.DateTimeFormat("tr-TR", { day: "numeric", month: "long", year: "numeric", weekday: "long" }).format(date);
  }, [overview.generatedAt, lastRefresh]);
  const shortDateLabel = useMemo(() => {
    const source = overview.generatedAt || lastRefresh?.toISOString() || new Date().toISOString();
    const date = new Date(source);
    return Number.isNaN(date.getTime())
      ? "—"
      : new Intl.DateTimeFormat("tr-TR", { day: "numeric", month: "short" }).format(date);
  }, [overview.generatedAt, lastRefresh]);
  const greeting = useMemo(() => {
    if (greetingHour < 6) return "İyi geceler";
    if (greetingHour < 12) return "Günaydın";
    if (greetingHour < 18) return "İyi günler";
    return "İyi akşamlar";
  }, [greetingHour]);

  if (needsLogin) {
    return (
      <div className="admin-shell">
        <main className="main-content">
          <div className="content-wrap login-wrap">
            <div className="brand"><span className="brand-mark">c</span><div><strong>Can Meydanı</strong><span>operasyon merkezi</span></div></div>
            <article className="panel login-panel">
              <p className="eyebrow">YÖNETİCİ GİRİŞİ</p>
              <h1>Operasyon merkezine giriş</h1>
              <p className="intro-copy">Yalnızca ADMIN / MODERATOR rolüne sahip hesaplar girebilir. Oturum jetonu yalnızca bellekte tutulur; sayfa yenilenince yeniden giriş gerekir.</p>
              <form onSubmit={(event) => void handleLogin(event)}>
                <label>E-posta<input type="email" value={loginEmail} onChange={(event) => setLoginEmail(event.target.value)} autoComplete="username" required /></label>
                <label>Şifre<input type="password" value={loginPassword} onChange={(event) => setLoginPassword(event.target.value)} autoComplete="current-password" required /></label>
                <button type="submit" className="outline-button" disabled={loginBusy}>{loginBusy ? "Giriş yapılıyor…" : "Giriş yap"}</button>
              </form>
              {actionError && <div className="api-alert error" role="alert"><strong>Giriş başarısız</strong><span>{actionError}</span></div>}
            </article>
          </div>
        </main>
      </div>
    );
  }

  return (
    <div className="admin-shell">
      <aside className="sidebar">
        <div className="brand"><span className="brand-mark">c</span><div><strong>Can Meydanı</strong><span>operasyon merkezi</span></div></div>
        <div className="workspace-label">YÖNETİM</div>
        <nav aria-label="Yönetim bölümleri">
          {navItems.map((item) => {
            const count = item.count === "users" ? overview.users.pendingVerification : item.count === "reports" ? overview.reports.open : item.count === "content" ? overview.content.pendingReview : item.count === "mesh" ? overview.mesh.totalNodes - overview.mesh.healthyNodes : 0;
            return <a className="nav-item" href={item.href} key={item.label}><Icon name={item.icon} /><span>{item.label}</span>{item.count && count > 0 ? <b>{formatNumber(count)}</b> : null}</a>;
          })}
        </nav>
        <div className="sidebar-bottom"><button type="button" className="nav-item" onClick={handleLogout}><Icon name="settings" /><span>Çıkış yap</span></button><div className="admin-identity"><span className="avatar">AY</span><div><strong>Yönetici</strong><small>oturum açık</small></div></div></div>
      </aside>

      <main className="main-content">
        <header className="topbar"><div className="breadcrumbs"><span>Yönetim</span><i>/</i><strong>Genel bakış</strong></div><div className="topbar-actions"><span className="secure-label"><Icon name="shield" /> Güvenli oturum</span><button type="button" className="icon-button" aria-label="Verileri yenile" title="Verileri yenile" onClick={() => void loadDashboard({ mounted: true })}><Icon name="search" /></button><span className="top-avatar" aria-hidden="true">AY</span></div></header>
        <div className="content-wrap">
          <section className="page-intro" id="genel-bakis"><div><p className="eyebrow">{todayLabel}</p><h1>{greeting}, Yönetici</h1><p className="intro-copy">Topluluğunuzun bugünkü operasyon görünümü.</p></div><div className="intro-status"><span className="live-dot" aria-hidden="true" /> Canlı izleme açık<span className="intro-divider" /> {updatedLabel}</div></section>
          {error && <div className="api-alert" role="status"><strong>Canlı veri bekleniyor</strong><span>{error}</span><button type="button" onClick={() => void loadDashboard({ mounted: true })}>Yenile</button></div>}
          {actionMessage && <div className="api-alert success" role="status"><strong>İşlem tamam</strong><span>{actionMessage}</span><button type="button" onClick={() => setActionMessage(null)}>Kapat</button></div>}
          {actionError && <div className="api-alert error" role="alert"><strong>İşlem başarısız</strong><span>{actionError}</span><button type="button" onClick={() => setActionError(null)}>Kapat</button></div>}

          <section className="metric-grid" aria-label="Özet metrikler">
            <MetricCard title="Toplam kullanıcı" value={loading ? "—" : formatNumber(overview.users.total)} caption="kayıtlı topluluk üyesi" icon="users" tone="wine" footer={`+${formatNumber(overview.users.newThisWeek)} bu hafta`} />
            <MetricCard title="Açık şikâyetler" value={loading ? "—" : formatNumber(overview.reports.open)} caption={`${formatNumber(overview.reports.urgent)} yüksek öncelikli`} icon="flag" tone="amber" footer={`${formatNumber(overview.reports.resolvedToday)} bugün çözüldü`} />
            <MetricCard title="İçerik inceleme" value={loading ? "—" : formatNumber(overview.content.pendingReview)} caption="işlem bekleyen içerik" icon="layers" tone="blue" footer={`${formatNumber(overview.content.appeals)} itiraz bekliyor`} />
            <MetricCard title="Mesh sağlığı" value={loading ? "—" : meshSummary} caption="node erişilebilir" icon="pulse" tone="green" footer={`${formatNumber(overview.mesh.averageLatencyMs)} ms ort. gecikme`} />
          </section>

          <section className="main-grid">
            <article className="panel activity-panel"><div className="panel-heading"><div><p className="eyebrow">OPERASYON AKIŞI</p><h2>Son aktiviteler</h2></div><a className="text-button" href="#sikayetler">Tümünü gör <span aria-hidden="true">→</span></a></div><div className="activity-list">{overview.activity.length === 0 ? <div className="empty-state"><span className="empty-symbol" aria-hidden="true">◌</span><strong>{loading ? "Aktiviteler yükleniyor" : "Görüntülenecek yeni aktivite yok"}</strong><span>Canlı API bağlantısı kurulduğunda olaylar burada listelenir.</span></div> : overview.activity.map((event) => <div className="activity-row" key={event.id}><span className={`activity-icon ${event.kind}`}><Icon name={event.kind === "report" ? "flag" : event.kind === "mesh" ? "pulse" : event.kind === "user" ? "users" : "layers"} /></span><div><strong>{event.title}</strong><p>{event.detail}</p></div><time dateTime={event.occurredAt}>{relativeTime(event.occurredAt)}</time></div>)}</div></article>
            <article className="panel health-panel"><div className="panel-heading"><div><p className="eyebrow">ALTYAPI</p><h2>Mesh sağlığı</h2></div><HealthPill state={overview.mesh.state} /></div><div className="health-visual"><div className={`health-ring ${overview.mesh.state}`}><strong>{overview.mesh.totalNodes ? Math.round((overview.mesh.healthyNodes / overview.mesh.totalNodes) * 100) : 0}%</strong><span>erişilebilir</span></div><div className="health-details"><div><span>Aktif node</span><strong>{meshSummary}</strong></div><div><span>Son senkronizasyon</span><strong>{formatTime(overview.mesh.lastSyncAt)}</strong></div><div><span>Ortalama gecikme</span><strong>{formatNumber(overview.mesh.averageLatencyMs)} ms</strong></div></div></div><div className="node-bars"><div className="node-bar-label"><span>Node kullanılabilirliği</span><strong>{overview.mesh.healthyNodes} / {overview.mesh.totalNodes}</strong></div><div className="progress-track" role="progressbar" aria-valuemin={0} aria-valuemax={overview.mesh.totalNodes} aria-valuenow={overview.mesh.healthyNodes} aria-label="Node kullanılabilirliği"><span style={{ width: `${overview.mesh.totalNodes ? (overview.mesh.healthyNodes / overview.mesh.totalNodes) * 100 : 0}%` }} /></div></div><div className="mesh-actions"><button type="button" className="outline-button" disabled={meshRefreshing} onClick={() => void handleMeshRefresh()}>{meshRefreshing ? "Yenileniyor…" : "Durumu yenile"}</button><a className="outline-button" href="#sunucular">Sunucu ayrıntıları <span aria-hidden="true">→</span></a></div></article>
          </section>

          <section className="bottom-grid"><article className="panel quick-panel"><div className="panel-heading"><div><p className="eyebrow">HIZLI GÖRÜNÜM</p><h2>Bugünün özeti</h2></div><span className="date-badge">{shortDateLabel}</span></div><div className="quick-list"><div><span className="quick-icon green" aria-hidden="true">✓</span><span>Çözülen şikâyetler</span><strong>{formatNumber(overview.reports.resolvedToday)}</strong></div><div><span className="quick-icon blue" aria-hidden="true">↗</span><span>Aktif kullanıcı (24 sa)</span><strong>{formatNumber(overview.users.active24h)}</strong></div><div><span className="quick-icon amber" aria-hidden="true">!</span><span>Kaldırılan içerik</span><strong>{formatNumber(overview.content.removedToday)}</strong></div><div><span className="quick-icon wine" aria-hidden="true">◷</span><span>Ort. yanıt süresi</span><strong>{formatNumber(overview.reports.medianResponseMinutes)} dk</strong></div></div></article><article className="panel security-panel" id="guvenlik"><div className="panel-heading"><div><p className="eyebrow">GÜVENLİK MERKEZİ</p><h2>Kontrol noktaları</h2></div><span className="security-score">{securityScore}</span></div><div className="security-list">{adminSecurityNotes.map((note) => <div className="security-row" key={note.title} title={note.description}><span className={`security-status ${note.tone}`} aria-hidden="true" /> <span>{note.title}</span><small>{note.tone === "good" ? "Etkin" : "İncele"}</small></div>)}</div></article></section>

          <section className="main-grid" aria-label="Moderasyon kuyrukları">
            <article className="panel" id="kullanicilar">
              <div className="panel-heading"><div><p className="eyebrow">MODERASYON</p><h2>Son kullanıcılar</h2></div><span className="date-badge">{formatNumber(users.length)}</span></div>
              <div className="table-tools">
                <input type="search" placeholder="Ad veya e-posta ara…" aria-label="Kullanıcı ara" value={userFilter} onChange={(event) => setUserFilter(event.target.value)} />
                <select aria-label="Liste boyutu" value={userLimit} onChange={(event) => void handleUserLimit(Number(event.target.value))}>
                  <option value={20}>20</option>
                  <option value={50}>50</option>
                  <option value={100}>100</option>
                </select>
              </div>
              {filteredUsers.length === 0 ? (
                <div className="empty-state"><span className="empty-symbol" aria-hidden="true">◌</span><strong>{loading ? "Kullanıcılar yükleniyor" : userFilter ? "Aramaya uyan kullanıcı yok" : "Kullanıcı bulunamadı"}</strong><span>API bağlantısı kurulduğunda liste burada görünür.</span></div>
              ) : (
                <div className="table-wrap"><table className="admin-table"><thead><tr><th scope="col">Kullanıcı</th><th scope="col">E-posta</th><th scope="col">Kayıt</th><th scope="col"><span className="sr-only">İşlem</span></th></tr></thead><tbody>
                  {filteredUsers.map((user) => (
                    <tr key={user.id}>
                      <td><strong>{user.displayName}</strong><small className="row-sub">{user.id.slice(0, 8)}…</small></td>
                      <td className="masked">{user.email}</td>
                      <td><time dateTime={user.createdAt}>{formatTime(user.createdAt)}</time></td>
                      <td className="row-actions"><button type="button" className="outline-button small" disabled={pendingAction === `suspend:${user.id}`} onClick={() => { setSuspendTarget(user); setSuspendReason("Güvenlik incelemesi"); }}>{pendingAction === `suspend:${user.id}` ? "İşleniyor…" : "Askıya al"}</button></td>
                    </tr>
                  ))}
                </tbody></table></div>
              )}
            </article>
            <article className="panel" id="sikayetler">
              <div className="panel-heading"><div><p className="eyebrow">GÜVENLİK KUYRUĞU</p><h2>Açık şikâyetler</h2></div><span className="date-badge">{formatNumber(reports.length)}</span></div>
              <div className="table-tools">
                <select aria-label="Durum filtresi" value={reportFilter} onChange={(event) => setReportFilter(event.target.value as "all" | "OPEN" | "REVIEWING")}>
                  <option value="all">Tümü</option>
                  <option value="OPEN">Açık</option>
                  <option value="REVIEWING">İnceleniyor</option>
                </select>
              </div>
              {filteredReports.length === 0 ? (
                <div className="empty-state"><span className="empty-symbol" aria-hidden="true">◌</span><strong>{loading ? "Şikâyetler yükleniyor" : "Bekleyen şikâyet yok"}</strong><span>Yeni raporlar moderasyon kuyruğuna düşer.</span></div>
              ) : (
                <div className="table-wrap"><table className="admin-table"><thead><tr><th scope="col">Neden</th><th scope="col">Durum</th><th scope="col">Zaman</th><th scope="col"><span className="sr-only">İşlem</span></th></tr></thead><tbody>
                  {filteredReports.map((report) => (
                    <tr key={report.id}>
                      <td><strong>{report.reason}</strong><small className="row-sub">{report.id.slice(0, 8)}…</small></td>
                      <td><span className={`status-badge ${report.status}`}>{report.status === "OPEN" ? "Açık" : report.status === "REVIEWING" ? "İnceleniyor" : report.status}</span></td>
                      <td><time dateTime={report.createdAt}>{relativeTime(report.createdAt)}</time></td>
                      <td className="row-actions">
                        <button type="button" className="outline-button small" disabled={pendingAction === `report:${report.id}`} onClick={() => void handleResolve(report.id, "dismiss")}>Kapat</button>
                        <button type="button" className="outline-button small" disabled={pendingAction === `report:${report.id}`} onClick={() => void handleResolve(report.id, "remove")}>Kaldır</button>
                        <button type="button" className="outline-button small danger" disabled={pendingAction === `report:${report.id}`} onClick={() => void handleResolve(report.id, "suspend")}>Askıya al</button>
                      </td>
                    </tr>
                  ))}
                </tbody></table></div>
              )}
            </article>
          </section>

          <section aria-label="Destek talepleri">
            <article className="panel" id="destek">
              <div className="panel-heading"><div><p className="eyebrow">DESTEK MASASI</p><h2>Kullanıcı talepleri</h2></div><span className="date-badge">{formatNumber(tickets.length)}</span></div>
              {tickets.length === 0 ? (
                <div className="empty-state"><span className="empty-symbol" aria-hidden="true">◌</span><strong>{loading ? "Talepler yükleniyor" : "Bekleyen talep yok"}</strong><span>Kullanıcılar uygulamadan yazınca burada görünür.</span></div>
              ) : (
                <div className="table-wrap"><table className="admin-table"><thead><tr><th scope="col">Konu</th><th scope="col">Kullanıcı</th><th scope="col">Durum</th><th scope="col">Zaman</th><th scope="col"><span className="sr-only">İşlem</span></th></tr></thead><tbody>
                  {tickets.map((ticket) => (
                    <tr key={ticket.id}>
                      <td><strong>{ticket.subject}</strong><small className="row-sub">{ticket.body.slice(0, 80)}{ticket.body.length > 80 ? "…" : ""}</small></td>
                      <td>{ticket.user?.displayName ?? "—"}</td>
                      <td><span className={`status-badge ${ticket.status === "OPEN" ? "OPEN" : "REVIEWING"}`}>{ticket.status === "OPEN" ? "Açık" : ticket.status === "ANSWERED" ? "Yanıtlandı" : ticket.status}</span></td>
                      <td><time dateTime={ticket.createdAt}>{relativeTime(ticket.createdAt)}</time></td>
                      <td className="row-actions">
                        <button type="button" className="outline-button small" disabled={pendingAction === `ticket:${ticket.id}`} onClick={() => { setReplyTarget(ticket); setReplyText(ticket.reply ?? ""); }}>Yanıtla</button>
                        <button type="button" className="outline-button small" disabled={pendingAction === `ticket:${ticket.id}`} onClick={() => void handleCloseTicket(ticket.id)}>Kapat</button>
                      </td>
                    </tr>
                  ))}
                </tbody></table></div>
              )}
            </article>
          </section>

          <section aria-label="Sunucu yönetimi">
            <article className="panel" id="sunucular">
              <div className="panel-heading"><div><p className="eyebrow">ALTYAPI</p><h2>Sunucular</h2></div><span className="date-badge">{formatNumber(edges.length)}</span></div>
              <p className="panel-note">Yeni yan sunucuyu buradan ekleyin. Oluşan <strong>katılım anahtarını</strong> yan sunucunun <code>EDGE_JOIN_TOKEN</code> değerine yazıp yeniden başlatın; nabız düşünce çevrimiçi görünür.</p>
              <form className="edge-form" onSubmit={(event) => void handleCreateEdge(event)}>
                <label>Sunucu adı<input value={edgeName} onChange={(event) => setEdgeName(event.target.value)} placeholder="yan-1" maxLength={80} required /></label>
                <label>Mesh adresi<input value={edgeHost} onChange={(event) => setEdgeHost(event.target.value)} placeholder="10.0.0.5 veya edge.ornek.net" maxLength={255} required /></label>
                <label>Mesh portu<input value={edgePort} onChange={(event) => setEdgePort(event.target.value)} placeholder="25763" inputMode="numeric" required /></label>
                <button type="submit" className="outline-button small" disabled={pendingAction === "edge:create"}>{pendingAction === "edge:create" ? "Ekleniyor…" : "Sunucu ekle"}</button>
              </form>
              {createdEdge && (
                <div className="api-alert success" role="status">
                  <strong>Katılım anahtarı (tek seferlik gösterim)</strong>
                  <span><code className="token">{createdEdge.joinToken}</code></span>
                  <button type="button" onClick={() => void handleCopyToken()}>{copied ? "Kopyalandı ✓" : "Kopyala"}</button>
                  <button type="button" onClick={() => setCreatedEdge(null)}>Kapat</button>
                </div>
              )}
              {edges.length === 0 ? (
                <div className="empty-state"><span className="empty-symbol" aria-hidden="true">◌</span><strong>{loading ? "Sunucular yükleniyor" : "Kayıtlı yan sunucu yok"}</strong><span>Yukarıdaki formla ilk sunucuyu ekleyin.</span></div>
              ) : (
                <div className="table-wrap"><table className="admin-table"><thead><tr><th scope="col">Sunucu</th><th scope="col">Mesh adresi</th><th scope="col">Durum</th><th scope="col">Son nabız</th><th scope="col"><span className="sr-only">İşlem</span></th></tr></thead><tbody>
                  {edges.map((edge) => (
                    <tr key={edge.id}>
                      <td><strong>{edge.name}</strong><small className="row-sub">{edge.id.slice(0, 8)}…</small></td>
                      <td className="masked">{edge.meshHost}:{edge.meshPort}</td>
                      <td><HealthPill state={edge.status === "online" ? "healthy" : edge.status === "pending" ? "degraded" : "offline"} /></td>
                      <td>{edge.lastSeenAt ? <time dateTime={edge.lastSeenAt}>{relativeTime(edge.lastSeenAt)}</time> : "—"}</td>
                      <td className="row-actions"><button type="button" className="outline-button small danger" disabled={pendingAction === `edge:${edge.id}`} onClick={() => setDeleteTarget(edge)}>Sil</button></td>
                    </tr>
                  ))}
                </tbody></table></div>
              )}
            </article>
          </section>
          <footer className="page-footer"><span>Can Meydanı Operasyon Merkezi · v0.4</span><span>Veriler amaç sınırlı ve maskeli gösterilir · KVKK</span></footer>
        </div>
      </main>
      {suspendTarget && (
        <div className="modal-backdrop" role="dialog" aria-modal="true" aria-label="Kullanıcıyı askıya al">
          <div className="modal">
            <h3>{suspendTarget.displayName} askıya alınsın mı?</h3>
            <p>Hesap kapatılır, oturumları düşer. İşlem denetim izine yazılır.</p>
            <label>Gerekçe<input value={suspendReason} onChange={(event) => setSuspendReason(event.target.value)} maxLength={2000} placeholder="En az 3 karakter" /></label>
            <div className="modal-actions">
              <button type="button" className="outline-button" onClick={() => setSuspendTarget(null)}>Vazgeç</button>
              <button type="button" className="outline-button danger" disabled={pendingAction === `suspend:${suspendTarget.id}`} onClick={() => void handleSuspend(suspendTarget.id)}>Askıya al</button>
            </div>
          </div>
        </div>
      )}
      {deleteTarget && (
        <div className="modal-backdrop" role="dialog" aria-modal="true" aria-label="Sunucuyu sil">
          <div className="modal">
            <h3>{deleteTarget.name} silinsin mi?</h3>
            <p>Nabız durunca çevrimdışı görünür. Kayıt kalıcı olarak silinir.</p>
            <div className="modal-actions">
              <button type="button" className="outline-button" onClick={() => setDeleteTarget(null)}>Vazgeç</button>
              <button type="button" className="outline-button danger" disabled={pendingAction === `edge:${deleteTarget.id}`} onClick={() => void handleDeleteEdge(deleteTarget.id)}>Sil</button>
            </div>
          </div>
        </div>
      )}
      {replyTarget && (
        <div className="modal-backdrop" role="dialog" aria-modal="true" aria-label="Talebi yanıtla">
          <div className="modal">
            <h3>{replyTarget.subject}</h3>
            <p>{replyTarget.body}</p>
            <label>Yanıtınız<textarea value={replyText} onChange={(event) => setReplyText(event.target.value)} rows={4} maxLength={2000} placeholder="Kullanıcıya yanıt yazın…" /></label>
            <div className="modal-actions">
              <button type="button" className="outline-button" onClick={() => setReplyTarget(null)}>Vazgeç</button>
              <button type="button" className="outline-button" disabled={pendingAction === `ticket:${replyTarget.id}`} onClick={() => void handleReplyTicket()}>Gönder</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
