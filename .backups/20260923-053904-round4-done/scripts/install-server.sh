#!/usr/bin/env bash
set -Eeuo pipefail

# Alevi API Linux provisioning helper.
# This script intentionally does not create secrets or pretend that a service is healthy.

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

RELEASE_DIR="/opt/alevi/api"
SERVICE_NAME="alevi-api"
SERVICE_USER="alevi"
SERVICE_GROUP="alevi"
ENV_FILE="/etc/alevi/alevi-api.env"
HEALTH_URL="http://127.0.0.1:3000/health/live"
SKIP_SERVICE=false

usage() {
  cat <<'USAGE'
Kullanım:
  sudo ./scripts/install-server.sh [seçenekler]

Seçenekler:
  --release-dir PATH     API release dizini (varsayılan: /opt/alevi/api)
  --service-name NAME    systemd servis adı (varsayılan: alevi-api)
  --service-user NAME    servis kullanıcısı (varsayılan: alevi)
  --env-file PATH        environment dosyası (varsayılan: /etc/alevi/alevi-api.env)
  --health-url URL       canlılık kontrolü (varsayılan: http://127.0.0.1:3000/health/live)
  --skip-service         systemd yükleme/restart adımını atla
  -h, --help             yardımı göster
USAGE
}

fail() {
  printf 'HATA: %s\n' "$*" >&2
  exit 1
}

while (($#)); do
  case "$1" in
    --release-dir) [[ $# -ge 2 ]] || fail "--release-dir değer bekler"; RELEASE_DIR="$2"; shift 2 ;;
    --service-name) [[ $# -ge 2 ]] || fail "--service-name değer bekler"; SERVICE_NAME="$2"; shift 2 ;;
    --service-user) [[ $# -ge 2 ]] || fail "--service-user değer bekler"; SERVICE_USER="$2"; SERVICE_GROUP="$2"; shift 2 ;;
    --env-file) [[ $# -ge 2 ]] || fail "--env-file değer bekler"; ENV_FILE="$2"; shift 2 ;;
    --health-url) [[ $# -ge 2 ]] || fail "--health-url değer bekler"; HEALTH_URL="$2"; shift 2 ;;
    --skip-service) SKIP_SERVICE=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) fail "Bilinmeyen seçenek: $1" ;;
  esac
done

[[ "$(id -u)" -eq 0 ]] || fail "Bu script root olarak çalıştırılmalıdır."
command -v systemctl >/dev/null 2>&1 || fail "systemctl bulunamadı; systemd olmayan sistemde çalıştırmayın."
command -v node >/dev/null 2>&1 || fail "Node.js bulunamadı."
command -v curl >/dev/null 2>&1 || fail "curl bulunamadı; health kontrolü yapılamaz."

node_major="$(node --version | sed -E 's/^v([0-9]+).*$/\1/')"
[[ "$node_major" =~ ^[0-9]+$ ]] || fail "Node.js sürümü okunamadı."
(( node_major >= 20 )) || fail "Node.js 20 veya üzeri gerekir (bulunan: $(node --version))."

[[ -d "$RELEASE_DIR" ]] || fail "Release dizini yok: $RELEASE_DIR"
[[ -f "$RELEASE_DIR/package.json" ]] || fail "Release dizininde package.json yok: $RELEASE_DIR"
[[ -f "$RELEASE_DIR/dist/main.js" ]] || fail "Release dizininde dist/main.js yok; sahte servis kurulmayacak."

if ! getent group "$SERVICE_GROUP" >/dev/null 2>&1; then
  groupadd --system "$SERVICE_GROUP"
fi
if ! id "$SERVICE_USER" >/dev/null 2>&1; then
  useradd --system --gid "$SERVICE_GROUP" --home-dir /var/lib/alevi --create-home --shell /usr/sbin/nologin "$SERVICE_USER"
fi

install -d -m 0750 -o root -g "$SERVICE_GROUP" /etc/alevi
install -d -m 0750 -o "$SERVICE_USER" -g "$SERVICE_GROUP" /var/lib/alevi
install -d -m 0750 -o "$SERVICE_USER" -g "$SERVICE_GROUP" /var/log/alevi
chown -R "$SERVICE_USER:$SERVICE_GROUP" "$RELEASE_DIR"
chmod -R u=rwX,g=rX,o= "$RELEASE_DIR"

if [[ ! -e "$ENV_FILE" ]]; then
  install -m 0640 -o root -g "$SERVICE_GROUP" /dev/null "$ENV_FILE"
  cat > "$ENV_FILE" <<'ENV'
# Secret olmayan servis ayarları. Secret'ları burada plaintext tutmayın.
NODE_ENV=production
PORT=3000
# DATABASE_URL, REDIS_URL, TLS ve encryption key referansları secret manager'dan sağlanır.
ENV
  chown root:"$SERVICE_GROUP" "$ENV_FILE"
  chmod 0640 "$ENV_FILE"
fi

UNIT_SOURCE="$PROJECT_ROOT/deploy/systemd/alevi-api.service"
[[ -f "$UNIT_SOURCE" ]] || fail "systemd unit bulunamadı: $UNIT_SOURCE"
UNIT_PATH="/etc/systemd/system/${SERVICE_NAME}.service"
TMP_UNIT="$(mktemp)"
trap 'rm -f "$TMP_UNIT"' EXIT
sed \
  -e "s#__ALEVI_SERVICE_NAME__#${SERVICE_NAME}#g" \
  -e "s#__ALEVI_SERVICE_USER__#${SERVICE_USER}#g" \
  -e "s#__ALEVI_SERVICE_GROUP__#${SERVICE_GROUP}#g" \
  -e "s#__ALEVI_RELEASE_DIR__#${RELEASE_DIR//\/\\}#g" \
  -e "s#__ALEVI_ENV_FILE__#${ENV_FILE//\/\\}#g" \
  "$UNIT_SOURCE" > "$TMP_UNIT"
install -m 0644 -o root -g root "$TMP_UNIT" "$UNIT_PATH"

if [[ "$SKIP_SERVICE" == true ]]; then
  printf 'Kurulum tamamlandı; systemd adımı --skip-service ile atlandı.\n'
  exit 0
fi

systemctl daemon-reload
systemctl enable "$SERVICE_NAME.service"
systemctl restart "$SERVICE_NAME.service"
sleep 2
if ! systemctl is-active --quiet "$SERVICE_NAME.service"; then
  systemctl --no-pager --full status "$SERVICE_NAME.service" || true
  fail "Servis aktif olmadı; health sonucu uydurulmayacak."
fi

if ! curl --fail --silent --show-error --max-time 10 "$HEALTH_URL" >/dev/null; then
  systemctl --no-pager --full status "$SERVICE_NAME.service" || true
  fail "Health kontrolü başarısız: $HEALTH_URL"
fi

printf 'Servis kuruldu ve canlılık kontrolü geçti: %s\n' "$SERVICE_NAME"
