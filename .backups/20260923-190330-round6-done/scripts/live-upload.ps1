$base = 'https://api.sonalis.com.tr'
$tmp = [System.IO.Path]::GetTempFileName() + '.png'
[System.IO.File]::WriteAllBytes($tmp, [byte[]]@(137,80,78,71,13,10,26,10,0,0,0,13,73,72,68,82))
try {
  $t = [System.Diagnostics.Stopwatch]::StartNew()
  $r = Invoke-WebRequest -UseBasicParsing "$base/v1/profile/avatar" -Method Post -Form @{avatar = Get-Item $tmp} -TimeoutSec 30
  $t.Stop()
  Write-Output "status: $([int]$r.StatusCode) sure: $($t.Elapsed.TotalSeconds)s"
  Write-Output $r.Content
} catch {
  Write-Output "HATA: $($_.Exception.Message)"
  $resp = $_.Exception.Response
  if ($resp) { Write-Output "status: $([int]$resp.StatusCode)" }
}
Remove-Item $tmp -Force
