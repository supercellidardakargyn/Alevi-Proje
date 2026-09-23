# Güvenlik modeli

## Hedef ve sınırlar

Hedef; kişisel verinin amaç dışında işlenmesini, hesap ele geçirilmesini, node/secret suistimalini, yetkisiz moderasyon kararını ve medya/mesaj sızıntısını azaltan ölçülebilir kontroller kurmaktır. “Tamamen güvenli” veya metadata'sız bir sistem vaat edilmez: IP, zamanlama, cihaz ve trafik metadatası bazı katmanlarda görülebilir ve retention ile sınırlandırılır.

Tehdit modeli en az şu aktörleri kapsar:

- internet üzerindeki anonim saldırgan ve bot;
- ele geçirilmiş hesap veya kötüye kullanılan admin hesabı;
- kötü niyetli/ele geçirilmiş mesh node;
- yanlış yapılandırılmış storage, log veya backup;
- içerik abuse, taciz, sahte profil ve rapor spam'i;
- insider veya break-glass erişim kullanan operatör.

## Kimlik ve yetki

- Kullanıcı parolaları Argon2id ile hashlenir; parola plaintext tutulmaz.
- Access token kısa ömürlüdür. Refresh rotation, reuse detection ve cihaz bazlı iptal uygulanır.
- Admin MFA zorunlu, role-based ve purpose-based access ile korunur.
- Her API isteği sunucu tarafında tenant/owner/role/purpose kontrolünden geçer; UI'da buton gizlemek yetkilendirme değildir.
- CSRF, CORS allowlist, güvenli cookie (`Secure`, `HttpOnly`, `SameSite`) ve rate limit uygulanır.
- OTP, login, reset, report ve media endpoint'lerinde IP/kullanıcı/cihaz bazlı abuse limiti vardır.
- Admin session revoke, emergency disable ve break-glass erişimi audit'lenir.

## Aktarım ve depolama

- Dış API/WSS TLS 1.3, HSTS, güvenli cipher ve reverse proxy arkasında çalışır.
- Node-to-node bağlantı TLS 1.3 mTLS, CA/fingerprint, node id, SAN, nonce ve protocol allowlist ile korunur.
- PostgreSQL/Redis yalnız private network, TLS ve ayrı least-privilege service account ile erişilir.
- Kültürel/dini bağ gibi hassas alanlar ayrı encrypted payload olarak envelope encryption ile tutulur; varsayılan görünürlük gizlidir ve discover ranking/filter'a girmez.
- Media upload MIME/size/magic-byte kontrolü, EXIF temizliği, malware scan, SSE-KMS ve kısa ömürlü signed URL kullanır.
- Backup ayrı anahtarla şifrelenir; retention, restore testi ve güvenli imha planı vardır.
- Direct message içeriği mümkün olduğunca ciphertext olarak saklanır. Moderasyon için kanıt, kullanıcının açıkça gönderdiği ayrı akışta ve sınırlı amaçla ele alınır.

## Uygulama kontrolleri

- JSON body/depth/size limiti; SSRF ve path traversal engeli.
- Output encoding ve güvenli içerik render'ı; admin panelinde raw HTML çalıştırılmaz.
- Idempotency key ile ödeme/rapor/moderasyon gibi tekrar edilebilir işlemler korunur.
- Security headers: CSP (deploy origin'e göre), X-Content-Type-Options, Referrer-Policy, frame deny ve Permissions-Policy.
- Error response kullanıcıya stack trace veya secret vermez; request id ile korelasyon sağlanır.
- Secret scan, dependency/SBOM, SAST, container scan, authorization test, TLS testi ve restore testleri CI/release kapısıdır.

## Log, audit ve izleme

Loglarda parola, access/refresh token, private key, mesaj gövdesi ve maskelenmemiş hassas alan bulunmaz. Audit log en az aktör, rol, amaç, kaynak, eylem, sonuç, zaman, request id ve reason içerir; silme/değiştirme yetkisi kısıtlıdır. Şüpheli login, rate-limit spike, failed mTLS, bulk export, moderator action burst ve data deletion alert üretir.

## Anahtar yaşam döngüsü

1. Anahtar üretimi CSPRNG/KMS/HSM veya güvenilir secret manager ile yapılır.
2. Her ortam, servis ve node ayrı kimlik/anahtara sahiptir.
3. Rotasyon overlap penceresiyle planlanır; eski anahtarın kullanım zamanı gözlenir.
4. Kayıp/şüpheli anahtarda revoke, rotation ve incident response başlatılır.
5. Secret yalnız ihtiyaç anında erişilir; CI output ve artifact'e sızmaz.
6. Backup anahtarları uygulama anahtarından ayrıdır; restore yetkisi iki kişili kontrolle tutulur.

## Olay müdahalesi

1. Etkilenen token/node/storage/endpoint'i izole et.
2. Kanıtı değişmez biçimde sakla; log retention ve KVKK yükümlülüklerini gözet.
3. Etkilenen secret'ları revoke/rotate et; session'ları iptal et.
4. Etki kapsamı ve veri kategorilerini belirle.
5. Hukuk/uyum ve gerekli bildirim akışını işlet.
6. Güvenli düzeltme, geri dönüş ve postmortem yap.

Güvenlik kararı, kırılabilir varsayımları ve kalan riski release kaydına yazılmalıdır.
