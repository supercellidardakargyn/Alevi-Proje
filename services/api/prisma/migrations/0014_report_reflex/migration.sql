-- Reflex moderasyon: Jev degerlendirme sonuclari rapor satirinda saklanir
ALTER TABLE "reports" ADD COLUMN "severity" INTEGER;
ALTER TABLE "reports" ADD COLUMN "eval_category" VARCHAR(32);
ALTER TABLE "reports" ADD COLUMN "auto_action" VARCHAR(32);

CREATE INDEX "reports_status_severity_idx" ON "reports" ("status", "severity");
