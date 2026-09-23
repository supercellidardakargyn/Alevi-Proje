#!/usr/bin/env bash
set -Eeuo pipefail

# Mesh init wrapper. Certificate generation belongs to the API mesh CLI/PKI,
# not to this wrapper; no fake CA or placeholder certificate is generated here.

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
API_DIR="${ALEVI_API_DIR:-$PROJECT_ROOT/services/api}"
CLI_PATH="${ALEVI_MESH_CLI:-$API_DIR/dist/cli.js}"
NODE_BIN="${NODE_BIN:-node}"
NODE_NAME=""
OUTPUT_DIR=""
BOOTSTRAP_ADDRESS=""

fail() { printf 'HATA: %s\n' "$*" >&2; exit 1; }
usage() {
  cat <<'USAGE'
Kullanım:
  ./scripts/mesh-init.sh --node-name NAME --output-dir PATH [--bootstrap ADDRESS]

Environment:
  ALEVI_API_DIR    API release/source dizini
  ALEVI_MESH_CLI   mesh CLI JavaScript dosyası (varsayılan: services/api/dist/cli.js)
  NODE_BIN         Node binary (varsayılan: node)
USAGE
}
while (($#)); do
  case "$1" in
    --node-name) [[ $# -ge 2 ]] || fail "--node-name değer bekler"; NODE_NAME="$2"; shift 2 ;;
    --output-dir) [[ $# -ge 2 ]] || fail "--output-dir değer bekler"; OUTPUT_DIR="$2"; shift 2 ;;
    --bootstrap) [[ $# -ge 2 ]] || fail "--bootstrap değer bekler"; BOOTSTRAP_ADDRESS="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) fail "Bilinmeyen seçenek: $1" ;;
  esac
done
[[ -n "$NODE_NAME" ]] || fail "--node-name zorunludur"
[[ -n "$OUTPUT_DIR" ]] || fail "--output-dir zorunludur"
[[ "$NODE_NAME" =~ ^[A-Za-z0-9][A-Za-z0-9._-]{0,62}$ ]] || fail "Geçersiz node adı"
command -v "$NODE_BIN" >/dev/null 2>&1 || fail "Node.js bulunamadı: $NODE_BIN"
[[ -f "$CLI_PATH" ]] || fail "Mesh CLI bulunamadı: $CLI_PATH; sahte sertifika üretilmeyecek."

umask 077
mkdir -p "$OUTPUT_DIR"
chmod 0700 "$OUTPUT_DIR"
args=("$CLI_PATH" mesh init --node-name "$NODE_NAME" --output-dir "$OUTPUT_DIR")
[[ -n "$BOOTSTRAP_ADDRESS" ]] && args+=(--bootstrap "$BOOTSTRAP_ADDRESS")

printf 'Mesh init başlatılıyor: node=%s output=%s\n' "$NODE_NAME" "$OUTPUT_DIR"
"$NODE_BIN" "${args[@]}"

[[ -s "$OUTPUT_DIR/node-id" || -s "$OUTPUT_DIR/node-id.txt" || -s "$OUTPUT_DIR/node.json" ]] || fail "Mesh CLI node kimliği üretmedi; init başarısız."
printf 'Mesh init tamamlandı. Secret/private key içerikleri gösterilmedi.\n'
