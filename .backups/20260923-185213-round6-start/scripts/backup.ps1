[CmdletBinding()]
param([string]$Root = (Join-Path (Get-Location) '.'), [string]$Label = '')
$ErrorActionPreference = 'Stop'
$backupRoot = Join-Path $Root '.backups'
New-Item -ItemType Directory -Force -Path $backupRoot | Out-Null
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$name = if ($Label) { "$stamp-$Label" } else { $stamp }
$dest = Join-Path $backupRoot $name
$existing = Get-ChildItem -LiteralPath $backupRoot -Directory | Sort-Object Name
while ($existing.Count -ge 5) {
  Remove-Item -LiteralPath $existing[0].FullName -Recurse -Force
  $existing = Get-ChildItem -LiteralPath $backupRoot -Directory | Sort-Object Name
}
New-Item -ItemType Directory -Force -Path $dest | Out-Null
$trees = @(
  'services\api\src', 'services\api\prisma', 'services\api\package.json', 'services\api\package-lock.json',
  'services\gateway', 'packages\config\src', 'packages\config\package.json',
  'packages\contracts\src', 'packages\contracts\package.json',
  'apps\admin\app', 'apps\admin\lib', 'apps\admin\package.json', 'apps\admin\next.config.mjs',
  'apps\client\lib', 'apps\client\pubspec.yaml', 'apps\client\android\app\src\main\AndroidManifest.xml',
  'site', 'deploy', 'scripts', 'turbo.json'
)
foreach ($t in $trees) {
  $from = Join-Path $Root $t
  if (-not (Test-Path -LiteralPath $from)) { continue }
  $to = Join-Path $dest $t
  $parent = Split-Path -Parent $to
  if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
  Copy-Item -LiteralPath $from -Destination $to -Recurse -Force -Exclude @('node_modules', '.next', 'dist')
}
[pscustomobject]@{ Yedek = $name; Klasor = $dest }
Get-ChildItem -LiteralPath $backupRoot -Directory | Sort-Object Name | Select-Object Name
