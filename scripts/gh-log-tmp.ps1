$token = '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'
$h = @{ Authorization = "Bearer $token"; Accept = 'application/vnd.github+json' }
$logs = Invoke-WebRequest -UseBasicParsing 'https://api.github.com/repos/supercellidardakargyn/Alevi-Proje/actions/jobs/107335091057/logs' -Headers $h -TimeoutSec 30 -MaximumRedirection 5
$lines = ($logs.Content -split "`n")
Write-Output ("toplam-satir: " + $lines.Count)
foreach ($line in $lines) {
  if ($line -match '(?i)error|exception|throw|failed|not found|not recognized|cannot find') {
    Write-Output $line.Substring(0, [Math]::Min(300, $line.Length))
  }
}
