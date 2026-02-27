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
  throw "No phase4 daily summary found."
}

$dateDir = Split-Path -Parent $latestSummary.FullName
$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$execFile = Join-Path $dateDir ("phase7_executive_status_" + $stamp + ".txt")

$summary = Get-Content -Path $latestSummary.FullName -Raw
$decision = if ($summary -match "Decision:\s+\*\*(GO|NO-GO)\*\*") { $Matches[1] } else { "UNKNOWN" }
$coreCheck = if ($summary -match "HA core check:\s+(PASS|FAIL)") { $Matches[1] } else { "UNKNOWN" }
$bootCheck = if ($summary -match "Current boot Phase1 errors:\s+(PASS|FAIL)") { $Matches[1] } else { "UNKNOWN" }
$writerCheck = if ($summary -match "Phase1 writer service scan:\s+(PASS|FAIL)") { $Matches[1] } else { "UNKNOWN" }

$taskName = "CasaMercurio-Phase4-DailyRuntimeReport"
$taskState = "UNKNOWN"
$taskNextRun = "UNKNOWN"
$taskLastResult = "UNKNOWN"
try {
  $task = Get-ScheduledTask -TaskName $taskName -ErrorAction Stop
  $info = Get-ScheduledTaskInfo -TaskName $taskName -ErrorAction Stop
  $taskState = [string]$task.State
  $taskNextRun = [string]$info.NextRunTime
  $taskLastResult = [string]$info.LastTaskResult
} catch {
}

$lines = @()
$lines += "EXECUTIVE_STATUS"
$lines += ("timestamp=" + (Get-Date -Format s))
$lines += ("decision=" + $decision)
$lines += ("ha_core_check=" + $coreCheck)
$lines += ("current_boot_check=" + $bootCheck)
$lines += ("writer_scan_check=" + $writerCheck)
$lines += ("task_state=" + $taskState)
$lines += ("task_next_run=" + $taskNextRun)
$lines += ("task_last_result=" + $taskLastResult)
$lines += ("source_summary=" + $latestSummary.FullName)

$lines | Set-Content -Path $execFile -Encoding utf8
Write-Host "Executive status file: $execFile"
