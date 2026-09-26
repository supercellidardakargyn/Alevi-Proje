# Reklam kurulumu (AdMob + AdSense)

Şu an **test kimlikleri** ve **boş yayıncı kimliği** ile çalışıyor. Reklamlar
uygulamayı yavaşlatmaz, sunucuya düşmez; kimlik girilene kadar test reklamı
gösterilir, siteye hiçbir reklam yüklenmez.

---

## 1. AdMob (uygulama içi, Android/iOS)

### 1.1 Hesap
1. https://admob.google.com → Google hesabınla giriş.
2. **Başlayın** → **Uygulama ekle**.
3. Platform: **Android** (ve istersen **iOS**).
4. Ad: `Can Meydanı`, paket adı: `com.alevi.alevi_client`.
5. Uygulama kimliği panelde verilir: `ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY`.

### 1.2 Reklam birimleri
**Uygulama içi reklam → Yeni reklam birimi**:
- **Banner**: ana ekranın altında görünür.
- **Interstitial**: uygulamaya döndüğünde ara sıra tam ekran.

Her birimin ID'si `ca-app-pub-XXXXXXXXXXXXXXXX/1234567890` biçimindedir.

### 1.3 Kimlikleri koda yaz

**Android uygulama kimliği** — `apps/client/android/gradle.properties`:
```properties
admobAppId=ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY
```

**Reklam birimleri** — derleme komutuna ekle (`--dart-define`):
```
--dart-define=ADMOB_BANNER_UNIT=ca-app-pub-XXXXXXXXXXXXXXXX/1234567890
--dart-define=ADMOB_INTERSTITIAL_UNIT=ca-app-pub-XXXXXXXXXXXXXXXX/9876543210
```

**iOS** istersen `apps/client/ios/Runner/Info.plist` içine:
```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY</string>
```

### 1.4 Kapatmak için
`--dart-define=ADS_ENABLED=false` — hiçbir reklam yüklenmez.

### 1.5 Notlar
- Test kimlikleri Google'ın **resmî** kimlikleridir; gerçek hesapla test
  yapılacaksa gerçek kimlikler de test reklamı döner.
- Konum izni reklam için istenmez; reklam hedeflemesi kapatılmış durumda
  başlar, açmak istersen `RequestConfiguration`.
- KVKK: reklam sağlayıcıları kişisel veri işleyebilir. Onay kutusu eklersen
  `mobile_ads` içinde `ConsentInformation` ile yönetilir (şu an kapalı).

---

## 2. AdSense (site)

### 2.1 Hesap
1. https://www.google.com/adsense → site ekle: `canmeydani.com.tr`.
2. Panel **Ödeme** bölümünden yayıncı ID'ni al: `pub-XXXXXXXXXXXXXXXX`.
3. Panel **ads.txt** satırını kopyala.

### 2.2 Kodu güncelle
`site/ads.txt`:
```
google.com, pub-XXXXXXXXXXXXXXXX, DIRECT, f08c47fec0942fa0
```

`site/ads.js` içindeki iki sabiti güncelle:
```js
var PUBLISHER_ID = 'ca-pub-XXXXXXXXXXXXXXXX';
var SLOT_ID = '1234567890';
```

Bu iki değer boş olduğu için şu anda site **hiçbir reklam script'i yüklemez**.
`index.html`'de zaten `<script src="/ads.js" defer>` var; dosya kendi kendini
etkinleştirir.

### 2.3 Nerede gösterilir?
`ads.js` reklamı `<main>` başına, yani indirme bölümünün hemen üstüne ekler.
Gizlilik/KVKK gibi yasal sayfalarda gösterilmez (AdSense politikası gereği).

---

## 3. Doğrulama

```bash
# Uygulama
flutter build apk --release --dart-define=ADMOB_BANNER_UNIT=...

# Site (yerelde)
npx serve site      # sonra http://localhost:3000
```

Kontrol listesi:
- [ ] `adb logcat | grep -i admob` çıktısında hata yok.
- [ ] Test reklamı görünüyor, dokununca açılıyor.
- [ ] Site `ads.txt` dosyası 200 dönüyor ve içeriği doğru.
- [ ] `ads.js` içindeki kimlikler boş değilse sayfa yavaşlamıyor.
