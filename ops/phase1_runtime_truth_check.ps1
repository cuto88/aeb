param(
  [string]$HaHost = "root@192.168.178.84",
  [int]$Port = 2222,
  [string]$KeyPath = "C:\Users\randalab\.ssh\ha_ed25519",
  [int]$LogLines = 500
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$dateDir = Join-Path $repoRoot ("docs\runtime_evidence\" + (Get-Date -Format "yyyy-MM-dd"))
New-Item -ItemType Directory -Force -Path $dateDir | Out-Null

$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile = Join-Path $dateDir ("phase1_runtime_truth_logs_" + $stamp + ".txt")
$scanFile = Join-Path $dateDir ("phase1_runtime_truth_scan_" + $stamp + ".txt")
$scanCurrentBootFile = Join-Path $dateDir ("phase1_runtime_truth_scan_current_boot_" + $stamp + ".txt")
$writerFile = Join-Path $dateDir ("phase1_runtime_truth_writer_scan_" + $stamp + ".txt")

$sshExe = "C:\Windows\System32\OpenSSH\ssh.exe"
$pwshExe = "C:\Program Files\PowerShell\7\pwsh.exe"

$remoteCmd = "ha core logs -n $LogLines -v"
$fullCmd = "& '$sshExe' -p $Port -i '$KeyPath' $HaHost '$remoteCmd'"
& $pwshExe -Command $fullCmd | Out-File -FilePath $logFile -Encoding utf8

$patterns = @(
  "Setup of package 'climateops_phase1_kpi'",
  "integration 'history_stats' cannot be merged",
  "Sensor sensor.climateops_kpi_comfort_band_percent_today",
  "Sensor sensor.climateops_kpi_vmc_boost_minutes_today",
  "non-numeric value",
  "ValueError"
)

$allLogLines = Get-Content -Path $logFile
$matches = $allLogLines | Select-String -Pattern $patterns -SimpleMatch
if ($matches) {
  $matches | ForEach-Object { $_.Line } | Set-Content -Path $scanFile -Encoding utf8
} else {
  "NO_PHASE1_ERRORS_MATCHED" | Set-Content -Path $scanFile -Encoding utf8
}

$bootMarkers = @(
  "Home Assistant Core service shutdown",
  "custom integration hacs",
  "custom integration nodered"
)
$lastBootIndex = -1
for ($i = 0; $i -lt $allLogLines.Count; $i++) {
  foreach ($marker in $bootMarkers) {
    if ($allLogLines[$i] -like "*$marker*") {
      $lastBootIndex = $i
    }
  }
}

if ($lastBootIndex -ge 0) {
  $currentBootLines = $allLogLines[($lastBootIndex)..($allLogLines.Count - 1)]
} else {
  $currentBootLines = $allLogLines
}

$currentBootMatches = $currentBootLines | Select-String -Pattern $patterns -SimpleMatch
if ($currentBootMatches) {
  $currentBootMatches | ForEach-Object { $_.Line } | Set-Content -Path $scanCurrentBootFile -Encoding utf8
} else {
  "NO_PHASE1_ERRORS_IN_CURRENT_BOOT_WINDOW" | Set-Content -Path $scanCurrentBootFile -Encoding utf8
}

$phase1Files = @(
  "$repoRoot\packages\climateops_phase1_kpi.yaml",
  "$repoRoot\packages\climateops_phase1_planner_dryrun.yaml"
)
$writerPattern = "switch.turn_|climate\.set_temperature|service:"
$rgCmd = Get-Command rg -ErrorAction SilentlyContinue
if ($null -ne $rgCmd) {
  $writerMatches = & $rgCmd.Source -n $writerPattern $phase1Files -S
  if ($LASTEXITCODE -eq 0 -and $writerMatches) {
    $writerMatches | Set-Content -Path $writerFile -Encoding utf8
  } else {
    "NO_WRITER_SERVICES_IN_PHASE1_FILES" | Set-Content -Path $writerFile -Encoding utf8
  }
} else {
  $psMatches = Select-String -Path $phase1Files -Pattern $writerPattern
  if ($psMatches) {
    $psMatches | ForEach-Object {
      "{0}:{1}:{2}" -f $_.Path, $_.LineNumber, $_.Line.Trim()
    } | Set-Content -Path $writerFile -Encoding utf8
  } else {
    "NO_WRITER_SERVICES_IN_PHASE1_FILES" | Set-Content -Path $writerFile -Encoding utf8
  }
}

Write-Host "Runtime log file : $logFile"
Write-Host "Phase1 scan file : $scanFile"
Write-Host "Current boot scan: $scanCurrentBootFile"
Write-Host "Writer scan file : $writerFile"
