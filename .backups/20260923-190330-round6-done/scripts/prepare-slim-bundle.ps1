[CmdletBinding()]
param([string]$Root = (Get-Location).Path)
$ErrorActionPreference = 'Stop'
$stage = Join-Path $Root 'dist\slim-bundle'
if (Test-Path -LiteralPath $stage) { Remove-Item -LiteralPath $stage -Recurse -Force }
New-Item -ItemType Directory -Force -Path "$stage\services\api\dist", "$stage\services\api\prisma", "$stage\packages\config\dist", "$stage\packages\contracts\dist" | Out-Null
Copy-Item -LiteralPath (Join-Path $Root 'services\api\package.json') -Destination (Join-Path $stage 'services\api')
Copy-Item -LiteralPath (Join-Path $Root 'services\api\.env.example') -Destination (Join-Path $stage 'services\api')
Copy-Item -LiteralPath (Join-Path $Root 'services\api\prisma\schema.prisma') -Destination (Join-Path $stage 'services\api\prisma')
$apiDist = Join-Path $Root 'services\api\dist'
Get-ChildItem -LiteralPath $apiDist -Recurse -File | Where-Object Extension -ne '.map' | ForEach-Object {
  $relative = $_.FullName.Substring($apiDist.Length).TrimStart('\')
  $destination = Join-Path (Join-Path $stage 'services\api\dist') $relative
  New-Item -ItemType Directory -Force -Path (Split-Path -Parent $destination) | Out-Null
  Copy-Item -LiteralPath $_.FullName -Destination $destination
}
foreach ($package in @('config','contracts')) {
  $src = Join-Path $Root "packages\$package"
  $dst = Join-Path $stage "packages\$package"
  Copy-Item -LiteralPath (Join-Path $src 'package.json') -Destination $dst
  $dist = Join-Path $src 'dist'
  Get-ChildItem -LiteralPath $dist -Recurse -File | Where-Object Extension -ne '.map' | ForEach-Object {
    Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $dst 'dist')
  }
}
$archive = Join-Path $Root 'dist\alevi-slim.tar.gz'
if (Test-Path -LiteralPath $archive) { Remove-Item -LiteralPath $archive -Force }
tar -czf $archive -C $stage .
$base64 = "$archive.b64"
[Convert]::ToBase64String([IO.File]::ReadAllBytes($archive)) | Set-Content -NoNewline -LiteralPath $base64
$chunks = Join-Path $Root 'dist\slim-chunks'
if (Test-Path -LiteralPath $chunks) { Remove-Item -LiteralPath $chunks -Recurse -Force }
New-Item -ItemType Directory -Force -Path $chunks | Out-Null
$text = [IO.File]::ReadAllText($base64)
$chunkSize = 12000
for ($offset = 0; $offset -lt $text.Length; $offset += $chunkSize) {
  $length = [Math]::Min($chunkSize, $text.Length - $offset)
  [IO.File]::WriteAllText((Join-Path $chunks ('chunk{0:D2}.txt' -f [int]($offset / $chunkSize))), $text.Substring($offset, $length))
}
[pscustomobject]@{ Archive = $archive; Bytes = (Get-Item $archive).Length; Base64 = $base64; Chunks = (Get-ChildItem $chunks -File).Count }
