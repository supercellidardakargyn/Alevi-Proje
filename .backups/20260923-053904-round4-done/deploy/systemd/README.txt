alevi-api.service, install-server.sh tarafından token değişimleriyle /etc/systemd/system altına kurulur.

Unit; ayrı kullanıcı/grup, NoNewPrivileges, ProtectSystem=strict, ProtectHome, PrivateTmp, boş capability seti, kısıtlı address family, UMask ve restart policy kullanır. `ReadWritePaths` yalnız uygulamanın ihtiyaç duyduğu dizinlerle sınırlandırılır.

Üretimde `/etc/alevi/alevi-api.env` içine secret plaintext yazmayın; systemd credentials, Vault/KMS agent veya platform secret manager kullanın. `journalctl -u alevi-api` ile logları inceleyin; uygulama token, parola ve hassas profil alanlarını loglamamalıdır.
