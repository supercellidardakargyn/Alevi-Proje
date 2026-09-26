# Alevi — `node index.js` kurulumu (docker yok)

## Gerekenler

- Sunucuda **Node.js 20+** kurulu olsun: `node --version`
- Dis Postgres (Supabase/Neon ucretsiz): connection string alin
- 4 DNS A kaydi ana sunucu IP'sine (Cloudflare turuncu bulut acik):
  `canmeydani.com.tr`, `www`, `api`, `yonetim`

## Ana sunucu

1. Paketi ac: `tar -xzf alevi-ana-sunucu.tar.gz && cd alevi-main`
2. `.env` dosyasini olusturup duzenle (SADECE bunlar):
   `cp .env.example .env` sonrasi:
   - `DATABASE_URL=` → Postgres connection stringin
     (ornek: `postgresql://postgres:SIFRE@db.xxx.supabase.co:5432/postgres?schema=public`)
   - `SMTP_USER=` + `SMTP_PASS=` → Gmail adresin + **uygulama şifresi**
     (Google Hesabı → Güvenlik → 2 Adımlı Doğrulama → Uygulama şifreleri)
   - `GOOGLE_CLIENT_ID=` → Google Cloud OAuth Web istemci kimliği
3. Baslat: `node index.js`
   Ekranda sirasiyla su satirlar gorulur:
   `[kurulum] veritabani migration calistiriliyor...`
   `[ok] api=:3000 admin=:3001 gateway=:25577`
4. Kontrol: `https://api.canmeydani.com.tr/health/live` → `{"status":"ok"}`
   Site: `https://canmeydani.com.tr` (APK indirme calisir).
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

## Güncelleme (elle)

Otomatik güncelleme yoktur. Yeni sürümde masaüstündeki yeni
`alevi-ana-sunucu.tar.gz` dosyasını sunucuya yükleyip açın,
`node index.js` ile yeniden başlatın. `.env` dosyanız yerinde kalır.

## E-posta dogrulama notu

SMTP/Gmail doldurulmadan production acilmaz (bilincli durdurma).
Gmail "normal sifre" ile calismaz, uygulama şifresi sarttir.

## Yapay zekâ özellikleri (isteğe bağlı)

`.env` içinde üç değer:

```
AI_ENABLED=true
AI_API_KEY=<Vercel AI Gateway anahtarı>
AI_MODEL=<Vercel AI Gateway model kimliği>
```

`AI_API_URL` varsayılan `https://ai-gateway.vercel.sh/v1` gelir; başka bir
OpenAI uyumlu sağlayıcı kullanacaksan değiştir.

**Model kimliği doğru değilse uygulama çökmez**, sadece yapay zekâ özellikleri
sessizce devre dışı kalır. Doğrulama:

```bash
curl -s https://ai-gateway.vercel.sh/v1/chat/completions \
  -H "authorization: Bearer $AI_API_KEY" -H "content-type: application/json" \
  -d "{\"model\":\"$AI_MODEL\",\"messages\":[{\"role\":\"user\",\"content\":\"merhaba\"}],\"max_tokens\":10}"
```

`200` dönüyorsa kimlik doğrudur. `401` anahtar, `404` model kimliği demektir.

Açıldığında devreye giren özellikler:

| Özellik | Nerede |
| --- | --- |
| Akıllı yanıt önerisi (son mesaja göre 3 cevap) | Sohbet ekranı |
| Buz kırıcı (hedef profile göre 3 ilk mesaj) | Keşfet kartı |
| Bio yardımcısı (düzeltme + 2 ipucu) | Profil düzenleme |
| Sohbet özeti (en fazla 3 cümle) | Sohbet ekranı |
| Eşleşme notu ("neden eşleştiniz") | Keşfet kartı |
| Destek otomasyonu (şifre / hesap / ücret) | Destek talebi |

### Dürüst not: "Reflex" hissi nereden geliyor?

Hızlı mini modeller **öğrenme yapmıyor**; önerilerin çoğu sunucudaki **gömülü
senaryo kütüphanesinden** gelir (son mesaja göre hazır cevaplar, ilgi alanına
göre buz kırıcılar, ortak etkinliğe göre eşleşme notları). Modele yalnızca
kütüphanenin yetmediği yerde başvurulur. Bu yüzden yanıtlar anında gelir ve
çoğu zaman bedavadır. Eğitim iddiası yoktur.

### Kuyruk

Tüm istekler sunucuda tek bir FIFO kuyruktan geçer: aynı anda en fazla 1 istek,
istekler arası en az 1,5 sn bekleme, istek başına 30 sn zaman aşımı. Böylece
kota tükenmez ve uygulama kilitlenmez.

## Reflex moderasyon (Jev, istege bagli)

Sikayetler TypeSafe System One degerlendirme modeliyle aninda puanlanir
(metin uretmez, tek istekte ciddiyet + kategori + mudahale karari doner).
`.env`:

```
REFLEX_ENABLED=true
REFLEX_API_URL=https://api.typesafe.ai/v1/systemone
REFLEX_API_KEY=<TypeSafe konsol anahtari (console.typesafe.ai/keys)>
REFLEX_MODEL=jev-latest
```

Dikkat: bu anahtar Vercel AI Gateway anahtari DEGIL, TypeSafe konsolundan
ayrica alinir. Kapaliysa sikayetler eski usulle OPEN kalir, hicbir sey degismez.

Davranis:

| Jev karari | Ne olur |
| --- | --- |
| Ciddiyet 3-4 + yuksek guven | Hedef **siradan uyeseyse** hesap otomatik kapatilir, rapor cozulur, denetim izi yazilir (`actor: reflex`) |
| Ciddiyet 2 veya mudahale gerekli | Rapor REVIEWING olur, moderasyon kuyrugunun basina gecer |
| Zararsiz / dusuk guven | Rapor OPEN kalir |

Guvenlik klitleri: yonetici ve moderatorlere oto-yasak YOK, silinmis hesaba
islem YOK, supheli durumda insan karari beklenir (rapor kuyrukta kalir).
