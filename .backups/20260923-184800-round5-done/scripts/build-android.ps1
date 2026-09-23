[CmdletBinding()]
param(
    [ValidateSet('apk', 'appbundle')]
    [string] $Format = 'apk',
    [ValidateSet('debug', 'profile', 'release')]
    [string] $Mode = 'release',
    [string] $ClientDir = '',
    [string] $OutputDir = '',
    [switch] $AllowUnsigned,
    [switch] $SkipPubGet
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
function Fail([string] $Message) { throw "HATA: $Message" }

$root = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($ClientDir)) { $ClientDir = Join-Path $root 'apps\client' }
if ([string]::IsNullOrWhiteSpace($OutputDir)) { $OutputDir = Join-Path $root 'dist\android' }
$client = [IO.Path]::GetFullPath($ClientDir)
$out = [IO.Path]::GetFullPath($OutputDir)
if (-not (Test-Path -LiteralPath (Join-Path $client 'pubspec.yaml') -PathType Leaf)) { Fail "Flutter client bulunamadı: $client\pubspec.yaml" }
$flutter = Get-Command flutter.exe -ErrorAction SilentlyContinue
if ($null -eq $flutter) { Fail 'Flutter bulunamadı.' }
if (-not $AllowUnsigned -and $Mode -eq 'release') {
    $keyProperties = Join-Path $client 'android\key.properties'
    if (-not (Test-Path -LiteralPath $keyProperties -PathType Leaf)) {
        Fail 'Release imzası için android/key.properties yok. Geliştirme çıktısı için -AllowUnsigned kullanın; script sahte imza üretmez.'
    }
}
if (-not $SkipPubGet) { Push-Location $client; try { & $flutter.Source pub get } finally { Pop-Location } }

$buildArgs = @('build', $Format, "--$Mode")
Push-Location $client
try {
    & $flutter.Source @buildArgs
    if ($LASTEXITCODE -ne 0) { Fail "Flutter Android build başarısız (exit code $LASTEXITCODE)." }
} finally { Pop-Location }

$pattern = if ($Format -eq 'appbundle') { Join-Path $client "build\app\outputs\bundle\$Mode\*.aab" } else { Join-Path $client "build\app\outputs\flutter-apk\*.apk" }
$artifacts = @(Get-ChildItem -Path $pattern -File -ErrorAction SilentlyContinue)
if ($artifacts.Count -ne 1 -or $artifacts[0].Length -le 0) { Fail "Tek ve gerçek Android artifact bulunamadı: $pattern" }
New-Item -ItemType Directory -Force -Path $out | Out-Null
$extension = if ($Format -eq 'appbundle') { '.aab' } else { '.apk' }
$destination = Join-Path $out ("alevi-android-$Mode$extension")
Copy-Item -LiteralPath $artifacts[0].FullName -Destination $destination -Force
(Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash | Set-Content -LiteralPath "$destination.sha256" -NoNewline
Write-Host "Android artifact hazır: $destination"
