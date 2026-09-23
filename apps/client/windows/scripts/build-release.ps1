param(
  [string]$ApiBaseUrl = $env:API_BASE_URL,
  [string]$OutputDir = "build/windows/release"
)

$ErrorActionPreference = "Stop"
if ([string]::IsNullOrWhiteSpace($ApiBaseUrl)) {
  $ApiBaseUrl = "https://api.example.com/v1"
}

Write-Host "Building Alevi Windows release against $ApiBaseUrl"
flutter config --enable-windows
flutter pub get
flutter build windows --release --dart-define=API_BASE_URL=$ApiBaseUrl --dart-define=MOCK_DATA=false

if (Test-Path $OutputDir) {
  Write-Host "Output available at $OutputDir"
}
