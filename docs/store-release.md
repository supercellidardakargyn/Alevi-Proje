# Mağaza sürümü ve imzalama

## Temel kural

İmzalı Android, iOS veya Windows mağaza paketi üretmek için ilgili hesap, sertifika, provisioning/profile ve CI secret'ları gereklidir. Secret yoksa workflow açık hata ile durur. Pipeline sahte APK/AAB/IPA/MSIX, boş zip veya “başarılı” görünen placeholder artifact üretmez.

İmzalama anahtarları repoya, issue'ya, artifact'e veya `.env` dosyasına konmaz. CI artifact retention, erişim rolü ve release log'ları ayrıca kısıtlanır.

## Android / Google Play

Gerekli hazırlık:

- Play Console uygulaması ve package/application id.
- Release keystore; alias ve parolaları secret manager'da.
- Play service account JSON veya OIDC tabanlı kısa ömürlü yetki.
- Play Integrity, data safety, içerik derecelendirmesi ve KVKK/gizlilik metni.

CI'da kullanılan zorunlu değerler `android-release.yml` içinde kontrol edilir: keystore base64, keystore/alias/password ve Play yetkilendirmesi. Keystore geçici dosyaya yazılır, build sonrasında silinir. `flutter build appbundle --release` ile gerçek `.aab` çıktısı oluşturulmadan upload/artifact adımı çalışmaz.

Yerel imzasız/dev doğrulama ile mağaza release'i karıştırmayın:

```bash
flutter build apk --release
flutter build appbundle --release
```

Gerçek Android mağaza gönderimi yalnız signing ve Play Console secret'ları doğrulandıktan sonra yapılır. Version code/name CI release tag'inden deterministik üretilir ve tekrar kullanılan version code reddedilmelidir.

## iOS / App Store

IPA/archive üretimi Windows'ta yapılmaz; `ios-release.yml` macOS runner kullanır.

Gerekli hazırlık:

- Apple Developer Team ve bundle identifier.
- Distribution certificate (`.p12`) ve parolası.
- App Store provisioning profile.
- App Store Connect API key id, issuer id ve private key.
- Push entitlement, privacy manifest, kamera/fotoğraf/konum açıklamaları ve 18+ derecelendirmesi.

CI keychain'i geçici oluşturur, profile/certificate'i import eder ve job sonunda temizler. `xcodebuild`/Flutter archive ve IPA gerçek dosyayı üretmezse artifact/upload adımı hata verir. Windows üzerinde IPA üretmeye çalışan helper bilinçli olarak durmalıdır.

Yerel komut örneği yalnız macOS'ta:

```bash
./scripts/build-ios.sh --configuration Release
```

## Microsoft Store / Windows

Gerekli hazırlık:

- Partner Center uygulama kimliği, Identity Name, Publisher bilgisi.
- Windows Store submission için MSIX manifest ve version.
- CI'da kullanılacak PFX veya Store signing/OIDC yetkisi.
- Logo/tiles, yaş derecelendirmesi, privacy URL ve package identity.

```powershell
.\scripts\build-windows.ps1 -Configuration Release
```

`windows-store.yml` secret, publisher ve gerçek `.msix` bulunmadan artifact üretmez. PFX geçici makinede import edilir; password loglanmaz ve sertifika temizlenir. Store submission sırasında Partner Center'ın publisher/identity eşleşmesi doğrulanır.

## Release doğrulama

- [ ] Tag commit'i ve changelog onaylandı.
- [ ] Dependency/license/security scan geçti.
- [ ] Version ve bundle/package identity doğru.
- [ ] İmzalama secret'ları CI preflight'ta bulundu ve erişim audit edildi.
- [ ] Üretilen artifact dosya boyutu, formatı ve SHA-256 checksum'ı doğrulandı.
- [ ] Mobil izinler, deep link, push, privacy manifest ve data safety metinleri güncel.
- [ ] Staged/internal test ve rollback sürümü hazır.
- [ ] Artifact retention ve store hesabı erişimleri sınırlandırıldı.
