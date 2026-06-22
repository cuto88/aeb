[CmdletBinding(SupportsShouldProcess = $true)]
param(
  [ValidateSet("Preview", "Install", "Status", "RunNow", "Remove", "RunJob")]
  [string]$Action = "Preview",
  [string]$TaskName = "CasaMercurio-DR-PeriodicBackup",
  [string]$StartTime = "03:15",
  [string]$EnvPath = ".env",
  [string]$BackupRoot = "",
  [string]$Source = "__REMOTE_HOME_ASSISTANT_CONFIG__",
  [int]$MaxAgeHours = 24,
  [int]$RunNowTimeoutSeconds = 1800
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

function Read-DotEnv {
  param([string]$Path)

  if (-not (Test-Path -LiteralPath $Path)) {
    throw "Missing env file: $Path"
  }

  $map = @{}
  foreach ($line in Get-Content -LiteralPath $Path) {
    if ([string]::IsNullOrWhiteSpace($line)) {
      continue
    }
    $trimmed = $line.TrimStart()
    if ($trimmed.StartsWith("#")) {
      continue
    }
    $parts = $line -split "=", 2
    if ($parts.Count -eq 2) {
      $map[$parts[0].Trim()] = $parts[1].Trim()
    }
  }
  return $map
}

function Import-EnvMap {
  param([hashtable]$Map)

  foreach ($key in $Map.Keys) {
    $value = [string]$Map[$key]
    if (-not [string]::IsNullOrWhiteSpace($value)) {
      Set-Item -Path ("Env:" + $key) -Value $value
    }
  }
}

function Resolve-DefaultBackupRoot {
  $repoRoot = Split-Path -Parent $PSScriptRoot
  return (Join-Path ([System.IO.Path]::GetDirectoryName($repoRoot)) "_repo_archives\aeb\_dr_backups")
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

function Resolve-RemoteHost {
  $hostValue = $env:HA_SSH_HOST_TAILSCALE
  if ([string]::IsNullOrWhiteSpace($hostValue)) {
    $hostValue = $env:HA_SSH_HOST_LAN
  }
  if ([string]::IsNullOrWhiteSpace($hostValue)) {
    throw "HA_SSH_HOST_TAILSCALE or HA_SSH_HOST_LAN is required."
  }

  $env:HA_SSH_HOST_LAN = $hostValue

  return $hostValue
}

function Get-BackupJobCommand {
  param(
    [string]$RepoRoot,
    [string]$BackupRoot,
    [string]$EnvPath,
    [string]$Source,
    [int]$MaxAgeHours
  )

  $scriptPath = Join-Path $PSScriptRoot "dr_backup_task.ps1"
  return @(
    "-NoProfile"
    "-NonInteractive"
    "-ExecutionPolicy"
    "Bypass"
    "-File"
    $scriptPath
    "-Action"
    "RunJob"
    "-Source"
    $Source
    "-BackupRoot"
    $BackupRoot
    "-MaxAgeHours"
    $MaxAgeHours
  )
}

function Invoke-BackupJob {
  param(
    [string]$RepoRoot,
    [string]$BackupRoot,
    [string]$EnvPath,
    [string]$Source,
    [int]$MaxAgeHours
  )

  $shellExe = Get-PowerShellExe
  $backupScript = Join-Path $PSScriptRoot "dr_backup_task.ps1"
  $verifyScript = Join-Path $PSScriptRoot "verify_backup_freshness.ps1"
  if (-not (Test-Path -LiteralPath $backupScript)) {
    throw "Missing script: $backupScript"
  }
  if (-not (Test-Path -LiteralPath $verifyScript)) {
    throw "Missing script: $verifyScript"
  }

  $logRoot = Join-Path $BackupRoot "logs"
  New-Item -ItemType Directory -Force -Path $logRoot | Out-Null
  $stamp = Get-Date -Format "yyyyMMdd_HHmmss"
  $logFile = Join-Path $logRoot ("scheduled_dr_backup_" + $stamp + ".log")

  try {
    "Scheduled DR backup start: $(Get-Date -Format s)" | Tee-Object -FilePath $logFile -Append | Out-Null
    $backupArgs = Get-BackupJobCommand -RepoRoot $RepoRoot -BackupRoot $BackupRoot -EnvPath $EnvPath -Source $Source -MaxAgeHours $MaxAgeHours
    & $shellExe @backupArgs 2>&1 | Tee-Object -FilePath $logFile -Append | Out-Null
    if ($LASTEXITCODE -ne 0) {
      throw "dr_backup_task.ps1 failed (RC=$LASTEXITCODE)"
    }

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
    & $shellExe @verifyArgs 2>&1 | Tee-Object -FilePath $logFile -Append | Out-Null
    if ($LASTEXITCODE -ne 0) {
      throw "verify_backup_freshness.ps1 failed (RC=$LASTEXITCODE)"
    }

    "Scheduled DR backup end: OK $(Get-Date -Format s)" | Tee-Object -FilePath $logFile -Append | Out-Null
    Say "OK source=$Source backup_root=$BackupRoot log=$logFile"
    return 0
  } catch {
    "Scheduled DR backup end: FAIL $(Get-Date -Format s)" | Tee-Object -FilePath $logFile -Append | Out-Null
    $_.Exception.Message | Tee-Object -FilePath $logFile -Append | Out-Null
    Say "FAIL source=$Source backup_root=$BackupRoot log=$logFile"
    return 1
  }
}

$repoRoot = Split-Path -Parent $PSScriptRoot
$shellExe = Get-PowerShellExe
$resolvedEnvPath = if ([System.IO.Path]::IsPathRooted($EnvPath)) {
  $EnvPath
} else {
  Join-Path $repoRoot $EnvPath
}

$envMap = Read-DotEnv -Path $resolvedEnvPath
Import-EnvMap -Map $envMap

if ([string]::IsNullOrWhiteSpace($BackupRoot)) {
  $BackupRoot = Resolve-DefaultBackupRoot
}

$remoteHost = Resolve-RemoteHost

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
  "-EnvPath"
  $EnvPath
  "-BackupRoot"
  $BackupRoot
  "-Source"
  $Source
  "-MaxAgeHours"
  $MaxAgeHours
)

switch ($Action) {
  "Preview" {
    Say "Preview only: no task registration and no backup run."
    Say "Repo root: $repoRoot"
    Say "Env path: $resolvedEnvPath"
    Say "Remote host (preferred): $remoteHost"
    Say "Backup root: $BackupRoot"
    Say "Task name: $TaskName"
    Say "Scheduled action: $shellExe $($taskActionArgs -join ' ')"
    Say "Manual one-shot backup command: $shellExe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File `"$PSCommandPath`" -Action RunJob -EnvPath `"$EnvPath`" -BackupRoot `"$BackupRoot`" -Source `"$Source`" -MaxAgeHours $MaxAgeHours"
  }
  "Install" {
    try {
      if (-not $PSCmdlet.ShouldProcess($TaskName, "Register scheduled DR backup task")) {
        break
      }

      $at = [datetime]::ParseExact($StartTime, "HH:mm", $null)
      $trigger = New-ScheduledTaskTrigger -Daily -At $at
      $taskAction = New-ScheduledTaskAction -Execute $shellExe -Argument ($taskActionArgs -join ' ') -WorkingDirectory $repoRoot
      $settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -MultipleInstances IgnoreNew -ExecutionTimeLimit (New-TimeSpan -Hours 4)
      $principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive -RunLevel Limited

      Register-ScheduledTask `
        -TaskName $TaskName `
        -Action $taskAction `
        -Trigger $trigger `
        -Settings $settings `
        -Principal $principal `
        -Description "Casa Mercurio: scheduled DR runtime snapshot + freshness verification." `
        -Force | Out-Null

      Say "Task installed/updated: $TaskName at $StartTime"
      Say "Action: $shellExe $($taskActionArgs -join ' ')"
    } catch {
      $message = $_.Exception.Message
      Say "Task install failed: $message"
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
    if (-not $PSCmdlet.ShouldProcess($TaskName, "Unregister scheduled DR backup task")) {
      break
    }
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    Say "Task removed: $TaskName"
  }
  "RunJob" {
    if ($WhatIfPreference) {
      Say "WhatIf: no backup run executed."
      exit 0
    }
    $rc = Invoke-BackupJob -RepoRoot $repoRoot -BackupRoot $BackupRoot -EnvPath $resolvedEnvPath -Source $Source -MaxAgeHours $MaxAgeHours
    exit $rc
  }
}
