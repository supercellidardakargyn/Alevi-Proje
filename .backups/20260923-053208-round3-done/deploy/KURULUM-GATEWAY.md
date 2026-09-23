# Alevi + sonalis.com.tr — Ana/Yan sunucu kurulumu (tar.gz, ugrasmadan)

## Mimari

```
internet (Cloudflare proxy onerilir)
   │  sadece 25577 (ana) / 25763 (yan mesh)
   ▼
ANA SUNUCU :25577 (Node.js gateway dagitir)
 ├── sonalis.com.tr            → tanıtım sitesi + APK (/indir/alevi.apk)
 ├── api.sonalis.com.tr        → api:3000 (iç ağ, portsuz)
 ├── yonetim.sonalis.com.tr    → admin:3000 (iç ağ, portsuz)
 ├── postgres / redis          (iç ağ, portsuz)
   │  ana → yan: mesh mTLS aramasi (outbound, serbest)
   │  yan → ana: nabiz HTTPS (outbound, serbest)
   ▼
YAN SUNUCU :25763 (sadece mesh mTLS, API ice kapali)
```

Alt sunuculara internetten erisim YOK. Guvenlik duvarinda baska port acma.

## DNS (4 A kaydi, hepsi ANA sunucu IP'sine, Cloudflare'de turuncu bulut ACİK)

| Host                   | Tür |
|------------------------|-----|
| sonalis.com.tr         | A   |
| www.sonalis.com.tr     | A   |
| api.sonalis.com.tr     | A   |
| yonetim.sonalis.com.tr | A   |

Yan sunucuya DNS kaydi GEREKMEZ. Turuncu bulut kapaliysa site duz HTTP
acilir; API yine calisir (uygulama baglanir, tarayici uyarir).

## Ana sunucu (5 dakika)

1. `dist/alevi-main.tar.gz` dosyasini sunucuya at:
   `tar -xzf alevi-main.tar.gz && cd alevi-main`
2. `.env` HAZIR gelir (`deploy/gateway/.env`): secretler uretildi.
   SADECE sunlari doldur (`deploy/gateway/.env` icinde):
   - `SMTP_USER` + `SMTP_PASS`: Gmail adresin + **uygulama şifresi**
     (Google Hesabı → Güvenlik → 2 Adımlı Doğrulama → Uygulama şifreleri → "Posta" → 16 harf).
     Normal Gmail şifren OLMAZ, uygulama şifresi şart.
   - `GOOGLE_CLIENT_ID`: Google Cloud → APIs & Services → Credentials →
     "OAuth client ID" (Web application) → istemci kimliği. JavaScript origins:
     `https://sonalis.com.tr`, Authorized redirect: gerekmez (mobil ID token kullanır).
3. Baslat: `docker compose -f deploy/gateway/docker-compose.gateway.yml up -d --build`
4. Kontrol: `http://ANA_IP:25577/health/live` → ok (ana API direk porttan da cevap verir;
   dis dunya Cloudflare uzerinden `https://api.sonalis.com.tr/health/live` kullanir).
5. Site: `https://sonalis.com.tr` → APK indir butonu calisir.
   (Gateway dahil her sey Node.js: `services/gateway/server.js`. Harici
   reverse proxy (Caddy/nginx) yok.)

## Yan sunucu (5 dakika)

1. `dist/alevi-edge.tar.gz` dosyasini yan sunucuya at:
   `tar -xzf alevi-edge.tar.gz && cd alevi-edge`
2. `.env` HAZIR gelir (`deploy/edge/.env`). SADECE sunlari degistir:
   `EDGE_UPLINK_URL=http://ANA_SUNUCU_IP:25577` (ANA_IP_BURAYA yerine gercek IP),
   `SMTP_USER` + `SMTP_PASS` (anadakiyle AYNI Gmail uygulama şifresi).
3. Baslat: `docker compose -f deploy/edge/docker-compose.edge.yml up -d --build`
4. Ana sunucuda `.env` dosyasindaki `EDGE_SEED_HOST=EDGE_IP_BURAYA` yerine
   yan sunucunun IP'sini yazip `docker compose ... up -d api` ile API'yi
   yeniden baslat. (Alternatif: hic elleme, asagidaki admin panel yolunu kullan.)

## Yeni sunucu ekleme (admin panelinden, onerilen)

1. `https://yonetim.sonalis.com.tr` → **Sunucular** bölümü.
2. Form: ad (`yan-2`), mesh adresi (yan sunucu IP), port (`25763`) → **Sunucu ekle**.
3. Ekrana TEK SEFERLIK **katılım anahtarı** cikar. Bunu yan sunucunun
   `.env` dosyasindaki `EDGE_JOIN_TOKEN` ve `EDGE_UPLINK_URL` degerlerine
   yazip edge API'yi yeniden baslat (`up -d --build api` degil, `restart api` yeter;
   token degistiysa compose `up -d` gerekir cunku env degisti).
4. 15 saniye icinde listede **çevrimiçi** (yesil) görünür. Nabız 60 sn
   kesilirse çevrimdışı (kirmizi) olur.

## Sifreleme notu

Mesajlar, topluluk gönderileri ve şikayet detayları veritabanında
AES-256-GCM ile şifreli durur (anahtar: SENSITIVE_DATA_KEY).
`.env` dosyalarini kimseyle paylasma; tar.gz yedegini guvenli tut.
Anahtari kaybedersen sifreli icerikler okunamaz.
