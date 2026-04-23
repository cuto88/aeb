param(
  [ValidateSet("Install", "Status", "RunNow", "Remove")]
  [string]$Action = "Status",
  [string]$TaskName = "CasaMercurio-Phase4-DailyRuntimeReport",
  [string]$StartTime = "07:30",
  [int]$RunNowTimeoutSeconds = 900
)

$ErrorActionPreference = "Stop"

function Say([string]$msg) {
  Write-Host $msg
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

$repoRoot = Split-Path -Parent $PSScriptRoot
$runnerScript = Join-Path $PSScriptRoot "phase5_task_runner.ps1"
if (!(Test-Path $runnerScript)) {
  throw "Missing runner script: $runnerScript"
}
$pwshExe = "C:\Program Files\PowerShell\7\pwsh.exe"
$shellExe = if (Test-Path $pwshExe) { $pwshExe } else { "powershell.exe" }

switch ($Action) {
  "Install" {
    $at = [datetime]::ParseExact($StartTime, "HH:mm", $null)
    $trigger = New-ScheduledTaskTrigger -Daily -At $at
    $taskAction = New-ScheduledTaskAction `
      -Execute $shellExe `
      -Argument "-NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File `"$runnerScript`"" `
      -WorkingDirectory $repoRoot
    $settings = New-ScheduledTaskSettingsSet `
      -StartWhenAvailable `
      -MultipleInstances IgnoreNew `
      -ExecutionTimeLimit (New-TimeSpan -Hours 2)
    $principal = New-ScheduledTaskPrincipal `
      -UserId "$env:USERDOMAIN\$env:USERNAME" `
      -LogonType Interactive `
      -RunLevel Limited

    Register-ScheduledTask `
      -TaskName $TaskName `
      -Action $taskAction `
      -Trigger $trigger `
      -Settings $settings `
      -Principal $principal `
      -Description "Casa Mercurio: daily runtime GO/NO-GO report and recorder-safe AEB snapshot." `
      -Force | Out-Null

    Say "Task installed/updated: $TaskName at $StartTime"
    Say "Action: $shellExe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File `"$runnerScript`""
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
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    Say "Task removed: $TaskName"
  }
}
