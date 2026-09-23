# Sunucu, mesh ve platform helper'ları

Bu script'ler gerçek toolchain veya API mesh CLI yoksa başarılı görünmez; placeholder sertifika, sahte release veya boş artifact üretmez.

## Sunucu

- `install-server.sh`: Linux Node.js release dizinini doğrular, systemd unit'i hardening ile kurar, servisi başlatır ve `/health/live` kontrol eder.
- `install-server.ps1`: Windows Node.js release dizinini doğrular, ACL ve Windows service provisioning'i çalıştırır, health kontrol eder.

## Mesh

- `mesh-init.sh` / `mesh-init.ps1`: gerçek API `dist/cli.js mesh init` komutunu çağırır. CA/secret üretimini wrapper taklit etmez.
- `mesh-join.sh` / `mesh-join.ps1`: `MESH_JOIN_TOKEN` secret'ını argv'ye koymadan stdin üzerinden gerçek mesh CLI'ye verir. Token loglanmaz; provision ve node certificate dosyaları doğrulanır.

## Platform build

- `build-android.ps1`: `flutter build apk/appbundle` ve gerçek çıktı checksum'ı.
- `build-ios.sh`: yalnız macOS/Xcode üzerinde `flutter build ipa`; Windows/Linux'ta bilinçli olarak fail.
- `build-windows.ps1`: `flutter build windows`, opsiyonel `msix` ve checksum.

Mağaza release imzası için CI workflow preflight'ları ayrıca zorunludur. Secret olmadan `--allow-unsigned` yalnız yerel/dev doğrulama içindir; signed artifact iddiasında bulunmaz.
