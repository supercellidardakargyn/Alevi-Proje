# Alevi Connect

Alevi kültürüne, inancına veya değerlerine ilgi duyan yetişkinler için güvenli sosyal bağlantı ve topluluk uygulaması. Ürün; romantik tanışmanın yanında arkadaşlık, sohbet, kültürel çevre ve etkinlik keşfini destekler. Hiçbir kullanıcı Alevi olduğunu kanıtlamaya veya açıklamaya zorlanmaz.

Bu depo üç hedefi aynı anda taşır:

> Not: Apple IPA üretimi macOS + Xcode ister; Microsoft Store ve Android imzalı paketleri de ilgili geliştirici hesapları/sertifikaları olmadan tamamlanmış sayılmaz. Bu gereksinimler CI'da secret preflight ile zorunlu tutulur.

- **Flutter istemci:** Android, iOS ve Windows için ortak uygulama. Native generated platform klasörleri bu Windows çalışma ortamında elle uydurulmadı; mağaza kaynakları/CI gerçek Flutter toolchain'inde üretilecek.
- **Node.js API:** PostgreSQL, Redis, REST/WebSocket ve yönetim/moderasyon sınırları.
- **Güvenli mesh:** 5–10 bilgisayarda provision edilmiş Node.js edge sunucularının TLS 1.3 mTLS ile otomatik peer bağlantısı. İlk join işlemi tek kullanımlık davet ve sertifika provision'ı gerektirir; yeni bilgisayar yalnızca aynı servisi başlatınca güvenilir kabul edilmez.

## Güvenlik gerçeği

Hiçbir yazılım mutlak güvenlik garantisi veremez. Bu proje uygulanabilir güvenlik hedefleri uygular: HTTPS/WSS, node-node mTLS, Argon2id parola hash'i, refresh token rotasyonu, rate limit, alan bazlı şifreleme, signed media URL'leri, audit logları, varsayılan gizli hassas alanlar ve KVKK veri talepleri. Trafik zamanı/ boyutu gibi bazı metadata'lar şifreleme altında da görülebilir.

Dini veya kültürel bağ bilgileri hassas olabilir. Bu bilgiler isteğe bağlıdır, varsayılan olarak gizlidir ve keşfetme/filtreleme sıralamasına girmez. Alevilik kimlik doğrulaması yapılmaz.

## Hızlı başlangıç

### Gereksinimler

- Node.js 20+ ve pnpm 9+
- Docker Desktop veya Linux Docker Engine + Compose v2
- Flutter stable (Android/iOS/Windows hedefleri etkin)
- Üretim için: Android keystore, Apple Developer/macOS runner, Microsoft Partner Center bilgileri

### API ve tek sunucu

```powershell
Copy-Item .env.example .env
# .env içindeki tüm change-me/replace-me değerlerini üretim secret'larıyla değiştirin.
docker compose -f deploy/docker-compose.single.yml up -d --build
```

API release dependency lockfile'ları `services/api/package-lock.json` ve ilgili shared package klasörlerindedir. CI `npm ci`/kilitli kurulum kullanır; lockfile güncellemeden production dependency sürümü değiştirmeyin.

Windows kullanıcı toolchain'i proje dışındaki `C:\Users\PC\Tools` altına kurulur. Kalıcı kullanıcı PATH değişkenine Node.js, Git, JDK, Flutter ve Android SDK yolları eklenmiştir. Yönetici hakları gerektirmediği için kurulum kullanıcı kapsamındadır.

Health:

- `GET http://localhost:8080/health/live`
- `GET http://localhost:8080/health/ready`
- `GET http://localhost:8080/health/mesh`

Yerel geliştirmede TLS reverse proxy kullanın; public ortamda API'yi doğrudan HTTP ile açmayın.

### Mesh node ekleme

İlk sunucuda:

```powershell
pnpm install
pnpm mesh:init
```

Komut tek kullanımlık, süreli join daveti üretir. Yeni bilgisayarda davet token'ını güvenli kanaldan iletin:

```powershell
$env:MESH_JOIN_TOKEN = "tek-kullanimlik-token"
pnpm mesh:join
```

Yeni node yalnız provision edilmiş sertifikayla başlatılabilir. LAN için mDNS/seed peer; farklı ağlar için WireGuard/Tailscale gibi özel overlay gerekir. İnternete ham mesh portu açmayın.

### İstemci

```powershell
cd apps/client
flutter pub get
flutter analyze
flutter test
flutter run -d windows
```

API adresini `--dart-define=API_BASE_URL=https://...` ile verin.

## Mağaza paketleri

Kaynak ve CI akışları hazırlandı; gerçek mağaza imzalama secret'ları olmadan üretim paketi üretildiği iddia edilmez.

```powershell
# Android: keystore secret'ları ayarlıysa
./scripts/build-android.ps1 -Flavor release

# Windows: Visual Studio + Windows SDK + msix gerektirir
./scripts/build-windows.ps1 -Configuration release
```

Apple IPA/Archive yalnız macOS + Xcode üzerinde veya GitHub Actions macOS runner'da üretilebilir:

```bash
./scripts/build-ios.sh
```

Detaylar:

- `docs/install.md`
- `docs/mesh-deployment.md`
- `docs/store-release.md`
- `docs/security-model.md`
- `docs/kvkk-data-map.md`
- `docs/moderation-policy.md`

## MVP kapsamı

- Kayıt/giriş, 18+ kontrolü ve consent
- Profil ve alan bazlı görünürlük
- Kart tabanlı keşfet, filtre, like/pass ve eşleşme
- Eşleşme sonrası mesajlaşma
- Engelleme/şikayet
- Basit topluluk akışı ve moderasyon
- Admin paneli, audit ve mesh sağlık görünümü
- Etkinlik ve premium için domain/feature-flag sınırları

## Doğrulama durumu

Bu Windows makinesinde doğrulananlar:

- Node API: Prisma client üretimi, TypeScript typecheck ve production compile başarılı. `npm audit` Prisma toolchain içinde üç yüksek önem seviyeli advisory raporluyor; otomatik `--force` güncellemesi major sürüm değişimi olduğu için uygulanmadı.
- Shared TypeScript packages: compile başarılı.
- Admin: TypeScript typecheck, production Next build ve `npm audit --audit-level=high` temiz.
- PowerShell deployment script'leri: parser doğrulaması başarılı.
- Flutter: bu makinede Flutter/Dart kurulu olmadığı için `flutter analyze/test/build` çalıştırılamadı; CI, gerçek Flutter kaynakları/secret'lar yoksa açıkça durur.
- Docker/Compose: bu makinede Docker bulunmadığı için container smoke test çalıştırılamadı.

## Lisans ve operasyon

Bu depo deployment secret'larını, özel anahtarları, keystore'ları veya kullanıcı verisini içermez. Secret'ları CI secret manager, OS credential store veya KMS/Vault üzerinden sağlayın; `.env` dosyasını commit etmeyin.
