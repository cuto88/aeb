$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$dateDir = Join-Path $repoRoot ("docs\runtime_evidence\" + (Get-Date -Format "yyyy-MM-dd"))
New-Item -ItemType Directory -Force -Path $dateDir | Out-Null

$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile = Join-Path $dateDir ("phase5_scheduler_run_" + $stamp + ".log")

try {
  "Runner start: $(Get-Date -Format s)" | Tee-Object -FilePath $logFile -Append | Out-Null
  & powershell -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "phase4_daily_runtime_report.ps1") 2>&1 |
    Tee-Object -FilePath $logFile -Append | Out-Null
  if ($LASTEXITCODE -ne 0) {
    throw "phase4_daily_runtime_report.ps1 failed (RC=$LASTEXITCODE)"
  }
  & powershell -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "phase6_no_go_guard.ps1") 2>&1 |
    Tee-Object -FilePath $logFile -Append | Out-Null
  if ($LASTEXITCODE -ne 0) {
    throw "phase6_no_go_guard.ps1 failed (RC=$LASTEXITCODE)"
  }
  & powershell -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "retention_runtime_evidence.ps1") 2>&1 |
    Tee-Object -FilePath $logFile -Append | Out-Null
  if ($LASTEXITCODE -ne 0) {
    throw "retention_runtime_evidence.ps1 failed (RC=$LASTEXITCODE)"
  }
  & powershell -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "phase7_executive_status.ps1") 2>&1 |
    Tee-Object -FilePath $logFile -Append | Out-Null
  if ($LASTEXITCODE -ne 0) {
    throw "phase7_executive_status.ps1 failed (RC=$LASTEXITCODE)"
  }
  "Runner end: OK $(Get-Date -Format s)" | Tee-Object -FilePath $logFile -Append | Out-Null
  exit 0
} catch {
  "Runner end: FAIL $(Get-Date -Format s)" | Tee-Object -FilePath $logFile -Append | Out-Null
  $_.Exception.Message | Tee-Object -FilePath $logFile -Append | Out-Null
  exit 1
}
