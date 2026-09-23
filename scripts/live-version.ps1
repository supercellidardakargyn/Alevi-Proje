$base = 'https://api.sonalis.com.tr'
function Check($label, [scriptblock]$fn, $expect) {
  try {
    $r = & $fn
    $code = [int]$r.StatusCode
  } catch {
    $resp = $_.Exception.Response
    $code = if ($resp) { [int]$resp.StatusCode } else { -1 }
  }
  $ok = if ($code -eq $expect) { 'OK' } else { 'ESKI-KOD' }
  Write-Output "$ok $label -> $code (beklenen $expect)"
}
Check 'presence (401=var)' { Invoke-WebRequest -UseBasicParsing "$base/v1/presence/active" -TimeoutSec 15 } 401
Check 'events (401=var)' { Invoke-WebRequest -UseBasicParsing "$base/v1/events" -TimeoutSec 15 } 401
Check 'forgot bos (400=var)' { Invoke-WebRequest -UseBasicParsing "$base/v1/auth/forgot-password" -Method Post -ContentType 'application/json' -Body '{}' -TimeoutSec 15 } 400
Check 'avatar yoksiz (401=var)' { Invoke-WebRequest -UseBasicParsing "$base/v1/profile/avatar" -Method Post -TimeoutSec 15 } 401
