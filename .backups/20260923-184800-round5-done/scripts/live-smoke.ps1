$base = 'https://api.sonalis.com.tr'
function Check($label, [scriptblock]$fn, $expect) {
  try {
    $r = & $fn
    $code = [int]$r.StatusCode
  } catch {
    $resp = $_.Exception.Response
    $code = if ($resp) { [int]$resp.StatusCode } else { -1 }
  }
  $ok = if ($code -eq $expect) { 'OK' } else { 'HATALI' }
  Write-Output "$ok $label -> $code (beklenen $expect)"
}
Check '/' { Invoke-WebRequest -UseBasicParsing "$base/" -TimeoutSec 15 } 200
Check '/health/live' { Invoke-WebRequest -UseBasicParsing "$base/health/live" -TimeoutSec 15 } 200
Check 'register bos govde' { Invoke-WebRequest -UseBasicParsing "$base/v1/auth/register" -Method Post -ContentType 'application/json' -Body '{}' -TimeoutSec 15 } 400
Check 'login yanlis' { Invoke-WebRequest -UseBasicParsing "$base/v1/auth/login" -Method Post -ContentType 'application/json' -Body '{"email":"yok@ornek.com","password":"yanlis-sifre-1234"}' -TimeoutSec 20 } 401
Check 'admin-login yanlis' { Invoke-WebRequest -UseBasicParsing "$base/v1/auth/admin-login" -Method Post -ContentType 'application/json' -Body '{"email":"yok@ornek.com","password":"yanlis-sifre-1234"}' -TimeoutSec 20 } 401
Check 'discover tokensiz' { Invoke-WebRequest -UseBasicParsing "$base/v1/discover" -TimeoutSec 15 } 401
Check 'events tokensiz' { Invoke-WebRequest -UseBasicParsing "$base/v1/events" -TimeoutSec 15 } 401
