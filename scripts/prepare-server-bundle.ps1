[CmdletBinding()]
param([string]$Root = (Join-Path (Get-Location) '.'))
$ErrorActionPreference = 'Stop'
$stage = Join-Path $Root 'dist\server-bundle'
if (Test-Path -LiteralPath $stage) { Remove-Item -LiteralPath $stage -Recurse -Force }
New-Item -ItemType Directory -Force -Path "$stage\services\api", "$stage\packages\config", "$stage\packages\contracts" | Out-Null
Copy-Item -LiteralPath "$Root\services\api\dist" -Destination "$stage\services\api\dist" -Recurse
Copy-Item -LiteralPath "$Root\services\api\prisma" -Destination "$stage\services\api\prisma" -Recurse
Copy-Item -LiteralPath "$Root\services\api\package.json", "$Root\services\api\package-lock.json", "$Root\services\api\.env.example" -Destination "$stage\services\api"
Copy-Item -LiteralPath "$Root\packages\config\dist" -Destination "$stage\packages\config\dist" -Recurse
Copy-Item -LiteralPath "$Root\packages\config\package.json", "$Root\packages\config\package-lock.json" -Destination "$stage\packages\config"
Copy-Item -LiteralPath "$Root\packages\contracts\dist" -Destination "$stage\packages\contracts\dist" -Recurse
Copy-Item -LiteralPath "$Root\packages\contracts\package.json", "$Root\packages\contracts\package-lock.json" -Destination "$stage\packages\contracts"
$files = Get-ChildItem -LiteralPath $stage -Recurse -File
[pscustomobject]@{ Directory = $stage; Files = $files.Count; Bytes = ($files | Measure-Object -Property Length -Sum).Sum }
