# Kurulum ve işletim

## 1. Ön koşullar

Üretim makinesinde aşağıdakiler hazır olmalıdır:

- Linux için systemd veya Windows Server 2019/2022.
- Node.js LTS, pnpm ve API'nin kilitli dependency seti.
- PostgreSQL ve Redis için TLS uç noktaları; tercihen ayrı/managed servis.
- DNS, geçerli TLS sertifikası ve yalnız gerekli portları açan firewall.
- Secret manager veya işletim sistemi secret store. `.env` yalnız secret olmayan ayarların şablonudur.
- Saat senkronizasyonu (NTP) ve UTC loglama.

Admin panelinin yerel geliştirmesi için `apps/admin/README.md` içindeki adımlar kullanılır. Admin üretimde API ile aynı origin altında veya açıkça allowlist'e alınmış HTTPS origin'de sunulmalıdır.

## 2. Secret hazırlığı

Aşağıdaki değerleri güvenli secret manager'da oluşturun; shell geçmişine, issue'lara veya CI log'una yazmayın:

- API signing/rotation anahtarları ve refresh-token pepper.
- PostgreSQL/Redis TLS CA ve service account bilgileri.
- Mesh CA, bootstrap node sertifikası ve private key.
- KMS/Vault erişimi ve envelope-encryption key id'leri.
- Medya storage bucket, erişim rolü ve malware tarama ayarları.
- Admin IdP/MFA ayarları.

Private key dosyalarının izinleri Linux'ta yalnız servis kullanıcısına (`0600`), Windows'ta yalnız servis hesabına verilmelidir.

## 3. Linux sunucu kurulumu

`install-server.sh` runtime, kullanıcı, klasör, izin, systemd servisi ve temel health kontrolünü doğrulamak için kullanılır. Root ile yalnız ilk provisioning aşamasında çalıştırın:

```bash
sudo ./scripts/install-server.sh --release-dir /opt/alevi/api --service-user alevi
sudo systemctl enable --now alevi-api
sudo systemctl status alevi-api
curl --fail --silent https://api.example.test/health/live
curl --fail --silent https://api.example.test/health/ready
```

Kurulum script'i secret üretmez, dışarıya gerçek veri göndermez ve başarılı health sonucu uydurmaz. API binary/source tree veya gerekli environment yoksa durur.

Systemd hardening için `deploy/systemd/alevi-api.service` kullanılır. `NoNewPrivileges`, private temporary directory, restricted capabilities, restart backoff ve ayrı kullanıcı etkin olmalıdır. Log rotasyonu journald veya merkezi log toplama ile ayarlanır; token, parola, mesaj içeriği ve hassas profil alanları loglanmaz.

## 4. Windows Server kurulumu

Yönetici PowerShell ile:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\scripts\install-server.ps1 -ReleaseDir 'C:\Program Files\Alevi\api' -ServiceName 'AleviApi'
Get-Service -Name AleviApi
Invoke-WebRequest https://api.example.test/health/ready
```

`deploy/windows-service/` içindeki servis tanımı, servis hesabı, failure action ve log klasörü kontrol edilmeden üretime alınmaz. Windows Firewall'da yalnız HTTPS, health/internal mesh için zorunlu portlar açılır; PostgreSQL/Redis public internete açılmaz.

## 5. Veritabanı ve migration

1. PostgreSQL TLS bağlantısını ve least-privilege service account'u doğrulayın.
2. Migration'ı release imajının aynı commit'i ile çalıştırın.
3. Migration öncesi şifreli ve geri yükleme testi yapılmış yedek alın.
4. Destructive migration'larda iki aşamalı expand/contract ve geri dönüş planı uygulayın.
5. Redis ACL, TLS ve ayrı service account ile başlatılmalıdır.

Üretim veritabanına doğrudan manuel `UPDATE/DELETE` yalnız onaylı break-glass prosedürü ve audit kaydıyla yapılır.

## 6. Yayına alma kontrol listesi

- [ ] HTTPS/TLS 1.3, HSTS ve güvenli header'lar doğrulandı.
- [ ] `/health/live` süreç sağlığını, `/health/ready` bağımlılık sağlığını doğru döndürüyor.
- [ ] Admin MFA, RBAC, CSRF ve session revocation test edildi.
- [ ] Backup restore ve hesap/veri silme akışı test edildi.
- [ ] Rate limit, abuse ve authorization testleri geçti.
- [ ] Secret scan ve dependency audit temiz.
- [ ] Alert receiver, on-call ve rollback komutu doğrulandı.
- [ ] Release commit'i, migration ve config checksum'ı kaydedildi.

## 7. Rollback

Rollback yalnız uyumlu migration planı ve on-call onayıyla yapılır. Önce trafiği azaltın, mevcut release'i immutable tag ile saklayın, migration geri dönüş gerektiriyorsa belgelenmiş script'i çalıştırın ve health/readiness ile doğrulayın. Kullanıcı verisini kaybeden hızlı rollback yapılmaz; olay sonrası audit ve etki analizi tutulur.
