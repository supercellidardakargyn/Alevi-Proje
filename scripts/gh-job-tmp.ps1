$token = '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'
$h = @{ Authorization = "Bearer $token"; Accept = 'application/vnd.github+json' }
$w = Invoke-WebRequest -UseBasicParsing 'https://api.github.com/repos/supercellidardakargyn/Alevi-Proje/actions/workflows/release-tars.yml/runs?per_page=1' -Headers $h -TimeoutSec 20
$run = ($w.Content | ConvertFrom-Json).workflow_runs[0]
Write-Output ("run: " + $run.id)
$j = Invoke-WebRequest -UseBasicParsing ("https://api.github.com/repos/supercellidardakargyn/Alevi-Proje/actions/runs/" + $run.id + "/jobs") -Headers $h -TimeoutSec 20
$jobs = ($j.Content | ConvertFrom-Json).jobs
foreach ($job in $jobs) {
  foreach ($step in $job.steps) {
    if ($step.number) { Write-Output ("adim " + $step.number + " : " + $step.name + " -> " + $step.conclusion) }
  }
}
