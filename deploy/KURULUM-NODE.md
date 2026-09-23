# Alevi — `node index.js` kurulumu (docker yok)

## Gerekenler

- Sunucuda **Node.js 20+** kurulu olsun: `node --version`
- Dis Postgres (Supabase/Neon ucretsiz): connection string alin
- 4 DNS A kaydi ana sunucu IP'sine (Cloudflare turuncu bulut acik):
  `sonalis.com.tr`, `www`, `api`, `yonetim`

## Ana sunucu

1. Paketi ac: `tar -xzf alevi-ana-sunucu.tar.gz && cd alevi-main`
2. `.env` dosyasini duzenle (SADECE bunlar):
   - `DATABASE_URL=` → Postgres connection stringin
     (ornek: `postgresql://postgres:SIFRE@db.xxx.supabase.co:5432/postgres?schema=public`)
   - `SMTP_USER=` + `SMTP_PASS=` → Gmail adresin + **uygulama şifresi**
     (Google Hesabı → Güvenlik → 2 Adımlı Doğrulama → Uygulama şifreleri)
   - `GOOGLE_CLIENT_ID=` → Google Cloud OAuth Web istemci kimliği
3. Baslat: `node index.js`
   Ekranda sirasiyla su satirlar gorulur:
   `[kurulum] veritabani migration calistiriliyor...`
   `[ok] api=:3000 admin=:3001 gateway=:25577`
4. Kontrol: `https://api.sonalis.com.tr/health/live` → `{"status":"ok"}`
   Site: `https://sonalis.com.tr` (APK indirme calisir).
   Kapatmak icin: `Ctrl+C`.

Arka planda calistirmak icin: `nohup node index.js > alevi.log 2>&1 &`
veya systemd/pm2 (istege bagli).

## Yan sunucu

1. Paketi ac: `tar -xzf alevi-yan-sunucu.tar.gz && cd alevi-edge`
2. `.env` dosyasinda SADECE sunlari duzenle:
   - `DATABASE_URL=` → bu sunucunun Postgres adresi (ana sunucuyla AYNI DB de olur)
   - `EDGE_UPLINK_URL=http://ANA_SUNUCU_IP:25577` (gercek IP)
   - `SMTP_USER` + `SMTP_PASS` (anadakiyle ayni)
3. Baslat: `node index.js`
4. Ana sunucunun `.env` dosyasindaki `EDGE_SEED_HOST` degerine yan sunucu
   IP'sini yazip ana sunucuyu yeniden baslat (Ctrl+C → `node index.js`).
   Alternatif: yonetim panelindeki **Sunucular** bölümünden ekle.

## Otomatik güncelleme (isteğe bağlı)

`node index.js` 10 dakikada bir GitHub `latest` paketine bakar
(`AUTO_UPDATE=1` ise). Yeni sürümde indirir, açar, migration kurar ve
servisleri ana process kapanmadan yeniden başlatır. `.env` ve yüklenen
fotoğraflar korunur. Açmak için `.env` dosyasına `AUTO_UPDATE=1` yazıp
yeniden başlatın. Paketler her `main` push'unda otomatik üretilir
(`.github/workflows/release-tars.yml`).

## E-posta dogrulama notu

SMTP/Gmail doldurulmadan production acilmaz (bilincli durdurma).
Gmail "normal sifre" ile calismaz, uygulama şifresi sarttir.
