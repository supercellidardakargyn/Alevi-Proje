[CmdletBinding()]
param(
    [ValidateSet('debug', 'profile', 'release')]
    [string] $Configuration = 'release',
    [string] $ClientDir = '',
    [string] $OutputDir = '',
    [switch] $CreateMsix,
    [switch] $AllowUnsigned,
    [switch] $SkipPubGet
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
function Fail([string] $Message) { throw "HATA: $Message" }

$root = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($ClientDir)) { $ClientDir = Join-Path $root 'apps\client' }
if ([string]::IsNullOrWhiteSpace($OutputDir)) { $OutputDir = Join-Path $root 'dist\windows' }
$client = [IO.Path]::GetFullPath($ClientDir)
$out = [IO.Path]::GetFullPath($OutputDir)
if (-not (Test-Path -LiteralPath (Join-Path $client 'pubspec.yaml') -PathType Leaf)) { Fail "Flutter client bulunamadı: $client\pubspec.yaml" }
if (-not (Test-Path -LiteralPath (Join-Path $client 'windows') -PathType Container)) { Fail "Windows Flutter projesi bulunamadı: $client\windows" }
$flutter = Get-Command flutter.exe -ErrorAction SilentlyContinue
if ($null -eq $flutter) { Fail 'Flutter bulunamadı.' }
if (-not $AllowUnsigned -and $Configuration -eq 'release' -and $CreateMsix) {
    if ([string]::IsNullOrWhiteSpace($env:WINDOWS_SIGNING_CERT_THUMBPRINT) -and [string]::IsNullOrWhiteSpace($env:WINDOWS_SIGNING_PFX_PATH)) {
        Fail 'MSIX release signing bilgisi yok. WINDOWS_SIGNING_CERT_THUMBPRINT veya WINDOWS_SIGNING_PFX_PATH sağlayın; sahte imza üretilmez.'
    }
}
if (-not $SkipPubGet) { Push-Location $client; try { & $flutter.Source pub get } finally { Pop-Location } }
Push-Location $client
try {
    & $flutter.Source build windows --$Configuration
    if ($LASTEXITCODE -ne 0) { Fail "Flutter Windows build başarısız (exit code $LASTEXITCODE)." }
    if ($CreateMsix) {
        $dart = Get-Command dart.exe -ErrorAction SilentlyContinue
        if ($null -eq $dart) { Fail 'Dart bulunamadı; msix paketleme yapılamaz.' }
        & $dart.Source run msix:create --build-windows false
        if ($LASTEXITCODE -ne 0) { Fail "MSIX paketleme başarısız (exit code $LASTEXITCODE)." }
    }
} finally { Pop-Location }

$patterns = if ($CreateMsix) { @((Join-Path $client '**\*.msix')) } else { @((Join-Path $client 'build\windows\x64\runner\Release\*')) }
if ($CreateMsix) {
    $artifacts = @(Get-ChildItem -Path (Join-Path $client '**\*.msix') -File -Recurse -ErrorAction SilentlyContinue)
    if ($artifacts.Count -ne 1 -or $artifacts[0].Length -le 0) { Fail 'Tek ve gerçek MSIX çıktısı bulunamadı.' }
    $extension = '.msix'
} else {
    $artifacts = @(Get-ChildItem -Path (Join-Path $client 'build\windows\x64\runner\Release') -File -Recurse -ErrorAction SilentlyContinue)
    if ($artifacts.Count -eq 0) { Fail 'Windows release çıktı klasörü boş.' }
    # Unsigned desktop release is a directory; package it only after a real build.
    $extension = '.zip'
}
New-Item -ItemType Directory -Force -Path $out | Out-Null
if ($CreateMsix) {
    $destination = Join-Path $out 'alevi-windows.msix'
    Copy-Item -LiteralPath $artifacts[0].FullName -Destination $destination -Force
} else {
    $destination = Join-Path $out 'alevi-windows-release.zip'
    Compress-Archive -Path (Join-Path $client 'build\windows\x64\runner\Release\*') -DestinationPath $destination -Force
}
if (-not (Test-Path -LiteralPath $destination) -or (Get-Item -LiteralPath $destination).Length -le 0) { Fail 'Çıktı boş; sahte artifact kabul edilmez.' }
(Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash | Set-Content -LiteralPath "$destination.sha256" -NoNewline
Write-Host "Windows çıktısı hazır: $destination"
