param(
  [string]$ApiBaseUrl = $env:API_BASE_URL
)

$ErrorActionPreference = "Stop"
if ([string]::IsNullOrWhiteSpace($ApiBaseUrl)) {
  $ApiBaseUrl = "https://api.example.com/v1"
}

flutter pub get
flutter build windows --release --dart-define=API_BASE_URL=$ApiBaseUrl --dart-define=MOCK_DATA=false
dart run msix:create --build-windows
