[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
Write-Error 'iOS build yalnız macOS/Xcode üzerinde scripts/build-ios.sh ile çalıştırılabilir. Windows üzerinde IPA üretilmeyecek.'
exit 1
