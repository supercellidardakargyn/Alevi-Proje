[CmdletBinding()]
param(
    [string] $ServiceName = 'AleviApi',
    [string] $WinSwPath = ''
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Fail([string] $Message) { throw "HATA: $Message" }
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Fail 'Servis kaldırma Yönetici PowerShell ile çalıştırılmalıdır.'
}

$serviceDir = Join-Path $env:ProgramData "Alevi\services\$ServiceName"
if ([string]::IsNullOrWhiteSpace($WinSwPath)) { $WinSwPath = Join-Path $serviceDir "$ServiceName.exe" }
if (-not (Test-Path -LiteralPath $WinSwPath -PathType Leaf)) {
    Write-Warning "WinSW binary bulunamadı; Windows servis kaydı sc.exe ile temizleniyor."
    & sc.exe stop $ServiceName | Out-Null
    & sc.exe delete $ServiceName | Out-Null
} else {
    & $WinSwPath stop | Out-Null
    & $WinSwPath uninstall | Out-Null
}
if (Test-Path -LiteralPath $serviceDir) { Remove-Item -LiteralPath $serviceDir -Recurse -Force }
Write-Host "Windows servisi kaldırıldı: $ServiceName"
