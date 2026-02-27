param(
  [string]$EvidenceRoot = "docs/runtime_evidence"
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$evidencePath = Join-Path $repoRoot $EvidenceRoot
if (!(Test-Path $evidencePath)) {
  throw "Evidence path not found: $evidencePath"
}

$latestSummary = Get-ChildItem -Path $evidencePath -Recurse -Filter "phase4_daily_summary_*.md" |
  Sort-Object LastWriteTime -Descending |
  Select-Object -First 1

if ($null -eq $latestSummary) {
  throw "No phase4 daily summary found in $evidencePath"
}

$content = Get-Content -Path $latestSummary.FullName -Raw
$isGo = $content -match "Decision:\s+\*\*GO\*\*"
$isNoGo = $content -match "Decision:\s+\*\*NO-GO\*\*"

$dateDir = Split-Path -Parent $latestSummary.FullName
$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$statusFile = Join-Path $dateDir ("phase6_no_go_guard_" + $stamp + ".txt")

if ($isGo) {
  "GO_OK: latest summary is GO ($($latestSummary.Name))" | Set-Content -Path $statusFile -Encoding utf8
  Write-Host "NO-GO guard: GO"
  exit 0
}

if ($isNoGo) {
  $alertFile = Join-Path $dateDir ("phase6_no_go_alert_" + $stamp + ".txt")
  @(
    "NO_GO_ALERT"
    ("summary_file=" + $latestSummary.FullName)
    ("detected_at=" + (Get-Date -Format s))
  ) | Set-Content -Path $alertFile -Encoding utf8
  "NO_GO_FAIL: latest summary is NO-GO ($($latestSummary.Name))" | Set-Content -Path $statusFile -Encoding utf8
  Write-Host "NO-GO guard: NO-GO"
  exit 2
}

"NO_GO_FAIL: decision not parsable in $($latestSummary.Name)" | Set-Content -Path $statusFile -Encoding utf8
Write-Host "NO-GO guard: decision parsing failed"
exit 3
