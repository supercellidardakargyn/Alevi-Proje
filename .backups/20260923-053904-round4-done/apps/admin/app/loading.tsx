export default function Loading() {
  return (
    <div className="admin-shell">
      <main className="main-content">
        <div className="content-wrap">
          <div className="empty-state" role="status" aria-live="polite">
            <span className="empty-symbol" aria-hidden="true">◌</span>
            <strong>Operasyon merkezi yükleniyor</strong>
            <span>Canlı veriler bağlanıyor…</span>
          </div>
        </div>
      </main>
    </div>
  );
}
