[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $ReleaseDir,

    [string] $ServiceName = 'AleviApi',
    [string] $ServiceDisplayName = 'Alevi API',
    [string] $ServiceAccount = 'LocalService',
    [string] $HealthUrl = 'http://127.0.0.1:3000/health/live',
    [string] $WinSwPath = '',
    [switch] $SkipService
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Fail([string] $Message) {
    throw "HATA: $Message"
}

function Assert-Administrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Fail 'Bu script Yönetici PowerShell ile çalıştırılmalıdır.'
    }
}

function Find-Node {
    $node = Get-Command node.exe -ErrorAction SilentlyContinue
    if ($null -eq $node) { Fail 'Node.js bulunamadı.' }
    $version = (& $node.Source --version).Trim()
    if ($version -notmatch '^v(\d+)') { Fail "Node.js sürümü okunamadı: $version" }
    if ([int]$Matches[1] -lt 20) { Fail "Node.js 20 veya üzeri gerekir (bulunan: $version)." }
    return $node.Source
}

Assert-Administrator
$nodePath = Find-Node
$resolvedReleaseDir = [IO.Path]::GetFullPath($ReleaseDir)
$entryPoint = Join-Path $resolvedReleaseDir 'dist\main.js'
$packageJson = Join-Path $resolvedReleaseDir 'package.json'
if (-not (Test-Path -LiteralPath $resolvedReleaseDir -PathType Container)) { Fail "Release dizini yok: $resolvedReleaseDir" }
if (-not (Test-Path -LiteralPath $packageJson -PathType Leaf)) { Fail "Release dizininde package.json yok: $resolvedReleaseDir" }
if (-not (Test-Path -LiteralPath $entryPoint -PathType Leaf)) { Fail 'Release dizininde dist\main.js yok; sahte servis kurulmayacak.' }

$stateRoot = Join-Path $env:ProgramData 'Alevi'
$logDir = Join-Path $stateRoot 'logs'
$envDir = Join-Path $stateRoot 'config'
New-Item -ItemType Directory -Force -Path $stateRoot, $logDir, $envDir | Out-Null

# Secret olmayan varsayılanlar; gerçek secret değerleri Windows Credential Manager/secret manager üzerinden verilir.
$envFile = Join-Path $envDir 'alevi-api.env'
if (-not (Test-Path -LiteralPath $envFile)) {
    @(
        '# Secret olmayan servis ayarları. Secretları bu dosyaya yazmayın.',
        'NODE_ENV=production',
        'PORT=3000',
        '# DATABASE_URL, REDIS_URL ve encryption key secret managerdan sağlanır.'
    ) | Set-Content -LiteralPath $envFile -Encoding UTF8 -NoNewline
}

# Release private key/config dosyalarına LocalService dışında varsayılan erişim bırakma.
$acl = Get-Acl -LiteralPath $resolvedReleaseDir
$acl.SetAccessRuleProtection($true, $false)
foreach ($accessRule in @($acl.Access)) {
    [void]$acl.RemoveAccessRule($accessRule)
}
$rule = [Security.AccessControl.FileSystemAccessRule]::new('NT AUTHORITY\LOCAL SERVICE', 'ReadAndExecute', 'ContainerInherit,ObjectInherit', 'None', 'Allow')
$acl.AddAccessRule($rule)
Set-Acl -LiteralPath $resolvedReleaseDir -AclObject $acl

if ($SkipService) {
    Write-Host "Dosya/izin kurulumu tamamlandı; servis kaydı -SkipService ile atlandı."
    exit 0
}

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$serviceInstaller = Join-Path $scriptRoot '..\deploy\windows-service\install-service.ps1'
if (-not (Test-Path -LiteralPath $serviceInstaller -PathType Leaf)) {
    Fail "Windows servis installer bulunamadı: $serviceInstaller"
}

$installerArgs = @{
    ServiceName = $ServiceName
    DisplayName = $ServiceDisplayName
    ReleaseDir = $resolvedReleaseDir
    NodePath = $nodePath
    EnvFile = $envFile
    LogDir = $logDir
    ServiceAccount = $ServiceAccount
}
if (-not [string]::IsNullOrWhiteSpace($WinSwPath)) { $installerArgs.WinSwPath = $WinSwPath }
& $serviceInstaller @installerArgs
if ($LASTEXITCODE -ne 0) { Fail "Windows servis kaydı başarısız oldu (exit code $LASTEXITCODE)." }

Start-Sleep -Seconds 2
$service = Get-Service -Name $ServiceName -ErrorAction Stop
if ($service.Status -ne 'Running') { Fail "Servis çalışmıyor: $($service.Status)" }

try {
    $health = Invoke-WebRequest -Uri $HealthUrl -UseBasicParsing -TimeoutSec 10
    if ($health.StatusCode -lt 200 -or $health.StatusCode -ge 300) { Fail "Health kontrolü başarısız: HTTP $($health.StatusCode)" }
} catch {
    Fail "Health kontrolü başarısız: $HealthUrl. Sahte başarı raporlanmayacak. Ayrıntı: $($_.Exception.Message)"
}

Write-Host "Servis kuruldu ve canlılık kontrolü geçti: $ServiceName"
