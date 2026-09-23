# KVKK veri haritası

Bu tablo ilk veri envanteri taslağıdır. Veri sorumlusu, işleme amaçları, saklama süreleri, aktarım ve aydınlatma/açık rıza metinleri hukuk ve uyum sorumlusu tarafından kesinleştirilmelidir. Hassas nitelikteki veri için zorunluluk varsayılmaz; kültürel/dini bağ alanları açıkça isteğe bağlı ve varsayılan gizlidir.

| Veri grubu | Örnek alanlar | Amaç | Saklama önerisi | Erişim/koruma |
|---|---|---|---|---|
| Hesap kimliği | kullanıcı id, e-posta, doğrulama durumu | hesap, giriş, güvenlik | hesap süresi + silme politikası | owner/admin purpose, şifreli transit, token yok |
| İletişim | telefon, e-posta, OTP metadata | doğrulama, güvenlik, bildirim | ihtiyaç süresi; OTP kısa TTL | maskeli UI, hash/şifreleme, rate limit |
| Profil | ad, yaş aralığı, şehir, dil, ilgi | keşfetme ve eşleşme | hesap süresi veya kullanıcı silmesi | alan bazlı görünürlük, minimizasyon |
| Hassas kültürel/dini alan | isteğe bağlı beyan | kullanıcının açık amacı | ayrı retention ve açık silme | encrypted payload, varsayılan gizli, admin maskeli |
| Fotoğraf/medya | profil fotoğrafı, rapor kanıtı | profil ve moderasyon | kullanıcı/itiraz politikası | malware scan, EXIF temizliği, signed URL |
| Etkileşim | like/pass/match/block | eşleşme ve güvenlik | amaç süresi, abuse/audit ihtiyacı | owner/relationship authorization |
| Mesaj | ciphertext/gönderim metadata | iletişim, güvenlik | açıklanmış mesaj retention | mümkünse ciphertext, sınırlı kanıt akışı |
| Şikâyet/moderasyon | report reason, action, evidence | abuse önleme, itiraz | yasal/audit süresi | moderator RBAC, immutable audit |
| Teknik kayıt | IP, cihaz, request id, hata | güvenlik, teşhis | kısa ve gerekçeli retention | erişim kısıtlı, maskeleme |
| KVKK talebi | export/delete/correction request | ilgili kişi hakları | talep ve doğrulama süresi | yüksek güvenli iş akışı, audit |

## İşleme ilkeleri

- Belirli, açık ve meşru amaç; amaçla bağlantılı, sınırlı ve ölçülü veri.
- Varsayılan gizlilik ve privacy by design; public discover API gereksiz alan döndürmez.
- Aydınlatma metni ve gerekiyorsa açık rıza ayrı tutulur; rıza hizmetin gereksiz koşulu yapılmaz.
- Hassas alanlar keşfetme sıralamasına, filtreye, reklam profiline veya otomatik karara sokulmaz.
- Doğruluk, erişim/düzeltme, silme, anonimleştirme/export ve itiraz akışları bulunur.
- Alt işleyen, storage, crash analytics ve push sağlayıcıları için aktarım/contract envanteri tutulur.
- Retention bitince secure deletion veya geri döndürülemez anonimleştirme uygulanır; backup kopyalarında gecikmeli imha belgelenir.

## İlgili kişi hakları akışı

1. Kimlik ve hesap sahipliğini güçlü biçimde doğrula.
2. Talebi türüne göre kaydet: erişim, düzeltme, silme, export, itiraz.
3. İlgili sistemleri ve backup retention'ı belirle.
4. Export'u gereksiz üçüncü taraf verisini maskeleyerek üret.
5. Silme istisnası varsa hukuki gerekçeyi ve saklama son tarihini kaydet.
6. Sonucu güvenli kanaldan bildir; audit kaydı oluştur.

Hukuki süreler ve istisnalar ülke/işleme senaryosuna göre değişebileceğinden bu taslak üretim hukuk onayı olmadan tek başına politika olarak kullanılmaz.
