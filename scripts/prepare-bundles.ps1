[CmdletBinding()]
param([string]$Root = (Join-Path (Get-Location) '.'))
$ErrorActionPreference = 'Stop'

# Tum yollar egik cizgili: Windows + Linux (pwsh) uyumlu.
# Calismasi icin once uret: `npm run build` (api), `npm run build` (admin), `npm run build` (packages)
function Stage-Tree([string]$stage, [hashtable]$files) {
  if (Test-Path -LiteralPath $stage) { Remove-Item -LiteralPath $stage -Recurse -Force }
  foreach ($src in $files.Keys) {
    $from = Join-Path $Root $src
    $to = Join-Path $stage $files[$src]
    if (-not (Test-Path -LiteralPath $from)) { throw "Kaynak bulunamadi: $from" }
    $parent = Split-Path -Parent $to
    if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
    Copy-Item -LiteralPath $from -Destination $to -Recurse -Force -Exclude @('node_modules', '.next')
  }
}

function Join-Root([string]$child) {
  return Join-Path $Root ($child -replace '/', [IO.Path]::DirectorySeparatorChar)
}

$bundles = Join-Root 'dist/bundles'
New-Item -ItemType Directory -Force -Path $bundles | Out-Null

$apiFiles = @{
  'services/api/package.json'      = 'services/api/package.json'
  'services/api/package-lock.json' = 'services/api/package-lock.json'
  'services/api/dist'              = 'services/api/dist'
  'services/api/prisma'            = 'services/api/prisma'
  'packages/config/package.json'   = 'packages/config/package.json'
  'packages/config/dist'           = 'packages/config/dist'
  'packages/contracts/package.json' = 'packages/contracts/package.json'
  'packages/contracts/dist'        = 'packages/contracts/dist'
}

# --- ANA SUNUCU: `node index.js` ile acar (api + admin + gateway + site) ---
$main = Join-Path $bundles 'alevi-main'
$mainFiles = $apiFiles.Clone()
$mainFiles['deploy/node-main/index.js'] = 'index.js'
# UYARI: gercek .env ASLA paketlenmez (sunucudaki uretim degerleri sizmasin).
# Taze kurulumda `.env.example` dosyasi `.env` adiyla kopyalanip doldurulur.
$mainFiles['deploy/gateway/.env.example'] = '.env.example'
$mainFiles['deploy/KURULUM-NODE.md'] = 'KURULUM.md'
$mainFiles['site'] = 'site'
$mainFiles['services/gateway/package.json'] = 'services/gateway/package.json'
$mainFiles['services/gateway/package-lock.json'] = 'services/gateway/package-lock.json'
$mainFiles['services/gateway/index.js'] = 'services/gateway/index.js'
$mainFiles['apps/admin/.next/standalone/apps/admin'] = 'admin-standalone'
Stage-Tree $main $mainFiles
# Windows'a ozel native moduller sunucuda sorun cikarmasin diye standalone
# node_modules paketlenmez; sunucuda `node index.js` ilk acilista kurar.
Remove-Item -LiteralPath (Join-Path $main 'admin-standalone/node_modules') -Recurse -Force -ErrorAction SilentlyContinue
Copy-Item -LiteralPath (Join-Root 'apps/admin/.next/static') -Destination (Join-Path $main 'admin-standalone/.next/static') -Recurse -Force
Copy-Item -LiteralPath (Join-Root 'apps/admin/public') -Destination (Join-Path $main 'admin-standalone/public') -Recurse -Force
# Calisan koda test/map dosyalari girmez.
Get-ChildItem -LiteralPath (Join-Path $main 'services/api/dist') -Recurse -File |
  Where-Object { $_.Name -like '*.test.js' -or $_.Name -like '*.test.js.map' -or $_.Extension -eq '.map' } |
  Remove-Item -Force

# --- YAN SUNUCU: `node index.js` ile acar (api) ---
$edge = Join-Path $bundles 'alevi-edge'
$edgeFiles = $apiFiles.Clone()
$edgeFiles['deploy/node-edge/index.js'] = 'index.js'
# UYARI: gercek .env ASLA paketlenmez (bkz. ana sunucu notu).
$edgeFiles['deploy/edge/.env.example'] = '.env.example'
$edgeFiles['deploy/KURULUM-NODE.md'] = 'KURULUM.md'
Stage-Tree $edge $edgeFiles
Get-ChildItem -LiteralPath (Join-Path $edge 'services/api/dist') -Recurse -File |
  Where-Object { $_.Name -like '*.test.js' -or $_.Name -like '*.test.js.map' -or $_.Extension -eq '.map' } |
  Remove-Item -Force

$mainTar = Join-Root 'dist/alevi-main.tar.gz'
$edgeTar = Join-Root 'dist/alevi-edge.tar.gz'
if (Test-Path -LiteralPath $mainTar) { Remove-Item -LiteralPath $mainTar -Force }
if (Test-Path -LiteralPath $edgeTar) { Remove-Item -LiteralPath $edgeTar -Force }
tar -czf $mainTar -C $bundles alevi-main
tar -czf $edgeTar -C $bundles alevi-edge

foreach ($f in @($mainTar, $edgeTar)) {
  $h = (Get-FileHash -LiteralPath $f -Algorithm SHA256).Hash
  $size = (Get-Item -LiteralPath $f).Length
  [pscustomobject]@{ Paket = (Split-Path -Leaf $f); Bayt = $size; SHA256 = $h }
}

# APK + Windows zip ayri artefakt + butunluk manifestosu (surum takibi icin).
$apkSrc = Join-Root 'site/indir/can-meydani.apk'
if (Test-Path -LiteralPath $apkSrc) {
  Copy-Item -LiteralPath $apkSrc -Destination (Join-Root 'dist/can-meydani.apk') -Force
}
$winSrc = Join-Root 'site/indir/can-meydani-windows-x64.zip'
if (Test-Path -LiteralPath $winSrc) {
  Copy-Item -LiteralPath $winSrc -Destination (Join-Root 'dist/can-meydani-windows-x64.zip') -Force
}
$setupSrc = Join-Root 'site/indir/CanMeydani-Kurulum-0.6.1.exe'
if (Test-Path -LiteralPath $setupSrc) {
  Copy-Item -LiteralPath $setupSrc -Destination (Join-Root 'dist/CanMeydani-Kurulum-0.6.1.exe') -Force
}
$linuxSrc = Join-Root 'site/indir/can-meydani-linux-x64.tar.gz'
if (Test-Path -LiteralPath $linuxSrc) {
  Copy-Item -LiteralPath $linuxSrc -Destination (Join-Root 'dist/can-meydani-linux-x64.tar.gz') -Force
}
$manifest = Join-Root 'dist/SHA256SUMS.txt'
Remove-Item -LiteralPath $manifest -Force -ErrorAction SilentlyContinue
$distDir = Join-Root 'dist'
foreach ($f in @(Get-ChildItem -LiteralPath $distDir -File | Where-Object { $_.Name -like '*.tar.gz' -or $_.Name -like '*.apk' -or $_.Name -like '*.zip' -or $_.Name -like '*.exe' })) {
  $h = (Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash
  Add-Content -LiteralPath $manifest "$h  $($f.Name)"
}
Get-Content -LiteralPath $manifest
