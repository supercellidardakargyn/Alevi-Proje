# Alevi Flutter istemcisi

Alevi; keşif, eşleşme, mesajlaşma ve topluluk akışlarını bir araya getiren Türkçe Flutter MVP istemcisidir. Kaynaklar mobil ve Windows hedeflerine ortak olacak şekilde hazırlanmıştır.

## Çalıştırma

Makinede Flutter kuruluysa:

```powershell
flutter pub get
flutter run -d windows --dart-define=MOCK_DATA=true
```

API ile çalıştırmak için sunucu URL'sini derleme zamanında ver:

```powershell
flutter run --dart-define=API_BASE_URL=https://api.example.com/v1 --dart-define=MOCK_DATA=false
```

Uygulama, `MOCK_DATA=true` iken statik Türkçe örnek verilerle açılır. Varsayılan değer MVP'nin çevrimdışı görsel olarak açılabilmesi için `true`'dur.

## Yapı

- `lib/main.dart`: uygulama giriş noktası ve environment/config kurulumu.
- `lib/app/app.dart`: onboarding, 18+ giriş/kayıt ve gerçek shell geçişi.
- `lib/app/screens/`: Keşfet, Eşleşmeler, Mesajlar, Topluluk ve Profil ekranları.
- `lib/app/services/api_client.dart`: HTTP API client interface, gerçek ve mock uygulamalar.
- `lib/app/services/secure_storage.dart`: güvenli saklama abstraction ve test/mock uygulaması.
- `lib/app/theme/app_theme.dart`: bordo, krem, antrasit ve altın tema.

## Ekranlar ve güvenlik

Onboarding 18+ güvenlik mesajlarını gösterir. Kayıt akışı 18+ onayı ister. Profil ve sohbet ekranlarında görünürlük, profil doğrulama, engelleme, bildirim, gizlilik, veri indirme ve hesap silme widget'ları bulunur. Bunlar MVP'de gerçek etkileşimli widget'lardır; backend entegrasyonu API sözleşmesine bağlanmaya hazırdır.

## Paketleme ve mağaza hazırlığı

Native generated `android/`, `ios/` ve `windows/` Flutter yapıları elle çoğaltılmamıştır. Bunun yerine aşağıdaki mağaza ve imzalama placeholder'ları eklenmiştir:

- `msix.yaml`
- `android/app/signing/keystore.properties.example`
- `ios/Runner/PrivacyInfo.xcprivacy`
- `ios/Runner/Runner.entitlements.example`
- `store-config/`
- `signing/README.txt`
- `windows/scripts/build-release.ps1`
- `windows/scripts/build-msix.ps1`

Windows paketleme için `msix` paketini proje politikasına göre ayrıca etkinleştirip `msix.yaml` içindeki gerçek sertifika değerlerini gizli değişkenlerle ver. Gerçek sertifika, keystore, provisioning profile veya token bu dizine commit edilmemelidir.

## Notlar

- GitHub Actions client build workflow'u bu çalışma kapsamında değiştirilmemiştir.
- `assets/store/app_icon.png` ve mağaza ekran görüntüleri tasarım/marka varlıkları hazır olduğunda eklenmelidir.
- iOS `PrivacyInfo.xcprivacy` içeriği gerçek veri envanteri ve Apple beyanlarıyla yayın öncesi gözden geçirilmelidir.
