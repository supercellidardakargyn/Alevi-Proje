#!/bin/bash
# Alevi otomatik guncelleyici. Kullanim:
#   ./scripts/update.sh            -> bir kez guncelle
#   cron (10 dakikada bir kontrol):
#   */10 * * * * cd /opt/alevi-main && ./scripts/update.sh >> update.log 2>&1
#
# .env dosyasina DOKUNMAZ (repoda yok, yerinde kalir).
set -e
cd "$(dirname "$0")/.."

if [ ! -d .git ]; then
  echo "[guncelle] .git yok: bu klasor git deposu degil. Once repo klonlanmali."
  echo "Ornek: git clone <REPO-URL> alevi-main && cp yedek-.env alevi-main/.env"
  exit 1
fi

BEFORE=$(git rev-parse HEAD)
git pull --ff-only origin "$(git branch --show-current)"
AFTER=$(git rev-parse HEAD)

if [ "$BEFORE" = "$AFTER" ]; then
  echo "[guncelle] degisiklik yok ($AFTER)."
  exit 0
fi

echo "[guncelle] $BEFORE -> $AFTER, derleniyor..."
npm --prefix packages/config install --no-audit --no-fund
npm --prefix packages/config run build
npm --prefix packages/contracts install --no-audit --no-fund
npm --prefix packages/contracts run build
npm --prefix services/api install --no-audit --no-fund
npm --prefix services/api run build
npm --prefix services/gateway install --omit=dev --no-audit --no-fund
npm --prefix apps/admin install --no-audit --no-fund
npm --prefix apps/admin run build

echo "[guncelle] tamam. Uygulamak icin uygulamayi yeniden baslat (Ctrl+C -> node index.js veya pm2 restart alevi)."
echo "[not] migrationlar acilista otomatik kurulur."
