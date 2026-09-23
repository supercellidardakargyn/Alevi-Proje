$base = 'https://api.sonalis.com.tr'
try {
  $r = Invoke-WebRequest -UseBasicParsing "$base/v1/auth/login" -Method Post -ContentType 'application/json' -Body '{"email":"yok@ornek.com","password":"yanlis-sifre-1234"}' -TimeoutSec 40
  Write-Output "status: $([int]$r.StatusCode)"
  Write-Output $r.Content
} catch {
  $resp = $_.Exception.Response
  Write-Output "status: $([int]$resp.StatusCode)"
  $stream = $resp.GetResponseStream()
  $reader = New-Object System.IO.StreamReader($stream)
  Write-Output $reader.ReadToEnd()
}
