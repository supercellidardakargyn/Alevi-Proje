# Can Meydanı — Yönetici kurulumu

## İlk yönetici hesabı

Kayıt formu normal üye açar. İlk yöneticiyi veritabanında yükseltin
(Supabase SQL editörü veya `psql`):

```sql
UPDATE users SET role = 'ADMIN' WHERE email = 'siz@ornek.com';
```

Sonraki yöneticiler panelden değil, aynı SQL ile atanır.
`MODERATOR` rolü giriş yapabilir ama `/v1/admin/*` uçları `ADMIN` ister.

## Yönetim web paneli

Ana sunucu paketinin içindedir, ek kurulum yok:

- Adres: `https://yonetim.canmeydani.com.tr`
- API: `https://api.canmeydani.com.tr` (aynı `.env`, ek ayar gerekmez)
- Giriş: ADMIN e-posta + şifre (Destek talepleri, Bildirimler, Kullanıcılar, metrikler)

## Yönetim mobil uygulaması

`apps/yonetim_client` (Flutter, ayrı paket adı `com.alevi.yonetim_client`):

- Giriş aynı uç: `POST /v1/auth/admin-login`
- Sekmeler: Genel (metrikler), Talepler (yanıt/kapat + yapay zeka taslağı),
  Bildirimler (reddet/kaldır/askıya al), Kullanıcılar (askıya al)
- Dağıtım: herkese açık sitede YAYINLANMAZ, yöneticilere elden verilir:
  `can-meydani-yonetim.apk` (Android), `can-meydani-yonetim-windows-x64.zip`
- Derleme (ana istemciyle aynı tanımlar):
  `flutter build apk --release --dart-define=API_BASE_URL=https://api.canmeydani.com.tr`
  `flutter build windows --release --dart-define=API_BASE_URL=https://api.canmeydani.com.tr`
