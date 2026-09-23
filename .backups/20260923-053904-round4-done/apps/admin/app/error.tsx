"use client";

export default function Error({
  error,
  reset
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  return (
    <div className="admin-shell">
      <main className="main-content">
        <div className="content-wrap">
          <div className="api-alert error" role="alert">
            <strong>Panel yüklenemedi</strong>
            <span>{error.message || "Beklenmeyen bir hata oluştu."}</span>
            <button type="button" onClick={() => reset()}>Tekrar dene</button>
          </div>
        </div>
      </main>
    </div>
  );
}
