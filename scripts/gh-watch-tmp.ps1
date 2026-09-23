$token = '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'
$h = @{ Authorization = "Bearer $token"; Accept = 'application/vnd.github+json' }
for ($i = 1; $i -le 15; $i++) {
  try {
    $w = Invoke-WebRequest -UseBasicParsing 'https://api.github.com/repos/supercellidardakargyn/Alevi-Proje/actions/workflows/release-tars.yml/runs?per_page=1' -Headers $h -TimeoutSec 20
    $run = ($w.Content | ConvertFrom-Json).workflow_runs[0]
    Write-Output ("kontrol $i : " + $run.status + " / " + $run.conclusion)
    if ($run.status -eq 'completed' -and $run.conclusion -eq 'success') {
      try {
        $rel = Invoke-WebRequest -UseBasicParsing 'https://api.github.com/repos/supercellidardakargyn/Alevi-Proje/releases/tags/latest' -Headers $h -TimeoutSec 20
        $rj = ($rel.Content | ConvertFrom-Json)
        Write-Output 'YESIL: latest yayinda'
        foreach ($a in $rj.assets) { Write-Output ('  - ' + $a.name + ' ' + $a.size) }
      } catch {
        Write-Output 'YESIL: derleme bitti, release henuz dusmemis'
      }
      exit 0
    }
    if ($run.status -eq 'completed') {
      Write-Output 'PATLADI: sonuc basarisiz'
      exit 1
    }
  } catch {
    Write-Output ("API hatasi, tekrar denenecek")
  }
  Start-Sleep -Seconds 120
}
Write-Output 'SURE-DOLDU: 30 dakikada yesil olmadi'
exit 2
