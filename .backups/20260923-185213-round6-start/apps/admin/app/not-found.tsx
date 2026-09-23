export default function NotFound() {
  return (
    <div className="admin-shell">
      <main className="main-content">
        <div className="content-wrap">
          <div className="empty-state" role="status">
            <span className="empty-symbol" aria-hidden="true">◌</span>
            <strong>Sayfa bulunamadı</strong>
            <span>Aradığınız yönetim bölümü mevcut değil.</span>
          </div>
        </div>
      </main>
    </div>
  );
}
