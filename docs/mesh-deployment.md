# Şifreli mesh dağıtımı

## Mimari karar

Mesh, veritabanını çoklu-master yapmaz. Tüm node'lar stateless API/WebSocket edge olarak çalışır; PostgreSQL için tek primary veya managed HA, Redis için TLS/ACL'li ortak servis kullanılır. Böylece 5–10 bilgisayar yatay olarak katılırken yazma çatışması ve iki ayrı gerçeklik oluşmaz.

Node-to-node trafiği yalnız mTLS ile kabul edilir. LAN broadcast ile herkesi kabul etme, public internete mesh portu açma veya private key paylaşma yapılmaz.

## İlk node: init

İlk makinede:

```powershell
.\scripts\mesh-init.ps1 -NodeName mesh-01 -OutputDir 'C:\ProgramData\Alevi\mesh'
```

```bash
sudo ./scripts/mesh-init.sh --node-name mesh-01 --output-dir /etc/alevi/mesh
```

Init işlemi:

1. Offline root CA ve mesh intermediate CA için hedef dizin/secret manager kontrolü yapar.
2. Bootstrap node kimliği ve private key üretir.
3. CA fingerprint, protocol version ve bootstrap peer adresini korumalı çıktı olarak kaydeder.
4. Tek kullanımlık, kısa ömürlü join invite üretmek için metadata hazırlar.

CA/private key stdout'a basılmaz, `.env` içine yazılmaz, git'e eklenmez. Root CA çevrimdışı veya HSM/Vault altında tutulur; node key'i yalnız ilgili node'da bulunur.

## Yeni node: join

```powershell
.\scripts\mesh-join.ps1 -Token $env:MESH_JOIN_TOKEN -Bootstrap 'https://mesh-bootstrap.example.test' -OutputDir 'C:\ProgramData\Alevi\mesh'
```

```bash
sudo ./scripts/mesh-join.sh --token "$MESH_JOIN_TOKEN" --bootstrap 'https://mesh-bootstrap.example.test' --output-dir /etc/alevi/mesh
```

Join token:

- kısa TTL'ye ve tek kullanıma sahiptir;
- node adı, rol, izin ve beklenen CA fingerprint'i ile bağlanır;
- başarılı provision sonrasında iptal edilir;
- log veya shell history'de tutulmaz.

Bootstrap, CSR ve node attestation'ı doğrulamadan sertifika vermez. Sertifika süresi, issuer, SAN/node id, CA fingerprint, protocol version ve nonce kontrol edilir.

## Keşif ve bağlantı

- Aynı güvenilir LAN'da `_alevi-mesh._tcp` mDNS yalnız provision edilmiş node'ların keşfini kolaylaştırır; kimlik doğrulamaz.
- Farklı ağlarda mDNS kullanılmaz. WireGuard/Tailscale gibi private overlay ve `MESH_BOOTSTRAP_PEERS` statik seed adresleri gerekir.
- Bağlantı TLS 1.3 mTLS, explicit protocol allowlist ve node ACL ile kurulur.
- Heartbeat, exponential backoff, reconnect ve stale-peer expiry vardır.
- Redis event fan-out olayları idempotency key ile tekilleştirilir.

## Port ve ağ politikası

Varsayılan portlar proje config'inden alınır; bu liste örnek politikadır:

| Trafik | Kaynak | Hedef | Politika |
|---|---|---|---|
| HTTPS/WSS | İstemci/edge | API | Public HTTPS, reverse proxy arkasında |
| Mesh mTLS | Provision edilmiş node CIDR/overlay | Node | Deny-by-default + mTLS |
| PostgreSQL TLS | API node'ları | DB private subnet | Public değil |
| Redis TLS | API node'ları | Redis private subnet | ACL + TLS |
| SSH/RDP | Bastion/IT | Sunucu | MFA, allowlist, audit |

## Üyelik, iptal ve rotasyon

- Node revoke edildiğinde ACL'den, service discovery'den ve overlay'den çıkarılır.
- CA veya node sertifikası rotasyonunda overlap penceresi ve yeni fingerprint duyurusu kullanılır.
- Kayıp/şüpheli private key'de beklemeden node revoke ve yeni CSR yapılır.
- Join invite tekrar kullanımı, yanlış CA, süresi geçmiş sertifika, yanlış SAN ve mTLS'siz bağlantı negatif testte reddedilir.
- Her provision, revoke, rotate, failed handshake ve üyelik değişikliği immutable audit log'a yazılır; private key veya token yazılmaz.

## Operasyon doğrulaması

3 ve 10 node senaryolarında aşağıdakiler test edilir:

- karşılıklı peer görünürlüğü ve protocol handshake;
- mTLS olmadan reddedilme;
- node kapanışında stale peer temizliği;
- yeniden açılışta reconnect;
- yanlış CA/expired cert/reused invite reddi;
- Redis event fan-out ile duplicate olayın tekilleşmesi;
- network partition sonrası kontrollü toparlanma.

Mesh, güvenlik sınırının kendisi değildir. API endpoint authorization, DB/Redis ACL ve admin RBAC her node'da aynı şekilde uygulanır.
