#!/usr/bin/env bash
set -Eeuo pipefail

# Mesh join wrapper. The one-time token is never printed by this script.

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
API_DIR="${ALEVI_API_DIR:-$PROJECT_ROOT/services/api}"
CLI_PATH="${ALEVI_MESH_CLI:-$API_DIR/dist/cli.js}"
NODE_BIN="${NODE_BIN:-node}"
TOKEN="${MESH_JOIN_TOKEN:-}"
BOOTSTRAP=""
OUTPUT_DIR=""
NODE_NAME=""

fail() { printf 'HATA: %s\n' "$*" >&2; exit 1; }
usage() {
  cat <<'USAGE'
Kullanım:
  MESH_JOIN_TOKEN='...' ./scripts/mesh-join.sh --bootstrap URL --node-name NAME --output-dir PATH

`--token` desteklenmez; token'ın shell history/process listesine sızmaması için
MESH_JOIN_TOKEN environment değişkenini secret manager'dan enjekte edin.
USAGE
}
while (($#)); do
  case "$1" in
    --bootstrap) [[ $# -ge 2 ]] || fail "--bootstrap değer bekler"; BOOTSTRAP="$2"; shift 2 ;;
    --node-name) [[ $# -ge 2 ]] || fail "--node-name değer bekler"; NODE_NAME="$2"; shift 2 ;;
    --output-dir) [[ $# -ge 2 ]] || fail "--output-dir değer bekler"; OUTPUT_DIR="$2"; shift 2 ;;
    --token) fail "--token kullanmayın; MESH_JOIN_TOKEN environment secret'ı kullanın." ;;
    -h|--help) usage; exit 0 ;;
    *) fail "Bilinmeyen seçenek: $1" ;;
  esac
done
[[ -n "$TOKEN" ]] || fail "MESH_JOIN_TOKEN eksik"
[[ -n "$BOOTSTRAP" ]] || fail "--bootstrap zorunludur"
[[ -n "$NODE_NAME" ]] || fail "--node-name zorunludur"
[[ -n "$OUTPUT_DIR" ]] || fail "--output-dir zorunludur"
[[ "$NODE_NAME" =~ ^[A-Za-z0-9][A-Za-z0-9._-]{0,62}$ ]] || fail "Geçersiz node adı"
command -v "$NODE_BIN" >/dev/null 2>&1 || fail "Node.js bulunamadı: $NODE_BIN"
[[ -f "$CLI_PATH" ]] || fail "Mesh CLI bulunamadı: $CLI_PATH; provision atlanmayacak."

umask 077
mkdir -p "$OUTPUT_DIR"
chmod 0700 "$OUTPUT_DIR"
# The API CLI contract reads the token from stdin; it does not appear in argv.
printf '%s\n' "$TOKEN" | "$NODE_BIN" "$CLI_PATH" mesh join --bootstrap "$BOOTSTRAP" --node-name "$NODE_NAME" --output-dir "$OUTPUT_DIR" --token-stdin
unset TOKEN MESH_JOIN_TOKEN

[[ -s "$OUTPUT_DIR/node-cert.pem" ]] || fail "Join sertifikası üretilmedi; katılım başarısız."
[[ -s "$OUTPUT_DIR/node-key.pem" ]] || fail "Node private key üretilmedi; katılım başarısız."
chmod 0600 "$OUTPUT_DIR/node-key.pem"
printf 'Mesh join tamamlandı: node=%s. Token ve private key gösterilmedi.\n' "$NODE_NAME"
