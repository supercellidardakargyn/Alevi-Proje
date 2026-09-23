[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)] [ValidateNotNullOrEmpty()] [string] $Bootstrap,
    [Parameter(Mandatory = $true)] [ValidatePattern('^[A-Za-z0-9][A-Za-z0-9._-]{0,62}$')] [string] $NodeName,
    [Parameter(Mandatory = $true)] [ValidateNotNullOrEmpty()] [string] $OutputDir,
    [string] $ApiDir = '',
    [string] $CliPath = '',
    [string] $NodePath = 'node.exe'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
function Fail([string] $Message) { throw "HATA: $Message" }

$token = [Environment]::GetEnvironmentVariable('MESH_JOIN_TOKEN', 'Process')
if ([string]::IsNullOrWhiteSpace($token)) { Fail 'MESH_JOIN_TOKEN process environment değişkeni eksik.' }
$node = Get-Command $NodePath -ErrorAction SilentlyContinue
if ($null -eq $node) { Fail "Node.js bulunamadı: $NodePath" }
if ([string]::IsNullOrWhiteSpace($ApiDir)) { $ApiDir = Join-Path (Split-Path -Parent $PSScriptRoot) 'services\api' }
if ([string]::IsNullOrWhiteSpace($CliPath)) { $CliPath = Join-Path $ApiDir 'dist\cli.js' }
$cli = [IO.Path]::GetFullPath($CliPath)
$out = [IO.Path]::GetFullPath($OutputDir)
if (-not (Test-Path -LiteralPath $cli -PathType Leaf)) { Fail "Mesh CLI bulunamadı: $cli; provision atlanmayacak." }
New-Item -ItemType Directory -Force -Path $out | Out-Null

$psi = [Diagnostics.ProcessStartInfo]::new()
$psi.FileName = $node.Source
$psi.WorkingDirectory = [IO.Path]::GetDirectoryName($cli)
$psi.UseShellExecute = $false
$psi.RedirectStandardInput = $true
$psi.RedirectStandardOutput = $false
$psi.RedirectStandardError = $false
foreach ($arg in @($cli, 'mesh', 'join', '--bootstrap', $Bootstrap, '--node-name', $NodeName, '--output-dir', $out, '--token-stdin')) {
    [void]$psi.ArgumentList.Add($arg)
}
$process = [Diagnostics.Process]::new()
$process.StartInfo = $psi
if (-not $process.Start()) { Fail 'Mesh CLI başlatılamadı.' }
$process.StandardInput.WriteLine($token)
$process.StandardInput.Close()
[Environment]::SetEnvironmentVariable('MESH_JOIN_TOKEN', $null, 'Process')
$process.WaitForExit()
if ($process.ExitCode -ne 0) { Fail "Mesh CLI join başarısız (exit code $($process.ExitCode))." }

$cert = Join-Path $out 'node-cert.pem'
$key = Join-Path $out 'node-key.pem'
if (-not (Test-Path -LiteralPath $cert -PathType Leaf)) { Fail 'Join sertifikası üretilmedi; katılım başarısız.' }
if (-not (Test-Path -LiteralPath $key -PathType Leaf)) { Fail 'Node private key üretilmedi; katılım başarısız.' }
Write-Host "Mesh join tamamlandı: node=$NodeName. Token ve private key gösterilmedi."
