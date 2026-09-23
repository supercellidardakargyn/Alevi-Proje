#!/usr/bin/env bash
set -Eeuo pipefail

# iOS builds require macOS/Xcode and are intentionally refused elsewhere.
if [[ "$(uname -s)" != "Darwin" ]]; then
  printf 'HATA: iOS archive/IPA yalnız macOS + Xcode üzerinde üretilebilir.\n' >&2
  exit 1
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
CLIENT_DIR="${CLIENT_DIR:-$ROOT/apps/client}"
OUTPUT_DIR="${OUTPUT_DIR:-$ROOT/dist/ios}"
CONFIGURATION="Release"
ALLOW_UNSIGNED=false
SKIP_PUB_GET=false
EXPORT_OPTIONS=""

fail() { printf 'HATA: %s\n' "$*" >&2; exit 1; }
usage() {
  cat <<'USAGE'
Kullanım:
  ./scripts/build-ios.sh [--configuration Release] [--export-options PATH] [--allow-unsigned]
USAGE
}
while (($#)); do
  case "$1" in
    --configuration) [[ $# -ge 2 ]] || fail "--configuration değer bekler"; CONFIGURATION="$2"; shift 2 ;;
    --client-dir) [[ $# -ge 2 ]] || fail "--client-dir değer bekler"; CLIENT_DIR="$2"; shift 2 ;;
    --output-dir) [[ $# -ge 2 ]] || fail "--output-dir değer bekler"; OUTPUT_DIR="$2"; shift 2 ;;
    --export-options) [[ $# -ge 2 ]] || fail "--export-options değer bekler"; EXPORT_OPTIONS="$2"; shift 2 ;;
    --allow-unsigned) ALLOW_UNSIGNED=true; shift ;;
    --skip-pub-get) SKIP_PUB_GET=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) fail "Bilinmeyen seçenek: $1" ;;
  esac
done

command -v flutter >/dev/null 2>&1 || fail 'Flutter bulunamadı.'
command -v xcodebuild >/dev/null 2>&1 || fail 'Xcode/xcodebuild bulunamadı.'
[[ -f "$CLIENT_DIR/pubspec.yaml" ]] || fail "Flutter client bulunamadı: $CLIENT_DIR/pubspec.yaml"
[[ -d "$CLIENT_DIR/ios" ]] || fail "iOS projesi bulunamadı: $CLIENT_DIR/ios"
if [[ "$ALLOW_UNSIGNED" != true && ! -f "$CLIENT_DIR/ios/ExportOptions.plist" && -z "$EXPORT_OPTIONS" ]]; then
  fail 'İmzalı IPA için ios/ExportOptions.plist veya --export-options gerekir; sahte imza üretilmez.'
fi

if [[ "$SKIP_PUB_GET" != true ]]; then (cd "$CLIENT_DIR" && flutter pub get); fi
build_args=(build ipa --release)
if [[ -n "$EXPORT_OPTIONS" ]]; then build_args+=(--export-options-plist "$EXPORT_OPTIONS"); elif [[ -f "$CLIENT_DIR/ios/ExportOptions.plist" ]]; then build_args+=(--export-options-plist ios/ExportOptions.plist); fi
(cd "$CLIENT_DIR" && flutter "${build_args[@]}")

shopt -s nullglob
ipas=("$CLIENT_DIR"/build/ios/ipa/*.ipa)
(( ${#ipas[@]} == 1 )) || fail 'Tek ve gerçek IPA çıktısı bulunamadı.'
[[ -s "${ipas[0]}" ]] || fail 'IPA boş; sahte artifact kabul edilmez.'
mkdir -p "$OUTPUT_DIR"
destination="$OUTPUT_DIR/alevi-ios.ipa"
cp "${ipas[0]}" "$destination"
shasum -a 256 "$destination" > "$destination.sha256"
printf 'iOS IPA hazır: %s\n' "$destination"
