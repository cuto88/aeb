[CmdletBinding()]
param(
  [ValidateSet("Install", "Status", "RunNow", "Remove", "RunJob")]
  [string]$Action = "Status",
  [string]$TaskName = "CasaMercurio-DR-DailyBackup",
  [string]$StartTime = "03:15",
  [string]$Source = "Z:\",
  [string]$BackupRoot = "",
  [switch]$IncludeStorage,
  [switch]$IncludeSecrets,
  [int]$MaxAgeHours = 24,
  [int]$RunNowTimeoutSeconds = 1800
)

$ErrorActionPreference = "Stop"

. $PSScriptRoot\ha_secure_key.ps1

function Say([string]$msg) {
  Write-Host $msg
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

function Resolve-DefaultBackupRoot {
  $repoRoot = Split-Path -Parent $PSScriptRoot
  return (Join-Path ([System.IO.Path]::GetDirectoryName($repoRoot)) "_repo_archives\aeb\_dr_backups")
}

function New-DrSafeKeyCopy {
  param(
    [Parameter(Mandatory = $true)]
    [string]$SourcePath
  )

  if (-not (Test-Path -LiteralPath $SourcePath)) {
    throw "SSH key source not found: $SourcePath"
  }

  $tmpRoot = Join-Path $PSScriptRoot ".tmp"
  New-Item -ItemType Directory -Force -Path $tmpRoot | Out-Null
  $safePath = Join-Path $tmpRoot ("dr_ssh_key_" + ([guid]::NewGuid().ToString("N")) + ".temp")
  Copy-Item -LiteralPath $SourcePath -Destination $safePath -Force

  $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
  $acl = New-Object System.Security.AccessControl.FileSecurity
  $acl.SetAccessRuleProtection($true, $false)
  $ruleUser = [System.Security.AccessControl.FileSystemAccessRule]::new($currentUser, [System.Security.AccessControl.FileSystemRights]::Modify, [System.Security.AccessControl.AccessControlType]::Allow)
  $ruleSystem = [System.Security.AccessControl.FileSystemAccessRule]::new('NT AUTHORITY\SYSTEM', [System.Security.AccessControl.FileSystemRights]::FullControl, [System.Security.AccessControl.AccessControlType]::Allow)
  $ruleAdmins = [System.Security.AccessControl.FileSystemAccessRule]::new('BUILTIN\Administrators', [System.Security.AccessControl.FileSystemRights]::FullControl, [System.Security.AccessControl.AccessControlType]::Allow)
  foreach ($rule in @($ruleUser, $ruleSystem, $ruleAdmins)) {
    [void]$acl.AddAccessRule($rule)
  }
  Set-Acl -LiteralPath $safePath -AclObject $acl

  return $safePath
}

function Get-DrSshKeyPath {
  $candidates = @(
    $env:HA_SSH_KEY_PATH
    "C:\2_OPS\aeb\.tmp\ha_ed25519.safe"
    "C:\Users\randalab\.codex\memories\ha_keys\ha_ed25519.20260517_073034_121.temp"
    "C:\2_OPS\secrets\ha\ha_ed25519"
    "C:\2_OPS\secrets\ha\ha_fallback_ed25519"
  ) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

  $lastError = $null
  foreach ($candidate in $candidates) {
    if (-not (Test-Path -LiteralPath $candidate)) {
      continue
    }
    try {
      return New-DrSafeKeyCopy -SourcePath $candidate
    } catch {
      $lastError = $_.Exception.Message
    }
  }

  if ($lastError) {
    throw "No usable SSH key source found. Last error: $lastError"
  }
  throw "No usable SSH key source found."
}

function Get-DrKnownHostsPath {
  if ($env:HA_SSH_KNOWN_HOSTS -and (Test-Path -LiteralPath $env:HA_SSH_KNOWN_HOSTS)) {
    return $env:HA_SSH_KNOWN_HOSTS
  }
  if (Test-Path -LiteralPath "C:\2_OPS\aeb\.tmp\known_hosts_ha_110") {
    return "C:\2_OPS\aeb\.tmp\known_hosts_ha_110"
  }
  return "C:\2_OPS\secrets\ha\known_hosts"
}

function Write-SnapshotMetadata {
  param(
    [string]$SnapshotRoot,
    [string]$SourceLabel,
    [switch]$CopiedStorage,
    [switch]$CopiedSecrets
  )

  $items = New-Object System.Collections.Generic.List[object]
  foreach ($file in Get-ChildItem -LiteralPath $SnapshotRoot -File -Recurse | Where-Object { $_.Name -notin @('manifest.json', 'README_RESTORE.txt') }) {
    $relative = $file.FullName.Substring((Resolve-Path -LiteralPath $SnapshotRoot).Path.Length).TrimStart('\','/')
    $items.Add([pscustomobject]@{
      relative_path   = $relative
      backup_path     = $file.FullName
      kind            = 'file'
      bytes           = [int64]$file.Length
      last_write_time = $file.LastWriteTimeUtc.ToString('o')
      sha256          = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
    })
  }

  $manifest = [ordered]@{
    schema            = 'aeb.dr.backup.v1'
    created_at        = (Get-Date).ToString('o')
    source           = $SourceLabel
    destination_root = (Split-Path -Parent $SnapshotRoot)
    snapshot_root    = $SnapshotRoot
    include_storage  = [bool]$CopiedStorage
    include_secrets  = [bool]$CopiedSecrets
    dry_run          = $false
    items            = $items
  }
  $manifestPath = Join-Path $SnapshotRoot 'manifest.json'
  $manifest | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $manifestPath -Encoding utf8

  $restoreText = @"
AEB Disaster Recovery snapshot
Created at: $((Get-Date).ToString('o'))
Source: $SourceLabel
Snapshot: $SnapshotRoot

Restore order:
1. Stop Home Assistant.
2. Restore configuration and runtime folders.
3. Restore .storage if included.
4. Restore secrets only if included and required.
5. Start Home Assistant and run validation.

Do not treat this snapshot as a Git substitute.
"@
  Set-Content -LiteralPath (Join-Path $SnapshotRoot 'README_RESTORE.txt') -Value $restoreText -Encoding utf8
}

function Invoke-RemoteSnapshot {
  param(
    [string]$RemoteHost,
    [string]$RemotePath,
    [string]$SnapshotRoot,
    [string]$LogFile,
    [switch]$CopiedStorage,
    [switch]$CopiedSecrets
  )

  $sshExe = (Get-Command ssh.exe -ErrorAction SilentlyContinue).Source
  $tarExe = (Get-Command tar.exe -ErrorAction SilentlyContinue)
  if (-not $sshExe -or $null -eq $tarExe) {
    throw "Missing ssh/tar tooling for remote DR snapshot."
  }

  $sshKey = Get-DrSshKeyPath
  $knownHosts = Get-DrKnownHostsPath
  $logRoot = Split-Path -Parent $LogFile
  $sshErrFile = Join-Path $logRoot ("remote_ssh_" + (Get-Date -Format 'yyyyMMdd_HHmmss') + ".err")
  $tarErrFile = Join-Path $logRoot ("local_tar_" + (Get-Date -Format 'yyyyMMdd_HHmmss') + ".err")
  $remoteCmd = @'
docker exec homeassistant sh -lc "tar -czf - -C /config --exclude='backup' --exclude='_ha_runtime_backups' --exclude='_dr_backups' --exclude='home-assistant_v2.db' --exclude='home-assistant_v2.db-*' --exclude='home-assistant_v2.db.corrupt.*' --exclude='.git' --exclude='.git-local' --exclude='.tmp' --exclude='media' --exclude='tts' --exclude='www' ."
'@

  try {
    "Remote snapshot start: $(Get-Date -Format s) host=$RemoteHost path=$RemotePath" | Tee-Object -FilePath $LogFile -Append | Out-Null
    New-Item -ItemType Directory -Force -Path $SnapshotRoot | Out-Null
    & $sshExe -T -o "UserKnownHostsFile=$knownHosts" -o StrictHostKeyChecking=yes -i $sshKey $RemoteHost $remoteCmd 2> $sshErrFile |
      & $tarExe.Source -xzf - -C $SnapshotRoot 2> $tarErrFile
    if ($LASTEXITCODE -ne 0) {
      throw "Remote stream snapshot failed (RC=$LASTEXITCODE)"
    }

    foreach ($errFile in @($sshErrFile, $tarErrFile)) {
      if (Test-Path -LiteralPath $errFile) {
        $errText = Get-Content -LiteralPath $errFile -Raw
        if (-not [string]::IsNullOrWhiteSpace($errText)) {
          Add-Content -LiteralPath $LogFile -Value $errText
        }
        Remove-Item -LiteralPath $errFile -Force -ErrorAction SilentlyContinue
      }
    }

    Write-SnapshotMetadata -SnapshotRoot $SnapshotRoot -SourceLabel ("ssh://" + $RemoteHost + "/docker/homeassistant:/config") -CopiedStorage:$CopiedStorage -CopiedSecrets:$CopiedSecrets
    "Remote snapshot end: OK $(Get-Date -Format s)" | Tee-Object -FilePath $LogFile -Append | Out-Null
  } catch {
    foreach ($errFile in @($sshErrFile, $tarErrFile)) {
      if (Test-Path -LiteralPath $errFile) {
        $errText = Get-Content -LiteralPath $errFile -Raw
        if (-not [string]::IsNullOrWhiteSpace($errText)) {
          Add-Content -LiteralPath $LogFile -Value $errText
        }
        Remove-Item -LiteralPath $errFile -Force -ErrorAction SilentlyContinue
      }
    }
    throw
  }
}

function Invoke-DrBackupJob {
  param(
    [string]$RepoRoot,
    [string]$SourcePath,
    [string]$BackupPath,
    [switch]$CopyStorage,
    [switch]$CopySecrets,
    [int]$FreshnessHours
  )

  $shellExe = Get-PowerShellExe
  $backupScript = Join-Path $PSScriptRoot "backup_runtime_snapshot.ps1"
  $verifyScript = Join-Path $PSScriptRoot "verify_backup_freshness.ps1"
  if (-not (Test-Path -LiteralPath $backupScript)) {
    throw "Missing script: $backupScript"
  }
  if (-not (Test-Path -LiteralPath $verifyScript)) {
    throw "Missing script: $verifyScript"
  }

  $logRoot = Join-Path $BackupPath "logs"
  New-Item -ItemType Directory -Force -Path $logRoot | Out-Null
  $stamp = Get-Date -Format "yyyyMMdd_HHmmss"
  $logFile = Join-Path $logRoot ("dr_backup_" + $stamp + ".log")

  try {
    "DR backup job start: $(Get-Date -Format s)" | Tee-Object -FilePath $logFile -Append | Out-Null
    $snapshotName = "ha_runtime_snapshot_" + (Get-Date -Format "yyyyMMdd_HHmmss")
    if (Test-Path -LiteralPath $SourcePath) {
      $backupArgs = @(
        "-NoProfile"
        "-ExecutionPolicy"
        "Bypass"
        "-File"
        $backupScript
        "-Source"
        $SourcePath
        "-DestinationRoot"
        $BackupPath
      )
      if ($CopyStorage) {
        $backupArgs += "-IncludeStorage"
      }
      if ($CopySecrets) {
        $backupArgs += "-IncludeSecrets"
      }
      & $shellExe @backupArgs 2>&1 | Tee-Object -FilePath $logFile -Append | Out-Null
      if ($LASTEXITCODE -ne 0) {
        throw "backup_runtime_snapshot.ps1 failed (RC=$LASTEXITCODE)"
      }
    } else {
      Invoke-RemoteSnapshot -RemoteHost "dscomparin@192.168.178.110" -RemotePath "/opt/data/homeassistant" -SnapshotRoot (Join-Path $BackupPath $snapshotName) -LogFile $logFile -CopiedStorage:$CopyStorage -CopiedSecrets:$CopySecrets
    }

    $verifyArgs = @(
      "-NoProfile"
      "-ExecutionPolicy"
      "Bypass"
      "-File"
      $verifyScript
      "-BackupRoot"
      $BackupPath
      "-MaxAgeHours"
      $FreshnessHours
    )
    & $shellExe @verifyArgs 2>&1 | Tee-Object -FilePath $logFile -Append | Out-Null
    if ($LASTEXITCODE -ne 0) {
      throw "verify_backup_freshness.ps1 failed (RC=$LASTEXITCODE)"
    }

    "DR backup job end: OK $(Get-Date -Format s)" | Tee-Object -FilePath $logFile -Append | Out-Null
    Say "OK source=$SourcePath backup_root=$BackupPath log=$logFile"
    return 0
  } catch {
    "DR backup job end: FAIL $(Get-Date -Format s)" | Tee-Object -FilePath $logFile -Append | Out-Null
    $_.Exception.Message | Tee-Object -FilePath $logFile -Append | Out-Null
    Say "FAIL source=$SourcePath backup_root=$BackupPath log=$logFile"
    return 1
  }
}

if ([string]::IsNullOrWhiteSpace($BackupRoot)) {
  $BackupRoot = Resolve-DefaultBackupRoot
}

$repoRoot = Split-Path -Parent $PSScriptRoot
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
  "-Source"
  $Source
  "-BackupRoot"
  $BackupRoot
  "-MaxAgeHours"
  $MaxAgeHours
)
if ($IncludeStorage) {
  $taskActionArgs += "-IncludeStorage"
}
if ($IncludeSecrets) {
  $taskActionArgs += "-IncludeSecrets"
}

switch ($Action) {
  "Install" {
    try {
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
        -Description "Casa Mercurio: daily DR runtime snapshot + freshness check." `
        -Force | Out-Null

      Say "Task installed/updated: $TaskName at $StartTime"
      Say "Action: $shellExe $($taskActionArgs -join ' ')"
    } catch {
      $message = $_.Exception.Message
      Say "Task install failed: $message"
      Say 'Manual fallback: run pwsh -NoProfile -ExecutionPolicy Bypass -File ops\dr_backup_task.ps1 -Action RunJob -IncludeStorage -IncludeSecrets'
      if ($message -match 'Accesso negato|Access is denied') {
        Say "Install requires an elevated PowerShell session on this machine."
      }
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
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    Say "Task removed: $TaskName"
  }
  "RunJob" {
    $rc = Invoke-DrBackupJob -RepoRoot $repoRoot -SourcePath $Source -BackupPath $BackupRoot -CopyStorage:$IncludeStorage -CopySecrets:$IncludeSecrets -FreshnessHours $MaxAgeHours
    exit $rc
  }
}
