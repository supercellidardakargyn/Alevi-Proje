# Alevi Connect API — Pterodactyl + canmeydani.com.tr kurulumu

## 1. Gerekenler (panelde yoksa önce bunları hazırla)

- **PostgreSQL:** Pterodactyl'in MySQL'i OLMAZ (şema Postgres'e özel).
  Ücretsiz/ucuz seçenek: Supabase veya Neon'dan free Postgres aç,
  connection string'i kopyala. Örnek:
  `postgresql://postgres:xxxxx@db.xxx.supabase.co:5432/postgres?schema=public`
- **Secret üret** (kendi bilgisayarında bir kez çalıştır):
  `openssl rand -hex 32` → bunu 3 kez çalıştır:
  JWT_ACCESS_SECRET, JWT_REFRESH_SECRET, SENSITIVE_DATA_KEY.
  Üçü de birbirinden farklı olsun. Yedeğini sakla.

## 2. Egg'i panele yükle

1. `panel.saganetwork.net` → **Admin → Nests → Import Egg**
2. `deploy/pterodactyl/alevi-api-egg.json` dosyasını seç, içe aktar.
3. Bir **Server** oluştur: Nest = egg'in nest'i, Egg = **Alevi Connect API**,
   512 MB RAM / 1 CPU / 1 GB disk yeterli (başlangıç).
4. Server **Startup / Variables** sekmesinde doldur:
   DATABASE_URL, REDIS_URL (boş bırakılabilir anlayışıyla default kalabilir),
   CORS_ORIGINS=`https://canmeydani.com.tr`, 3 secret, issuer/audience default.

## 3. Dosyaları yükle

Server **Files** sekmesine repo içeriğini yükle: `packages/` ve `services/`
klasörleri container kökünde olacak şekilde (zip yükleyip Unarchive en kolayı).
`server/`, `apps/`, `dist/` klasörlerini YÜKLEME (gereksiz).

## 4. Kur ve başlat

1. **Settings → Reinstall Server** → kurulum scripti derler
   (`packages/*` build + `services/api` npm ci + build).
2. **Console** → `API listening on 0.0.0.0:<port>` görülmeli.
3. Test: `http://NODE_IP:ALLOCATION_PORT/health/live` → `{"status":"ok"}`.

## 5. Domain bağlama (canmeydani.com.tr)

Pterodactyl portu doğrudan 443/SSL vermez. İki yol:

**A — Basit (önerilen):** Cloudflare'de `api.canmeydani.com.tr` → A kaydı → node IP
(DNS only, proxy kapalı). Uygulama `http://api.canmeydani.com.tr:PORT` ile çalışır.
Flutter'da `API_BASE_URL` bunu gösterir.

**B — 443/SSL:** Node önüne nginx reverse proxy
(`api.canmeydani.com.tr` → `127.0.0.1:ALLOCATION_PORT`, certbot ile SSL).
Gerektiğinde `deploy/` altına nginx örneği eklenir.

Not: Admin paneli (Next) bu egg'e dahil değil; API canlıya geçince
onu ayrı Node egg veya statik host olarak ekleriz.
