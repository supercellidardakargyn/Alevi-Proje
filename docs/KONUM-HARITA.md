# Konum, harita ve yapay zekâ

## Konum veri seti

`apps/client/assets/data/locations.json` (292 KB) uygulamayla birlikte gelir:

- **250 ülke** — Türkçe adı, İngilizce adı, başkent, bölge, koordinat
- **~9.000 şehir** — ülke kodu → şehir adı + koordinat
- **81 il / 974 ilçe** (Türkiye)

Kaynak: [GeoNames](https://www.geonames.org/) (`cities5000`, `admin1CodesASCII`,
`admin2Codes`) + [mledoze/countries](https://github.com/mledoze/countries)
(Türkçe ülke adları). Lisanslar: GeoNames CC-BY 4.0, çalışma odası MIT.

### Yeniden üretme

```bash
mkdir -p /tmp/geo && cd /tmp/geo
curl -LO https://download.geonames.org/export/dump/cities5000.zip
curl -LO https://download.geonames.org/export/dump/admin1CodesASCII.txt
curl -LO https://download.geonames.org/export/dump/admin2Codes.txt
curl -LO https://raw.githubusercontent.com/mledoze/countries/master/countries.json
unzip cities5000.zip

python tools/locations/build_locations.py /tmp/geo apps/client/assets/data/locations.json
```

Betik, ülke başına en büyük 30 şehri + nüfusu 50.000 üzeri şehirleri (en fazla
120) alır; böylece dosya küçük kalır ama her ülkede anlamlı bir liste vardır.

## Konum girişi

- **Profil düzenleme** → Konum kartı → ülke / şehir (Türkiye'de il / ilçe) seçimi
- **Keşfet filtreleri** → aynı seçici, `country` + `city` + `district` sorgusu

Sunucu tarafı: `services/api/prisma/migrations/0012_user_country` (`users.country`),
`discover.ts` içinde `country`/`city`/`district` filtresi.

### Açık adres (özel alan)

Profil düzenlemede **"Açık adres"** alanı vardır (`users.address`, en fazla 500
karakter). Bu alan **asla** herkese açık profilde, keşfette, eşleşmede veya
haritada dönülmez; yalnızca `/v1/profile/me` yanıtında sahibine gösterilir.
Migration: `0015_user_address`.

## Harita

`apps/client/lib/app/screens/map/map_screen.dart` — ana sekmede **Harita**.

- Tile'lar `https://tile.openstreetmap.org/{z}/{x}/{y}.png` adresinden gelir
  (OpenStreetMap tile kullanım şartlarına uyar; ağır kullanımda kendi tile
  sunucunu kur).
- Yerel SDK/WebView yok → aynı kod web, Android, Windows, Linux, macOS'ta çalışır.
- Pan/sürükleme, yakınlaştırma, 5–500 km yarıçap kaydırıcısı, konum butonu.
- Uç: `GET /v1/map/nearby?lat&lng&radiusKm&limit`

### Gizlilik (önemli)

- Üyelerin **gerçek konumu asla gönderilmez**: sunucu koordinatları
  0,02 derece (~2 km) hassasiyete yuvarlar (`blur()`).
- Her üye **Profil → Haritada görün** anahtarıyla haritadan çıkabilir.
- Engellenen kullanıcılar listede hiç görünmez (çift yönlü kontrol).
- Veritabanında kutu öncesi dar bölge filtresi uygulanır, sonra gerçek mesafe
  hesaplanır; kapsayıcı kutu kenarına düşenler elenir.
