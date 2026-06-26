[CmdletBinding(SupportsShouldProcess = $true)]
param(
  [ValidateSet("Preview", "Install", "Status", "RunNow", "Remove", "RunJob")]
  [string]$Action = "Preview",
  [string]$TaskName = "CasaMercurio-DR-BackupFreshnessAlert",
  [string]$StartTime = "14:00",
  [string]$BackupRoot = "",
  [int]$MaxAgeHours = 30,
  [int]$RunNowTimeoutSeconds = 300
)

$ErrorActionPreference = "Stop"

function Say([string]$Message) {
  Write-Host $Message
}

function Get-PowerShellExe {
  if (Get-Command pwsh -ErrorAction SilentlyContinue) {
    return "pwsh"
  }
  return "powershell"
}

function Get-TaskInfoSafe([string]$Name) {
  try {
    $task = Get-ScheduledTask -TaskName $Name -ErrorAction Stop
    $info = Get-ScheduledTaskInfo -TaskName $Name -ErrorAction Stop
    return @{ Task = $task; Info = $info }
  } catch {
    return $null
  }
}

function Get-LogRoot {
  param([string]$Root)

  return (Join-Path $Root "logs")
}

function Resolve-AlertLogRoot {
  param(
    [string]$PreferredRoot,
    [string]$FallbackRoot
  )

  foreach ($candidate in @($PreferredRoot, $FallbackRoot)) {
    if ([string]::IsNullOrWhiteSpace($candidate)) {
      continue
    }
    try {
      New-Item -ItemType Directory -Force -Path $candidate | Out-Null
      $probe = Join-Path $candidate ("write_probe_" + ([guid]::NewGuid().ToString("N")) + ".tmp")
      Set-Content -LiteralPath $probe -Value "probe" -Encoding utf8
      Remove-Item -LiteralPath $probe -Force -ErrorAction SilentlyContinue
      return $candidate
    } catch {
      continue
    }
  }

  throw "Unable to initialize alert log root."
}

function New-AlertLogContext {
  param(
    [string]$BackupRoot,
    [string]$RepoRoot
  )

  $preferred = Get-LogRoot -Root $BackupRoot
  $fallback = Join-Path $RepoRoot ".tmp\dr_backup_alert_logs"
  $logRoot = Resolve-AlertLogRoot -PreferredRoot $preferred -FallbackRoot $fallback
  $stamp = Get-Date -Format "yyyyMMdd_HHmmss"
  $logFile = Join-Path $logRoot ("dr_backup_alert_" + $stamp + ".log")
  return [pscustomobject]@{
    LogRoot = $logRoot
    LogFile = $logFile
  }
}

function Invoke-BackupAlertCheck {
  param(
    [string]$BackupRoot,
    [int]$MaxAgeHours
  )

  $shellExe = Get-PowerShellExe
  $verifyScript = Join-Path $PSScriptRoot "verify_backup_freshness.ps1"
  if (-not (Test-Path -LiteralPath $verifyScript)) {
    throw "Missing script: $verifyScript"
  }

  if (-not (Test-Path -LiteralPath $BackupRoot)) {
    $logContext = New-AlertLogContext -BackupRoot $BackupRoot -RepoRoot $repoRoot
    $logFile = $logContext.LogFile
    "DR_BACKUP_ALERT_FAIL reason=backup_root_missing root=$BackupRoot max_age_hours=$MaxAgeHours log=$logFile" | Tee-Object -FilePath $logFile -Append | Out-Null
    Write-Host "DR_BACKUP_ALERT_FAIL reason=backup_root_missing root=$BackupRoot max_age_hours=$MaxAgeHours log=$logFile"
    return 1
  }

  $logContext = New-AlertLogContext -BackupRoot $BackupRoot -RepoRoot $repoRoot
  $logRoot = $logContext.LogRoot
  $logFile = $logContext.LogFile

  try {
    "DR backup alert check start: $(Get-Date -Format s)" | Tee-Object -FilePath $logFile -Append | Out-Null
    $verifyArgs = @(
      "-NoProfile"
      "-ExecutionPolicy"
      "Bypass"
      "-File"
      $verifyScript
      "-BackupRoot"
      $BackupRoot
      "-MaxAgeHours"
      $MaxAgeHours
    )
    $verifyOutput = & $shellExe @verifyArgs 2>&1
    $verifyText = (($verifyOutput | Out-String).Trim())
    if (-not [string]::IsNullOrWhiteSpace($verifyText)) {
      Add-Content -LiteralPath $logFile -Value $verifyText
    }

    if ($LASTEXITCODE -ne 0) {
      $reason = if ([string]::IsNullOrWhiteSpace($verifyText)) { "freshness_check_failed" } else { $verifyText }
      Write-Host "DR_BACKUP_ALERT_FAIL reason=$reason root=$BackupRoot max_age_hours=$MaxAgeHours log=$logFile"
      "DR backup alert check end: FAIL $(Get-Date -Format s)" | Tee-Object -FilePath $logFile -Append | Out-Null
      return 1
    }

    $latest = "unknown"
    $ageHours = "unknown"
    $items = "unknown"
    if ($verifyText -match 'BACKUP_VERIFY_OK latest=(\S+) age_hours=([0-9.]+) items=([0-9]+) root=') {
      $latest = $Matches[1]
      $ageHours = $Matches[2]
      $items = $Matches[3]
    }

    Write-Host "DR_BACKUP_ALERT_OK latest=$latest age_hours=$ageHours items=$items max_age_hours=$MaxAgeHours root=$BackupRoot log=$logFile"
    "DR backup alert check end: OK $(Get-Date -Format s)" | Tee-Object -FilePath $logFile -Append | Out-Null
    return 0
  } catch {
    $message = $_.Exception.Message
    Add-Content -LiteralPath $logFile -Value $message
    Write-Host "DR_BACKUP_ALERT_FAIL reason=$message root=$BackupRoot max_age_hours=$MaxAgeHours log=$logFile"
    "DR backup alert check end: FAIL $(Get-Date -Format s)" | Tee-Object -FilePath $logFile -Append | Out-Null
    return 1
  }
}

$repoRoot = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($BackupRoot)) {
  $BackupRoot = Join-Path $repoRoot "_dr_backups"
}
$shellExe = Get-PowerShellExe
$taskActionArgs = @(
  "-NoProfile"
  "-NonInteractive"
  "-ExecutionPolicy"
  "Bypass"
  "-File"
  $PSCommandPath
  "-Action"
  "RunJob"
  "-TaskName"
  $TaskName
  "-StartTime"
  $StartTime
  "-BackupRoot"
  $BackupRoot
  "-MaxAgeHours"
  $MaxAgeHours
)

switch ($Action) {
  "Preview" {
    Say "Preview only: no task registration and no backup alert run."
    Say "Repo root: $repoRoot"
    Say "Backup root: $BackupRoot"
    Say "Max age hours: $MaxAgeHours"
    Say "Task name: $TaskName"
    Say "Scheduled action: $shellExe $($taskActionArgs -join ' ')"
    Say "Manual alert command: $shellExe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File `"$PSCommandPath`" -Action RunJob -BackupRoot `"$BackupRoot`" -MaxAgeHours $MaxAgeHours"
  }
  "Install" {
    try {
      if (-not $PSCmdlet.ShouldProcess($TaskName, "Register backup freshness alert task")) {
        break
      }

      $at = [datetime]::ParseExact($StartTime, "HH:mm", $null)
      $trigger = New-ScheduledTaskTrigger -Daily -At $at
      $taskAction = New-ScheduledTaskAction -Execute $shellExe -Argument ($taskActionArgs -join ' ') -WorkingDirectory $repoRoot
      $settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -MultipleInstances IgnoreNew -ExecutionTimeLimit (New-TimeSpan -Hours 1)
      $principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive -RunLevel Limited

      Register-ScheduledTask `
        -TaskName $TaskName `
        -Action $taskAction `
        -Trigger $trigger `
        -Settings $settings `
        -Principal $principal `
        -Description "Casa Mercurio: scheduled DR backup freshness alert." `
        -Force | Out-Null

      Say "Task installed/updated: $TaskName at $StartTime"
      Say "Action: $shellExe $($taskActionArgs -join ' ')"
    } catch {
      Say "Task install failed: $($_.Exception.Message)"
      exit 1
    }
  }
  "Status" {
    $data = Get-TaskInfoSafe -Name $TaskName
    if ($null -eq $data) {
      Say "Task not found: $TaskName"
      exit 1
    }
    Say "Task: $TaskName"
    Say ("State: " + $data.Task.State)
    Say ("LastRunTime: " + $data.Info.LastRunTime)
    Say ("NextRunTime: " + $data.Info.NextRunTime)
    Say ("LastTaskResult: " + $data.Info.LastTaskResult)
  }
  "RunNow" {
    Start-ScheduledTask -TaskName $TaskName
    $deadline = (Get-Date).AddSeconds($RunNowTimeoutSeconds)
    do {
      Start-Sleep -Seconds 5
      $data = Get-TaskInfoSafe -Name $TaskName
      if ($null -eq $data) {
        throw "Task missing after Start-ScheduledTask: $TaskName"
      }
    } while ($data.Task.State -eq "Running" -and (Get-Date) -lt $deadline)

    if ($data.Task.State -eq "Running") {
      throw "Task still running after $RunNowTimeoutSeconds seconds: $TaskName"
    }
    Say "Task started: $TaskName"
    Say ("State: " + $data.Task.State)
    Say ("LastRunTime: " + $data.Info.LastRunTime)
    Say ("LastTaskResult: " + $data.Info.LastTaskResult)
  }
  "Remove" {
    if (-not $PSCmdlet.ShouldProcess($TaskName, "Unregister backup freshness alert task")) {
      break
    }
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    Say "Task removed: $TaskName"
  }
  "RunJob" {
    $rc = Invoke-BackupAlertCheck -BackupRoot $BackupRoot -MaxAgeHours $MaxAgeHours
    exit $rc
  }
}
