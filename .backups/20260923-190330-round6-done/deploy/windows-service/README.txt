Alevi API Windows servisi

install-server.ps1, WinSW ile Node.js API'yi Windows servisi olarak kaydeder. WinSW executable repoya eklenmez; güvenilir sürümünü `AleviApi.exe` adıyla bu klasöre koyun veya `-WinSwPath` ile yol verin.

WinSW binary'sinin SHA-256 değerini release kaydında ve güvenilir kaynaktan doğrulamadan üretimde kullanmayın. Servis hesabı varsayılan olarak LocalService'tir. Secret'lar `ProgramData\Alevi\config` dosyasına plaintext yazılmamalı; Windows Credential Manager veya kurumsal secret manager kullanılmalıdır.
