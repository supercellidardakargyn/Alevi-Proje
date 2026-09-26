# Can Meydanı — Çalışma Durumu (v0.6.0 turu)

Son güncelleme: paketleme tamamlandı. Git HEAD: `88384ee` (bu turdaki değişiklikler **commit edilmedi**).
Kullanıcı talimatı: önce her şeyi bitir, paketlemeyi de yap.

Durum: **Tamamlandı.** İstemci derlemeleri yeşil, paketler üretildi, hash'ler
yazıldı, Masaüstü kopyaları yenilendi. Kalan tek iş: commit + push (token gerekli).

---

## Doğrulama durumu

| Kontrol | Sonuç |
| --- | --- |
| `npm --prefix packages/contracts run build` | ✅ |
| `npm --prefix services/api run build` | ✅ (TS hatası yok) |
| `npm --prefix services/api run typecheck` | ✅ |
| `npm --prefix services/api test` | ✅ **40/40** (25 eski + 15 yeni) |
| `flutter analyze lib test` (apps/client) | ✅ No issues found |
| `flutter test` (apps/client) | ✅ 4/4 |
| İstemci derlemesi (web/apk/windows) | ✅ web + apk (90,6 MB) + windows + Inno kurulum |
| Sunucu paketleri (`prepare-bundles.ps1`) | ✅ `alevi-main.tar.gz` (119 MB) + `alevi-edge.tar.gz` |
| `site/indir` + `site/web` + `version.json` + `SHA256SUMS.txt` | ✅ hash'ler gerçek değerlerle yazıldı |
| Masaüstü kopyaları | ✅ yenilendi (eski 0.5.6 exe silindi) |

---

## A grubu — Windows altyapısı (TAMAMLANDI)

- **Sistem çekmecesi**: `apps/client/lib/app/services/tray_service.dart`
  - `tray_manager: ^0.5.1` (0.7 API'si farklıydı, 0.5.3'e düşürüldü; `TrayManager.instance` API'si)
  - `window_manager: ^0.5.2` ile `setPreventClose(true)` → X'e basınca kapanmaz, gizlenir
  - Sağ tık menüsü: **Aç** / **Çıkış**; sol tık aç/kapat
  - İkon: `apps/client/assets/icon/can-tray.ico` (32×32 ICO, PNG'den üretildi)
  - Web için `tray_stub.dart` (koşullu import `if (dart.library.io)`)
  - `main.dart` içinde `initTray()` çağrısı
- **İlk açılış bildirim izni**: `main_shell.dart` → `_maybePromptNotifications()`
  - Bir kez sorar (`notif_prompt_done`), Aç / Şimdi değil; `notifier.dart`'ya `ensurePermission()` eklendi
- **Sessiz otomatik güncelleme**: `services/update_service.dart`
  - Günlük kontrol + Ayarlar'da `checkNow`
  - Windows `.exe` ise: indir → **SHA-256 doğrula** → `/VERYSILENT /SUPPRESSMSGBOXES /CLOSEAPPLICATIONS` → çık
  - Doğrulama tutmazsa **hiçbir şey çalıştırılmaz**
  - Diğer platformlarda indirme önerisi
- **`.env` sızıntısı kapandı**: `scripts/prepare-bundles.ps1` artık sadece
  `deploy/gateway/.env.example` → `.env.example` koyuyor (gerçek `.env` asla tara girmez)
- Sürüm `0.5.6+11` → **`0.6.0+12`** (pubspec, app_strings, Inno Setup, site HTML, version.json)

---

## B grubu — Konum + harita (TAMAMLANDI)

### Veri seti
- **Üretici**: `tools/locations/build_locations.py` (GeoNames + mledoze/countries)
- **Çıktı**: `apps/client/assets/data/locations.json` — **292 KB**
  - 250 ülke (Türkçe ad, başkent, bölge, koordinat)
  - ~8.987 şehir (ülke → ad + koordinat; ülke başına en büyük 30 + nüfus>50k, max 120)
  - 81 il / 974 ilçe (Türkiye, Türkçe adlar; "İlçesi" eki temizlendi, `İstanbul` düzeltildi)
- `pubspec.yaml` → `assets/data/` eklendi
- Yeniden üretim komutu: `docs/KONUM-HARITA.md`

### Sunucu
- Migration `0012_user_country` → `users.country`
- Migration `0013_map_locations` → `users.show_map_location` (default true),
  `events.latitude/longitude` + 2 index
- `routes/profile.ts`: `country`, `showMapLocation` patch; `/me` yanıtına `showMapLocation`
- `routes/discover.ts`: `country` filtresi eklendi
- `routes/events.ts`: create event lat/lng kabul ediyor
- **Yeni `services/api/src/routes/map.ts`** → `GET /v1/map/nearby?lat&lng&radiusKm&limit`
  - Kaba kutu (bbox) öncesi filtre + gerçek Haversine mesafe
  - **Gizlilik: `blur()` koordinatları 0,02° (~2 km) yuvarlar**
  - Engellenenler (çift yönlü) hiç listelenmez
  - `showMapLocation=false` olanlar haritada yok
  - `app.ts`'te `secured.use('/map', mapRoutes(prisma))`

### İstemci
- **`services/location_data.dart`** — `LocationData.load()` (tek seferlik asset),
  `Country` / `City` / `Province` / `LocationChoice`, Türkçe alfabetik sıralama (`compareTr`)
- **`screens/profile/location_picker_screen.dart`** — ülke → şehir / (TR) il → ilçe
- **`screens/profile/location_fields.dart`** — `LocationField` (karta tıkla → seçici),
  `BioField` (+ "Yardım et" → AI)
- Profil düzenleme: eski serbest metin şehir/ilçe alanları **seçiciye** dönüştü
- Keşfet filtreleri: aynı seçici, `country`+`city`+`district` sorgusu
- **`screens/map/map_screen.dart`** — **OSM harita sekmesi** (6. sekme)
  - Tile'lar `tile.openstreetmap.org` (yerel SDK yok → web dahil her platformda çalışır)
  - Web Mercator projeksiyonu, pan/sürükleme, zoom, 5–500 km yarıçap (ağ isteği
    sürükleme bitince atılır: `onChangeEnd`), "Konumum" butonu
  - Üye iğneleri (avatar) + etkinlik iğneleri, mesafe etiketli kart
- Profil → **"Haritada görün"** anahtarı
- **6 sekme**: Topluluk · Keşfet · **Harita** · Eşleşmeler · Mesajlar · Profil
  (bildirim dokunma indeksi 3 → **4** olarak düzeltildi)

---

## C grubu — Yapay zekâ (TAMAMLANDI)

### Sunucu
- **`services/api/src/services/ai.ts` tamamen yeniden yazıldı**
  - `aiReady()`: `AI_ENABLED=false` veya anahtar/model boşsa **her şey `null` döner** (çökmez)
  - **FIFO kuyruk**: `enqueue<T>()` — aynı anda 1 istek, istekler arası ≥1500 ms,
    istek başına 30 sn timeout, hata izolasyonlu zincir
  - `chatComplete(system, user, maxTokens)`: OpenAI uyumlu POST, 2000 karakter kırpma
  - 401/404 → `console.error('[ai] model hatasi: <status> <model>')` + `null` (kilitlenme yok)
  - **Gömülü senaryo kütüphanesi** (model cagrısız, anında, bedava):
    - `FOLLOWUP_SCENARIOS` — teşekkür / selam / ne yapıyorsun / nerede / soru
    - `ICEBREAKER_SCENARIOS` — ilgi alanı → şehir → genel
    - `MATCH_NOTE_SCENARIOS` — 2+ ilgi + etkinlik / 2+ ilgi / etkinlik / 1 ilgi / hiçbiri
  - Dışa açık saf fonksiyonlar (test edilebilir): `scenarioSmartReplies`,
    `scenarioIcebreakers`, `scenarioMatchNote`
  - Dışa açık API fonksiyonları: `draftSupportReply`, `smartReplies`, `icebreakers`,
    `coachBio`, `summarizeChat`, `matchNote`
- **`services/api/src/routes/ai.ts`** (yeni) → `secured.use('/ai', writeLimiter(), aiRoutes(prisma))`
  - `POST /ai/smart-replies` (üyelik doğrulama, son 6 mesaj)
  - `POST /ai/icebreakers` (hedef + çift yönlü blok kontrolü)
  - `POST /ai/bio-coach`
  - `POST /ai/summarize` (son 50 mesaj)
  - `POST /ai/match-note` (kesişim ilgi alanları + ortak etkinlik sayısı)
- `packages/contracts/src/index.ts` sonuna 5 şema eklendi
- **`routes/support.ts`**: bilet açılışında **destek otomasyonu** — şifre / hesap silme /
  ücret kalıplarından biri tutarsa `[Otomatik yanıt] ` ile anında yanıt + `ANSWERED`;
  tutmazsa mevcut AI taslak akışı aynen çalışır

### İstemci
- **`screens/ai/ai_service.dart`** — 5 uç, hepsi hatada sessiz `[]`/`null`
- **`screens/ai/ai_sheet.dart`** — alt sayfa altyapısı + 5 sheet:
  `showBioCoachSheet`, `showSmartRepliesSheet`, `showSummarySheet`,
  `showIcebreakerSheet`, `MatchNoteText` (keşfet kartında eşleşme notu)
- Sohbet ekranı: **✨** butonu (akıllı yanıtlar, seçince mesaj olarak gönderir),
  mesaj kutusunda **⌛** (sohbet özeti)
- Keşfet kartı: **eşleşme notu** + **"Buz kırıcı önerileri"** butonu
  (seçilen cümle beğen'i tetikler, eşleşirse sohbete **taslak** olarak düşer —
  `ChatScreen.initialDraft`, kullanıcı göndermeden önce düzenler)
- Profil düzenleme: bio alanında **"Yardım et"**

### Dürüstlük notu
`deploy/KURULUM-NODE.md` içine yazıldı: hızlı mini modeller **öğrenmiyor**;
hız hissinin çoğu gömülü senaryo kütüphanesinden geliyor. Eğitim iddiası yok.

---

## D grubu — Reklam (TAMAMLANDI)

### AdMob (uygulama içi)
- `flutter pub add google_mobile_ads` → **9.1.0** (API farklıydı:
  `AdSize.banner` sabiti, `InterstitialAd.load(...)` statik, `load()` → `Future<void>`)
- `apps/client/lib/app/services/ads_service.dart` — `ChangeNotifier`,
  sadece Android/iOS (web/masaüstü reklam yok), `ADS_ENABLED=false` ile kapanır
- `apps/client/lib/app/widgets/ad_banner.dart` — ana ekranın altında banner
- `main_shell.dart`: `AdsService` + banner `NavigationBar` üstünde,
  `didChangeAppLifecycleState` → 4 dakikada bir en fazla interstitial
- **`app_config.dart`**: `adsEnabled`, `admobAndroidAppId`, `admobIosAppId`,
  `admobBannerUnit`, `admobInterstitialUnit`, `adsenseClientId`
- `AndroidManifest.xml` → `com.google.android.gms.ads.APPLICATION_ID` = `${admobAppId}`
- `android/gradle.properties` → `admobAppId=ca-app-pub-3940256099942544~3347511713` (**resmî test kimliği**)
- `build.gradle.kts` → `manifestPlaceholders["admobAppId"]` (gradle.properties'ten)
- Dart tarafında gerçek kimlik yoksa **Google'ın resmî test banner/interstitial
  birimleri** kullanılır

### AdSense (site)
- `site/ads.js` — **güvenli iskelet**: `PUBLISHER_ID` ve `SLOT_ID` boşsa hiçbir şey
  yüklemez. Doluysa `<main>` başına bir `<ins class="adsbygoogle">` enjekte eder
- `site/index.html` → `<script src="/ads.js" defer></script>` + yeni özellik kartları
  (Harita, Yapay zekâ yardımcısı)
- `site/ads.txt` — placeholder satır + nasıl değiştirileceği
- **`docs/REKLAM.md`** — AdMob + AdSense adım adım, gerçek ID'ler nerede yazılır

### Eksik (bilerek boş, kullanıcıdan ID gerekli)
- Gerçek AdMob uygulama/reklam birimi kimlikleri
- Gerçük AdSense `pub-...` yayıncı kimliği + slot ID
- `Vercel AI Gateway` geçerli model kimliği (`AI_MODEL`)

---

## Yeni testler
- `services/api/src/ai.test.ts` — 8 test: AI kapalıyken her şey `null`, asla `reject` olmaz,
  gömülü senaryoların doğru eşleşmesi
- `services/api/src/map.test.ts` — 7 test: sorgu varsayılanları/geçersiz değerler,
  `blur()` gizlilik davranışı, rota kaydı
- `services/api/package.json` → `test` script'i 5 dosyayı çalıştırıyor

## Yeni/İlgili dosyalar
```
tools/locations/build_locations.py
apps/client/assets/data/locations.json
apps/client/lib/app/services/location_data.dart
apps/client/lib/app/services/tray_service.dart  + tray_stub.dart
apps/client/lib/app/services/update_service.dart   (genişletildi)
apps/client/lib/app/services/ads_service.dart
apps/client/lib/app/widgets/ad_banner.dart
apps/client/lib/app/screens/ai/ai_service.dart  + ai_sheet.dart
apps/client/lib/app/screens/map/map_screen.dart
apps/client/lib/app/screens/profile/location_picker_screen.dart
apps/client/lib/app/screens/profile/location_fields.dart
apps/client/lib/app/config/app_config.dart        (genişletildi)
services/api/src/services/ai.ts                   (yeniden yazıldı)
services/api/src/routes/ai.ts                     (yeni)
services/api/src/routes/map.ts                    (yeni)
services/api/src/ai.test.ts, src/map.test.ts     (yeni)
services/api/prisma/migrations/0012_user_country/
services/api/prisma/migrations/0013_map_locations/
site/ads.js, site/ads.txt                        (yeni)
docs/REKLAM.md, docs/KONUM-HARITA.md             (yeni)
```

## Dikkat / tuzaklar
- **`.env` sunucuda zaten kurulu**; `deploy/gateway/.env` paketlenmiyor artık.
  Sunucuya yükleme yaparken mevcut `.env` yerinde kalmalı.
- **Migration 0012 ve 0013 yeni** → sunucuda `node index.js` ilk açılışta
  otomatik `prisma migrate deploy` çalıştırır (index.js `installAllDeps` + boot).
- `site/indir/CanMeydani-Kurulum-0.5.6.exe` hâlâ `site/indir` içinde duruyor;
  paketlemeden önce **silinmeli** (0.6.0 ile değişecek).
- `apps/client/android/.kotlin/` üretildi → `.gitignore`'a eklendi.
- PowerShell `Set-Content` Türkçe karakterleri bozuyor → değişiklikler
  `C:\Users\PC\AppData\Local\Programs\Python\Python314\python.exe` ile yapıldı.
- `edit` aracı bazı uzun Türkçe/özel karakterli bloklarda "Missing key" hatası
  veriyordu → Python script ile değiştirildi.

## Kalan adımlar (tamamlandı)
1. ~~İstemci derlemesinin bitmesini bekle~~ ✅ web + apk + windows + Inno (`dist/CanMeydani-Kurulum-0.6.0.exe`)
2. ~~`site/indir/CanMeydani-Kurulum-0.5.6.exe` sil~~ ✅ silindi (site + dist + Masaüstü)
3. ~~Yeni dosyaları `site/indir/` + `site/web/` + `site/version.json` + `site/SHA256SUMS.txt` güncelle~~ ✅
4. ~~`scripts/prepare-bundles.ps1` çalıştır~~ ✅ (tar doğrulandı: `.env` yok, test dosyası yok)
5. ~~Masaüstü kopyaları yenile~~ ✅
6. Commit + push (token: `scripts/git-push-tmp.ps1`, `.gitignore`'da; push sonrası sil)
