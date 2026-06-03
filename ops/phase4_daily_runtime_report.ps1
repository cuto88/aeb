param(
  [switch]$RunRestart,
  [string]$HaHost = "dscomparin@192.168.178.110",
  [int]$Port = 22,
  [string]$KeyPath = $(if ($env:HA_SSH_KEY_PATH) { $env:HA_SSH_KEY_PATH } elseif (Test-Path -LiteralPath "C:\Users\randalab\.codex\memories\ha_keys\ha_ed25519.20260517_073034_121.temp") { "C:\Users\randalab\.codex\memories\ha_keys\ha_ed25519.20260517_073034_121.temp" } elseif (Test-Path -LiteralPath "C:\2_OPS\aeb\.tmp\ha_ed25519.safe") { "C:\2_OPS\aeb\.tmp\ha_ed25519.safe" } elseif (Test-Path -LiteralPath "C:\2_OPS\secrets\ha\ha_ed25519") { "C:\2_OPS\secrets\ha\ha_ed25519" } elseif (Test-Path -LiteralPath "C:\2_OPS\secrets\ha\ha_fallback_ed25519") { "C:\2_OPS\secrets\ha\ha_fallback_ed25519" } else { "C:\Users\randalab\.ssh\ha_ed25519" })
)

$ErrorActionPreference = "Stop"
. "$PSScriptRoot\ha_secure_key.ps1"
$KeyPath = Resolve-HaSecureKeyPath -Path $KeyPath

function Say([string]$msg) {
  Write-Host $msg
}

$repoRoot = Split-Path -Parent $PSScriptRoot
$date = Get-Date -Format "yyyy-MM-dd"
$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$dateDir = Join-Path $repoRoot ("docs\runtime_evidence\" + $date)
New-Item -ItemType Directory -Force -Path $dateDir | Out-Null

$pwshExe = "C:\Program Files\PowerShell\7\pwsh.exe"
$sshExe = "C:\Windows\System32\OpenSSH\ssh.exe"
$knownHosts = "C:\2_OPS\secrets\ha\known_hosts"

$coreCheckFile = Join-Path $dateDir ("phase4_ha_core_check_" + $stamp + ".txt")
$summaryFile = Join-Path $dateDir ("phase4_daily_summary_" + $stamp + ".md")

Say "==> HA config check"
$checkCmd = "& '$sshExe' -o UserKnownHostsFile=$knownHosts -o StrictHostKeyChecking=yes -p $Port -i '$KeyPath' $HaHost 'docker exec homeassistant python -m homeassistant --script check_config -c /config'"
& $pwshExe -Command $checkCmd | Tee-Object -FilePath $coreCheckFile
if ($LASTEXITCODE -ne 0) {
  throw "HA container check_config failed (RC=$LASTEXITCODE)"
}

if ($RunRestart) {
  Say "==> HA container restart + check"
  $restartCmd = "& '$sshExe' -o UserKnownHostsFile=$knownHosts -o StrictHostKeyChecking=yes -p $Port -i '$KeyPath' $HaHost 'docker restart homeassistant >/dev/null && sleep 30 && docker exec homeassistant python -m homeassistant --script check_config -c /config'"
  & $pwshExe -Command $restartCmd | Out-Null
  if ($LASTEXITCODE -ne 0) {
    throw "HA container restart/check failed (RC=$LASTEXITCODE)"
  }
}

Say "==> Runtime truth scan"
& powershell -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "phase1_runtime_truth_check.ps1") `
  -HaHost $HaHost -Port $Port -KeyPath $KeyPath
if ($LASTEXITCODE -ne 0) {
  throw "phase1_runtime_truth_check failed (RC=$LASTEXITCODE)"
}

$currentBootScan = Get-ChildItem $dateDir -Filter "phase1_runtime_truth_scan_current_boot_*.txt" |
  Sort-Object LastWriteTime -Descending | Select-Object -First 1
$writerScan = Get-ChildItem $dateDir -Filter "phase1_runtime_truth_writer_scan_*.txt" |
  Sort-Object LastWriteTime -Descending | Select-Object -First 1

if ($null -eq $currentBootScan -or $null -eq $writerScan) {
  throw "Missing runtime truth outputs in $dateDir"
}

$coreCheckOk = (Get-Content $coreCheckFile -Raw) -match "Testing configuration at /config"
$currentBootValue = (Get-Content $currentBootScan.FullName -Raw).Trim()
$writerValue = (Get-Content $writerScan.FullName -Raw).Trim()

$runtimeErrorsOk = ($currentBootValue -eq "NO_PHASE1_ERRORS_IN_CURRENT_BOOT_WINDOW")
$writerOk = ($writerValue -eq "NO_WRITER_SERVICES_IN_PHASE1_FILES")
$go = ($coreCheckOk -and $runtimeErrorsOk -and $writerOk)
$decision = if ($go) { "GO" } else { "NO-GO" }

$summary = @()
$summary += "# Phase4 Daily Runtime Report ($date)"
$summary += ""
$summary += "Timestamp: $stamp"
$summary += "Decision: **$decision**"
$summary += ""
$summary += "## Checks"
$summary += "- HA core check: " + ($(if ($coreCheckOk) { "PASS" } else { "FAIL" }))
$summary += "- Current boot Phase1 errors: " + ($(if ($runtimeErrorsOk) { "PASS" } else { "FAIL" }))
$summary += "- Phase1 writer service scan: " + ($(if ($writerOk) { "PASS" } else { "FAIL" }))
$summary += ""
$summary += "## Evidence files"
$summary += "- " + $coreCheckFile
$summary += "- " + $currentBootScan.FullName
$summary += "- " + $writerScan.FullName
$summary += ""
$summary += "## Raw values"
$summary += "- current_boot_scan: `"$currentBootValue`""
$summary += "- writer_scan: `"$writerValue`""

$summary -join "`r`n" | Set-Content -Path $summaryFile -Encoding utf8

Say "==> Daily summary"
Say $summaryFile
Say ("Decision: " + $decision)
