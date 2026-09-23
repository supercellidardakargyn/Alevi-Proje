[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)] [ValidatePattern('^[A-Za-z0-9][A-Za-z0-9._-]{0,62}$')] [string] $NodeName,
    [Parameter(Mandatory = $true)] [ValidateNotNullOrEmpty()] [string] $OutputDir,
    [string] $Bootstrap = '',
    [string] $ApiDir = '',
    [string] $CliPath = '',
    [string] $NodePath = 'node.exe'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
function Fail([string] $Message) { throw "HATA: $Message" }

$node = Get-Command $NodePath -ErrorAction SilentlyContinue
if ($null -eq $node) { Fail "Node.js bulunamadı: $NodePath" }
if ([string]::IsNullOrWhiteSpace($ApiDir)) {
    $root = Split-Path -Parent $PSScriptRoot
    $ApiDir = Join-Path $root 'services\api'
}
if ([string]::IsNullOrWhiteSpace($CliPath)) { $CliPath = Join-Path $ApiDir 'dist\cli.js' }
$cli = [IO.Path]::GetFullPath($CliPath)
$out = [IO.Path]::GetFullPath($OutputDir)
if (-not (Test-Path -LiteralPath $cli -PathType Leaf)) { Fail "Mesh CLI bulunamadı: $cli; sahte sertifika üretilmeyecek." }
New-Item -ItemType Directory -Force -Path $out | Out-Null
$acl = Get-Acl -LiteralPath $out
$acl.SetAccessRuleProtection($true, $false)
$acl.Access | ForEach-Object { [void]$acl.RemoveAccessRule($_) }
$acl.AddAccessRule([Security.AccessControl.FileSystemAccessRule]::new($env:USERNAME, 'FullControl', 'ContainerInherit,ObjectInherit', 'None', 'Allow'))
Set-Acl -LiteralPath $out -AclObject $acl

$arguments = @($cli, 'mesh', 'init', '--node-name', $NodeName, '--output-dir', $out)
if (-not [string]::IsNullOrWhiteSpace($Bootstrap)) { $arguments += @('--bootstrap', $Bootstrap) }
Write-Host "Mesh init başlatılıyor: node=$NodeName output=$out"
& $node.Source @arguments
if ($LASTEXITCODE -ne 0) { Fail "Mesh CLI init başarısız (exit code $LASTEXITCODE)." }

$markers = @((Join-Path $out 'node-id'), (Join-Path $out 'node-id.txt'), (Join-Path $out 'node.json'))
if (-not ($markers | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf })) { Fail 'Mesh CLI node kimliği üretmedi; init başarısız.' }
Write-Host 'Mesh init tamamlandı. Secret/private key içerikleri gösterilmedi.'
