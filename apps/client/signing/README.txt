Signing placeholders

This folder intentionally contains no certificates or secrets.

Android:
- Use android/app/signing/keystore.properties.example.
- Keep upload-keystore.jks and keystore.properties outside version control.

Windows:
- Configure a real certificate_path and certificate_password through a local/private msix config.

iOS:
- Configure Apple Team ID, provisioning profiles, and signing certificates in Xcode/CI.
