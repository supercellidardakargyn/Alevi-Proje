[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)] [string] $ServiceName,
    [Parameter(Mandatory = $true)] [string] $DisplayName,
    [Parameter(Mandatory = $true)] [string] $ReleaseDir,
    [Parameter(Mandatory = $true)] [string] $NodePath,
    [Parameter(Mandatory = $true)] [string] $EnvFile,
    [Parameter(Mandatory = $true)] [string] $LogDir,
    [ValidateSet('LocalService', 'NetworkService', 'LocalSystem')]
    [string] $ServiceAccount = 'LocalService',
    [string] $WinSwPath = ''
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Fail([string] $Message) { throw "HATA: $Message" }

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Fail 'Servis kaydı Yönetici PowerShell ile çalıştırılmalıdır.'
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$template = Join-Path $scriptDir 'alevi-api.xml.template'
if (-not (Test-Path -LiteralPath $template -PathType Leaf)) { Fail "WinSW template yok: $template" }

if ([string]::IsNullOrWhiteSpace($WinSwPath)) {
    $candidate = Join-Path $scriptDir 'AleviApi.exe'
    if (Test-Path -LiteralPath $candidate -PathType Leaf) { $WinSwPath = $candidate }
}
if ([string]::IsNullOrWhiteSpace($WinSwPath) -or -not (Test-Path -LiteralPath $WinSwPath -PathType Leaf)) {
    Fail 'WinSW executable bulunamadı. Güvenilir WinSW binarysini deploy/windows-service/AleviApi.exe olarak sağlayın veya -WinSwPath verin.'
}

$release = [IO.Path]::GetFullPath($ReleaseDir)
$node = [IO.Path]::GetFullPath($NodePath)
$envPath = [IO.Path]::GetFullPath($EnvFile)
$logs = [IO.Path]::GetFullPath($LogDir)
$entrypoint = Join-Path $release 'dist\main.js'
foreach ($path in @($release, $node, $envPath, $entrypoint)) {
    if (-not (Test-Path -LiteralPath $path)) { Fail "Gerekli yol bulunamadı: $path" }
}
New-Item -ItemType Directory -Force -Path $logs | Out-Null

$xml = Get-Content -LiteralPath $template -Raw
$replacements = @{
    '__ALEVI_SERVICE_NAME__' = $ServiceName
    '__ALEVI_DISPLAY_NAME__' = $DisplayName
    '__ALEVI_NODE_PATH__' = $node
    '__ALEVI_ENTRYPOINT__' = $entrypoint
    '__ALEVI_RELEASE_DIR__' = $release
    '__ALEVI_ENV_FILE__' = $envPath
    '__ALEVI_LOG_DIR__' = $logs
}
foreach ($key in $replacements.Keys) {
    $xml = $xml.Replace($key, [string]$replacements[$key])
}

$serviceDir = Join-Path $env:ProgramData "Alevi\services\$ServiceName"
New-Item -ItemType Directory -Force -Path $serviceDir | Out-Null
$configPath = Join-Path $serviceDir "$ServiceName.xml"
$wrapperPath = Join-Path $serviceDir "$ServiceName.exe"
Copy-Item -LiteralPath $WinSwPath -Destination $wrapperPath -Force
Set-Content -LiteralPath $configPath -Value $xml -Encoding UTF8 -NoNewline

# WinSW must be invoked from its own service directory so it finds the XML.
$existing = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
if ($null -ne $existing) {
    if ($existing.Status -ne 'Stopped') { Stop-Service -Name $ServiceName -Force -ErrorAction SilentlyContinue }
    & $wrapperPath stop | Out-Null
    & $wrapperPath uninstall | Out-Null
}

# WinSW reads the adjacent XML file and its <id>; command arguments are not
# service names, so invoking `install <name>` would fail on standard WinSW.
& $wrapperPath install
if ($LASTEXITCODE -ne 0) { Fail "WinSW install başarısız (exit code $LASTEXITCODE)." }

$serviceAccountName = switch ($ServiceAccount) {
    'LocalService' { 'NT AUTHORITY\LocalService' }
    'NetworkService' { 'NT AUTHORITY\NetworkService' }
    'LocalSystem' { 'LocalSystem' }
    default { Fail "Desteklenmeyen servis hesabı: $ServiceAccount" }
}
# WinSW defaults vary by version; make the least-privilege account explicit.
& sc.exe config $ServiceName obj= $serviceAccountName password= '' | Out-Null
if ($LASTEXITCODE -ne 0) { Fail "Windows servis hesabı yapılandırılamadı (exit code $LASTEXITCODE)." }
& $wrapperPath start
if ($LASTEXITCODE -ne 0) { Fail "WinSW start başarısız (exit code $LASTEXITCODE)." }

Set-Service -Name $ServiceName -DisplayName $DisplayName -StartupType Automatic
Write-Host "Windows servisi kuruldu: $ServiceName ($ServiceAccount)"
