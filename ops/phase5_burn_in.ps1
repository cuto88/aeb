param(
  [ValidateSet("Start", "Status", "Stop", "RunNow", "Loop")]
  [string]$Action = "Status",
  [string]$StartTime = "07:30",
  [int]$RunNowTimeoutSeconds = 900,
  [string]$StateFile = ""
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($StateFile)) {
  $StateFile = Join-Path $repoRoot ".ops_state\phase5_burn_in.json"
}

$runnerExe = if (Get-Command pwsh -ErrorAction SilentlyContinue) { "pwsh" } else { "powershell" }
$launcherExe = if (Get-Command powershell -ErrorAction SilentlyContinue) { "powershell" } else { $runnerExe }

function Say([string]$msg) {
  Write-Host $msg
}

function Ensure-StateDir {
  $stateDir = Split-Path -Parent $StateFile
  New-Item -ItemType Directory -Force -Path $stateDir | Out-Null
}

function Get-NextRun([string]$Clock) {
  $at = [datetime]::ParseExact($Clock, "HH:mm", $null)
  $now = Get-Date
  $next = Get-Date -Hour $at.Hour -Minute $at.Minute -Second 0
  if ($next -le $now) {
    $next = $next.AddDays(1)
  }
  return $next
}

function Read-State {
  if (!(Test-Path -LiteralPath $StateFile)) {
    return $null
  }
  try {
    return Get-Content -LiteralPath $StateFile -Raw | ConvertFrom-Json
  } catch {
    return $null
  }
}

function Write-State {
  param([hashtable]$State)
  Ensure-StateDir
  $State | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $StateFile -Encoding utf8
}

function Get-ProcessState {
  param([object]$State)
  if ($null -eq $State -or $null -eq $State.pid) {
    return $null
  }
  try {
    return Get-Process -Id ([int]$State.pid) -ErrorAction Stop
  } catch {
    return $null
  }
}

function Get-LoopLogFile {
  $dateDir = Join-Path $repoRoot ("docs\runtime_evidence\" + (Get-Date -Format "yyyy-MM-dd"))
  New-Item -ItemType Directory -Force -Path $dateDir | Out-Null
  return Join-Path $dateDir ("phase5_burn_in_loop_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".log")
}

function Invoke-DailyRunner {
  param(
    [string]$LogFile,
    [switch]$WhatIfRetention
  )

  $runnerArgs = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", (Join-Path $PSScriptRoot "phase5_task_runner.ps1"))
  if ($WhatIfRetention) {
    $runnerArgs += @("-RetentionWhatIf")
  }
  & $runnerExe @runnerArgs 2>&1 | Tee-Object -FilePath $LogFile -Append | Out-Null
  return $LASTEXITCODE
}

switch ($Action) {
  "Start" {
    $state = Read-State
    $proc = Get-ProcessState -State $state
    if ($null -ne $proc) {
      Say "Burn-in loop already running: pid=$($proc.Id)"
      exit 0
    }

    $logFile = Get-LoopLogFile
    $targetArgs = @(
      "-NoProfile"
      "-ExecutionPolicy"
      "Bypass"
      "-File"
      $PSCommandPath
      "-Action"
      "Loop"
      "-StartTime"
      $StartTime
      "-StateFile"
      $StateFile
    )
    $proc = Start-Process -FilePath $launcherExe -ArgumentList $targetArgs -WindowStyle Hidden -PassThru -WorkingDirectory $repoRoot
    Write-State @{
      action = "Loop"
      pid = $proc.Id
      start_time = (Get-Date -Format s)
      start_clock = $StartTime
      next_run = (Get-NextRun -Clock $StartTime).ToString("s")
      log_file = $logFile
      last_run = ""
      last_exit = ""
    }
    Say "Burn-in loop started: pid=$($proc.Id)"
    Say "State file: $StateFile"
  }
  "Status" {
    $state = Read-State
    if ($null -eq $state) {
      Say "Burn-in loop not initialized."
      exit 1
    }
    $proc = Get-ProcessState -State $state
    Say ("Mode: " + ($state.action))
    Say ("PID: " + ($state.pid))
    Say ("Running: " + ($(if ($null -ne $proc) { "yes" } else { "no" })))
    Say ("StartTime: " + ($state.start_clock))
    Say ("NextRun: " + ($state.next_run))
    Say ("LastRun: " + ($state.last_run))
    Say ("LastExit: " + ($state.last_exit))
    Say ("LogFile: " + ($state.log_file))
    if ($null -eq $proc) {
      exit 1
    }
  }
  "Stop" {
    $state = Read-State
    $proc = Get-ProcessState -State $state
    if ($null -ne $proc) {
      Stop-Process -Id $proc.Id -Force
    }
    if (Test-Path -LiteralPath $StateFile) {
      Remove-Item -LiteralPath $StateFile -Force
    }
    Say "Burn-in loop stopped."
  }
  "RunNow" {
    $logFile = Get-LoopLogFile
    $exitCode = Invoke-DailyRunner -LogFile $logFile
    Say "Burn-in run completed."
    Say ("ExitCode: " + $exitCode)
    exit $exitCode
  }
  "Loop" {
    $logFile = Get-LoopLogFile
    Write-State @{
      action = "Loop"
      pid = $PID
      start_time = (Get-Date -Format s)
      start_clock = $StartTime
      next_run = (Get-NextRun -Clock $StartTime).ToString("s")
      log_file = $logFile
      last_run = ""
      last_exit = ""
    }
    Say "Burn-in loop active. Log: $logFile"
    while ($true) {
      $nextRun = Get-NextRun -Clock $StartTime
      $now = Get-Date
      $sleepSeconds = [math]::Ceiling(($nextRun - $now).TotalSeconds)
      if ($sleepSeconds -gt 0) {
        $hours = [math]::Floor($sleepSeconds / 3600)
        $minutes = [math]::Floor(($sleepSeconds % 3600) / 60)
        $state = Read-State
        if ($null -ne $state) {
          $state.next_run = $nextRun.ToString("s")
          $state.log_file = $logFile
          Write-State @{
            action = "Loop"
            pid = $PID
            start_time = $state.start_time
            start_clock = $StartTime
            next_run = $nextRun.ToString("s")
            log_file = $logFile
            last_run = $state.last_run
            last_exit = $state.last_exit
          }
        }
        Say ("Next run at " + $nextRun.ToString("s") + " (sleep " + $hours + "h " + $minutes + "m)")
        Start-Sleep -Seconds $sleepSeconds
      }

      $runStamp = Get-Date -Format "yyyyMMdd_HHmmss"
      $runCode = Invoke-DailyRunner -LogFile $logFile
      $state = Read-State
      if ($null -ne $state) {
        Write-State @{
          action = "Loop"
          pid = $PID
          start_time = $state.start_time
          start_clock = $StartTime
          next_run = (Get-NextRun -Clock $StartTime).ToString("s")
          log_file = $logFile
          last_run = (Get-Date -Format s)
          last_exit = $runCode
        }
      }
      Say ("Burn-in run " + $runStamp + " exit=" + $runCode)
    }
  }
}
