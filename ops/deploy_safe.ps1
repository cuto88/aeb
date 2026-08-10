param(
  [string]$Branch = "main",
  [string]$Target = "",
  [string]$BackupRoot = ".\_ha_runtime_backups",
  [string]$RemoteHost = $(if ($env:HA_SSH_HOST_LAN) { $env:HA_SSH_HOST_LAN } else { "dscomparin@192.168.178.110" }),
  [int]$RemotePort = 22,
  [string]$RemoteContainer = "homeassistant",
  [string]$RemotePath = "/config",
  [switch]$IncludeTts,
  [switch]$IncludeWww,
  [switch]$IncludeBlueprints,
  [switch]$AllowDirty,
  [switch]$RunConfigCheck,
  [switch]$Restart,
  [switch]$DryRun,
  [switch]$RunGates,
  [int]$TransferTimeoutSeconds = 300,
  [int]$HeartbeatSeconds = 15
)

$ErrorActionPreference = "Stop"

. $PSScriptRoot\ha_secure_key.ps1
. $PSScriptRoot\deploy_transport.ps1

function Say($m){ Write-Host $m }
function Fail($m){ throw $m }

function Resolve-StaleGitIndexLocks {
  param([string]$RepoPath)

  $resolverPath = Join-Path $RepoPath "..\00_shared\scripts\Resolve-StaleGitLocks.ps1"
  if (-not (Test-Path $resolverPath)) {
    return
  }

  $repoFullPath = (Resolve-Path $RepoPath).Path
  Say "Preflight: checking stale git index locks in $repoFullPath"
  & $resolverPath -Root $repoFullPath -MinAgeMinutes 15 | Out-Host
}

function Assert-HaConfigTarget {
  param([string]$Path)

  if (-not (Test-Path $Path)) {
    Fail "Target path '$Path' not available."
  }

  $configPath = Join-Path $Path "configuration.yaml"
  if (-not (Test-Path $configPath)) {
    Fail "Target path '$Path' does not look like a Home Assistant config (missing configuration.yaml)."
  }

  $secretsPath = Join-Path $Path "secrets.yaml"
  if (-not (Test-Path $secretsPath)) {
    Fail "Refusing deploy: missing secrets.yaml at target ($secretsPath)."
  }

  $secretsLines = Get-Content -Path $secretsPath -ErrorAction Stop
  $hasKeyValue = $false
  foreach ($line in $secretsLines) {
    if ($line -match '^\s*[^#\s][^:]*\s*:\s*.+') {
      $hasKeyValue = $true
      break
    }
  }
  if (-not $hasKeyValue) {
    Fail "Refusing deploy: secrets.yaml sanity check failed (no key/value entries found)."
  }
}

function Read-OpsStateFile {
  param([string]$Path)

  $data = @{}
  if (-not (Test-Path $Path)) {
    return $data
  }
  foreach ($line in (Get-Content -Path $Path -ErrorAction Stop)) {
    if ($line -match '^\s*([^=]+)=(.*)$') {
      $data[$matches[1].Trim()] = $matches[2].Trim()
    }
  }
  return $data
}

function Write-OpsStateFile {
  param(
    [string]$Path,
    [string]$Head,
    [string]$Branch
  )

  $timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssK"
  $content = @(
    "HEAD=$Head"
    "BRANCH=$Branch"
    "TIMESTAMP=$timestamp"
  )
  $utf8NoBom = New-Object System.Text.UTF8Encoding $false
  [System.IO.File]::WriteAllLines($Path, $content, $utf8NoBom)
}

function Resolve-BackupRoot {
  param(
    [string]$RepoRoot,
    [string]$ConfiguredBackupRoot
  )

  $candidates = @()

  if ($ConfiguredBackupRoot) {
    if ([System.IO.Path]::IsPathRooted($ConfiguredBackupRoot)) {
      $candidates += $ConfiguredBackupRoot
    } else {
      $candidates += (Join-Path $RepoRoot $ConfiguredBackupRoot)
    }
  }

  $externalArchiveRoot = Join-Path ([System.IO.Path]::GetDirectoryName($RepoRoot)) "_repo_archives\aeb\_ha_runtime_backups"
  if ($candidates -notcontains $externalArchiveRoot) {
    $candidates += $externalArchiveRoot
  }

  foreach ($candidate in $candidates) {
    if ([string]::IsNullOrWhiteSpace($candidate)) { continue }
    if (Test-Path $candidate) {
      return (Resolve-Path $candidate).Path
    }
  }

  $preferred = $candidates[0]
  if (-not [System.IO.Path]::IsPathRooted($preferred)) {
    $preferred = Join-Path $RepoRoot $preferred
  }
  New-Item -ItemType Directory -Force -Path $preferred | Out-Null
  return (Resolve-Path $preferred).Path
}

function Copy-Allowed {
  param(
    [string]$SourceRoot,
    [string]$TargetRoot,
    [string[]]$AllowedDirs,
    [string[]]$AllowedFiles
  )

  foreach ($dir in $AllowedDirs) {
    $srcDir = Join-Path $SourceRoot $dir
    if (Test-Path $srcDir) {
      $dstDir = Join-Path $TargetRoot $dir
      Say "-> dir  $dir"
      & robocopy $srcDir $dstDir /MIR /R:1 /W:1 /NFL /NDL /NP /NJH /NJS
      if ($LASTEXITCODE -ge 8) {
        throw "Deploy robocopy failed for '$dir' (RC=$LASTEXITCODE)"
      }
    }
  }

  foreach ($file in $AllowedFiles) {
    $srcFile = Join-Path $SourceRoot $file
    if (Test-Path $srcFile) {
      $dstFile = Join-Path $TargetRoot $file
      Say "-> file $file"
      Copy-Item -Path $srcFile -Destination $dstFile -Force
    }
  }
}

function Get-SshExe {
  $ssh = Get-Command ssh.exe -ErrorAction SilentlyContinue
  if (-not $ssh) {
    Fail "ssh.exe not available."
  }
  return $ssh.Source
}

function Get-TarExe {
  $tar = Get-Command tar.exe -ErrorAction SilentlyContinue
  if (-not $tar) {
    Fail "tar.exe not available."
  }
  return $tar.Source
}

function New-SafeSshKeyCopy {
  param(
    [Parameter(Mandatory = $true)]
    [string]$SourcePath
  )

  if (-not (Test-Path -LiteralPath $SourcePath)) {
    throw "SSH key source not found: $SourcePath"
  }

  $tmpRoot = Join-Path -Path $PSScriptRoot -ChildPath ".tmp"
  New-Item -ItemType Directory -Force -Path $tmpRoot | Out-Null

  $safePath = Join-Path -Path $tmpRoot -ChildPath ("deploy_ssh_key.{0}.safe" -f ([guid]::NewGuid().ToString('N')))
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

function Get-DeployKeyPath {
  if ([string]::IsNullOrWhiteSpace($env:HA_SSH_KEY_PATH)) {
    throw "HA_SSH_KEY_PATH is required."
  }
  return New-SafeSshKeyCopy -SourcePath $env:HA_SSH_KEY_PATH
}

function Get-KnownHostsPath {
  if ($env:HA_SSH_KNOWN_HOSTS -and (Test-Path -LiteralPath $env:HA_SSH_KNOWN_HOSTS)) {
    return $env:HA_SSH_KNOWN_HOSTS
  }
  throw "HA_SSH_KNOWN_HOSTS is required and must point to a readable file."
}

function Test-RemoteConfigTarget {
  param(
    [string]$HaSshScript,
    [string]$KeyPath,
    [string]$KnownHostsPath,
    [string]$RemoteHostName,
    [int]$Port,
    [string]$RemoteContainer,
    [string]$Path
  )

  & $HaSshScript -Port $Port -HaHost $RemoteHostName -KeyPath $KeyPath -KnownHostsPath $KnownHostsPath -RemoteCommand "docker exec $RemoteContainer test -f $Path/configuration.yaml" | Out-Null
  if ($LASTEXITCODE -ne 0) {
    throw "Remote target '${RemoteHostName}:${RemoteContainer}:${Path}' does not look like a Home Assistant config."
  }

  & $HaSshScript -Port $Port -HaHost $RemoteHostName -KeyPath $KeyPath -KnownHostsPath $KnownHostsPath -RemoteCommand "docker exec $RemoteContainer test -f $Path/secrets.yaml" | Out-Null
  if ($LASTEXITCODE -ne 0) {
    throw "Remote target '${RemoteHostName}:${RemoteContainer}:${Path}' does not look like a Home Assistant config."
  }
}

function Invoke-RemoteMirror {
  param(
    [string]$HaSshScript,
    [string]$TarExe,
    [string]$KeyPath,
    [string]$KnownHostsPath,
    [string]$RemoteHostName,
    [int]$Port,
    [string]$RemoteContainer,
    [string]$RemotePath,
    [string]$LocalPath,
    [string[]]$Entries
  )

  $existingEntries = @()
  foreach ($entry in $Entries) {
    $probe = "docker exec $RemoteContainer test -e $RemotePath/$entry"
    & $HaSshScript -Port $Port -HaHost $RemoteHostName -KeyPath $KeyPath -KnownHostsPath $KnownHostsPath -RemoteCommand $probe | Out-Null
    if ($LASTEXITCODE -eq 0) {
      $existingEntries += $entry
    }
  }

  if ($existingEntries.Count -eq 0) { throw 'Remote backup has no existing entries.' }
  $archivePath = Join-Path ([System.IO.Path]::GetTempPath()) ("aeb-backup-{0}.tar.gz" -f [guid]::NewGuid().ToString('N'))
  try {
    $remoteCommand = "docker exec $RemoteContainer tar -czf - -C $RemotePath " + ($existingEntries -join ' ')
    $sshArgs = Get-AebSshArguments -KeyPath $KeyPath -KnownHostsPath $KnownHostsPath -RemoteHostName $RemoteHostName -Port $Port -RemoteCommand $remoteCommand
    $backup = Invoke-AebBoundedProcess -FilePath (Get-SshExe) -ArgumentList $sshArgs -OutputFile $archivePath -TimeoutSeconds $TransferTimeoutSeconds -HeartbeatSeconds $HeartbeatSeconds -Label 'remote backup transfer'
    if ($backup.ExitCode -ne 0) { throw "Remote backup SSH failed (RC=$($backup.ExitCode)): $($backup.Stderr.Trim())" }
    & $TarExe -tzf $archivePath | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Remote backup archive validation failed (tar RC=$LASTEXITCODE)." }
    & $TarExe -xzf $archivePath -C $LocalPath
    if ($LASTEXITCODE -ne 0) { throw "Remote backup extraction failed (tar RC=$LASTEXITCODE)." }
    Say ("[OK] Remote backup completed in {0}s" -f $backup.DurationSeconds)
  }
  finally {
    Remove-Item -LiteralPath $archivePath -Force -ErrorAction SilentlyContinue
  }
}

function Invoke-RemoteDeploy {
  param(
    [string]$HaSshScript,
    [string]$TarExe,
    [string]$KeyPath,
    [string]$KnownHostsPath,
    [string]$RemoteHostName,
    [int]$Port,
    [string]$RemoteContainer,
    [string]$RemotePath,
    [string]$SourceRoot,
    [string[]]$Entries
  )

  $existingEntries = @()
  foreach ($entry in $Entries) {
    if (Test-Path -LiteralPath (Join-Path $SourceRoot $entry)) {
      $existingEntries += $entry
    }
  }

  if ($existingEntries.Count -eq 0) { throw 'Deploy archive has no existing entries.' }
  $archivePath = Join-Path ([System.IO.Path]::GetTempPath()) ("aeb-deploy-{0}.tar.gz" -f [guid]::NewGuid().ToString('N'))
  $remoteArchive = "/tmp/aeb-deploy-{0}.tar.gz" -f [guid]::NewGuid().ToString('N')
  try {
    & $TarExe -czf $archivePath -C $SourceRoot @existingEntries
    if ($LASTEXITCODE -ne 0) { throw "Local deploy archive creation failed (tar RC=$LASTEXITCODE)." }
    & $TarExe -tzf $archivePath | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Local deploy archive validation failed (tar RC=$LASTEXITCODE)." }

    $uploadCommand = "umask 077; cat > $remoteArchive"
    $uploadArgs = Get-AebSshArguments -KeyPath $KeyPath -KnownHostsPath $KnownHostsPath -RemoteHostName $RemoteHostName -Port $Port -RemoteCommand $uploadCommand
    $upload = Invoke-AebBoundedProcess -FilePath (Get-SshExe) -ArgumentList $uploadArgs -InputFile $archivePath -TimeoutSeconds $TransferTimeoutSeconds -HeartbeatSeconds $HeartbeatSeconds -Label 'remote deploy upload'
    if ($upload.ExitCode -ne 0) { throw "Remote deploy upload failed (SSH RC=$($upload.ExitCode)): $($upload.Stderr.Trim())" }

    $localHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $archivePath).Hash.ToLowerInvariant()
    $promoteCommand = "test `$(sha256sum $remoteArchive | cut -d' ' -f1) = $localHash && docker cp $remoteArchive ${RemoteContainer}:/tmp/aeb-deploy.tar.gz && docker exec $RemoteContainer tar -tzf /tmp/aeb-deploy.tar.gz >/dev/null && docker exec $RemoteContainer tar -xzf /tmp/aeb-deploy.tar.gz -C $RemotePath"
    $promoteArgs = Get-AebSshArguments -KeyPath $KeyPath -KnownHostsPath $KnownHostsPath -RemoteHostName $RemoteHostName -Port $Port -RemoteCommand $promoteCommand
    $promote = Invoke-AebBoundedProcess -FilePath (Get-SshExe) -ArgumentList $promoteArgs -TimeoutSeconds $TransferTimeoutSeconds -HeartbeatSeconds $HeartbeatSeconds -Label 'remote deploy validation and extraction'
    if ($promote.ExitCode -ne 0) { throw "Remote deploy promotion failed (SSH RC=$($promote.ExitCode)): $($promote.Stderr.Trim())" }
    Say ("[OK] Remote deploy uploaded in {0}s and extracted in {1}s" -f $upload.DurationSeconds, $promote.DurationSeconds)
  }
  finally {
    Remove-Item -LiteralPath $archivePath -Force -ErrorAction SilentlyContinue
    $cleanupCommand = "rm -f $remoteArchive; docker exec $RemoteContainer rm -f /tmp/aeb-deploy.tar.gz"
    try {
      $cleanupArgs = Get-AebSshArguments -KeyPath $KeyPath -KnownHostsPath $KnownHostsPath -RemoteHostName $RemoteHostName -Port $Port -RemoteCommand $cleanupCommand
      $cleanup = Invoke-AebBoundedProcess -FilePath (Get-SshExe) -ArgumentList $cleanupArgs -TimeoutSeconds 30 -HeartbeatSeconds $HeartbeatSeconds -Label 'remote deploy cleanup'
      if ($cleanup.ExitCode -ne 0) { Say "[WARN] Remote deploy cleanup failed (SSH RC=$($cleanup.ExitCode)): $($cleanup.Stderr.Trim())" }
    } catch { Say "[WARN] Remote deploy cleanup failed: $($_.Exception.Message)" }
  }
}

Say "== Deploy SAFE =="

# --------------------------------------------------
# Repo context
# --------------------------------------------------
Resolve-StaleGitIndexLocks -RepoPath $PSScriptRoot\..
$repoRoot = (git rev-parse --show-toplevel)
Set-Location $repoRoot

Say "Repo   : $repoRoot"
Say "Target : $Target"
Say "RemoteHost : $RemoteHost"
Say "RemoteContainer : $RemoteContainer"
Say "RemotePath : $RemotePath"
Say "Branch : $Branch"
Say "IncludeTts : $IncludeTts"
Say "IncludeWww : $IncludeWww"
Say "IncludeBlueprints : $IncludeBlueprints"
Say "AllowDirty : $AllowDirty"
Say "RunGates   : $RunGates"
Say "RunConfigCheck : $RunConfigCheck"
Say "Restart    : $Restart"
Say "DryRun     : $DryRun"

if ($Restart -and -not $RunConfigCheck) {
  throw '-Restart requires -RunConfigCheck.'
}

# --------------------------------------------------
# 0) Refuse dirty working tree
# --------------------------------------------------
$statusLines = git status --porcelain
if ($statusLines) {
  $ignoredStatus = $statusLines | Where-Object { $_ -match '^\?\?\s+(\.ops_state/|ops/_logs/)' }
  if ($ignoredStatus) {
    Say "Ignoring untracked operational paths: .ops_state/, ops/_logs/"
  }
  $remainingStatus = $statusLines | Where-Object { $_ -notmatch '^\?\?\s+(\.ops_state/|ops/_logs/)' }
  if ($remainingStatus) {
    if ($AllowDirty) {
      Say "Working tree dirty, but -AllowDirty set -> continuing with current validated workspace snapshot"
    } else {
      throw "Working tree NOT clean. Commit/stash first."
    }
  }
}

function Mirror-Allowed {
  param(
    [string]$SourceRoot,
    [string]$TargetRoot,
    [string[]]$AllowedDirs,
    [string[]]$AllowedFiles
  )

  foreach ($dir in $AllowedDirs) {
    $srcDir = Join-Path $SourceRoot $dir
    if (Test-Path $srcDir) {
      $dstDir = Join-Path $TargetRoot $dir
      Say "-> backup dir  $dir"
      & robocopy $srcDir $dstDir /MIR /R:1 /W:1 /NFL /NDL /NP /NJH /NJS
      if ($LASTEXITCODE -ge 8) {
        throw "Backup robocopy failed for '$dir' (RC=$LASTEXITCODE)"
      }
    }
  }

  foreach ($file in $AllowedFiles) {
    $srcFile = Join-Path $SourceRoot $file
    if (Test-Path $srcFile) {
      $dstFile = Join-Path $TargetRoot $file
      $dstParent = Split-Path -Parent $dstFile
      if ($dstParent) {
        New-Item -ItemType Directory -Force -Path $dstParent | Out-Null
      }
      Say "-> backup file $file"
      Copy-Item -Path $srcFile -Destination $dstFile -Force
    }
  }
}

# --------------------------------------------------
# 0a) Path stato operativo (repo)
# --------------------------------------------------
$opsStateDir = Join-Path $repoRoot ".ops_state"
$gatesFile = Join-Path $opsStateDir "gates.ok"
$gatesStatePath = Join-Path $PSScriptRoot ".gates_state.json"

$tarExe = Get-TarExe
$keyPath = Get-DeployKeyPath
$knownHostsPath = Get-KnownHostsPath
$haSshScript = Join-Path $PSScriptRoot "ha_ssh.ps1"
$useRemoteDeploy = $false
$cleanupKeyPath = $keyPath
trap {
  if ($cleanupKeyPath -and (Test-Path -LiteralPath $cleanupKeyPath)) {
    Remove-Item -LiteralPath $cleanupKeyPath -Force -ErrorAction SilentlyContinue
  }
  throw $_
}

# --------------------------------------------------
# 0b) Preflight target path
# --------------------------------------------------
if (Test-Path $Target) {
  # Local/share deploy path.
  Assert-HaConfigTarget -Path $Target
} else {
  $useRemoteDeploy = $true
  Say "Local target '$Target' not available; falling back to remote deploy on $RemoteHost"
  Test-RemoteConfigTarget -HaSshScript $haSshScript -KeyPath $keyPath -KnownHostsPath $knownHostsPath -RemoteHostName $RemoteHost -Port $RemotePort -RemoteContainer $RemoteContainer -Path $RemotePath
}

# --------------------------------------------------
# 1) Update local branch (ff-only)
# --------------------------------------------------
Say "`n==> git fetch"
git fetch origin

Say "`n==> git ff-only to origin/$Branch"
git merge --ff-only "origin/$Branch"

# --------------------------------------------------
# 1b) Quality gates (must pass for current HEAD)
# --------------------------------------------------
$currentHead = (git rev-parse HEAD).Trim()
$currentBranch = (git rev-parse --abbrev-ref HEAD).Trim()

$gatesAttestPath = Join-Path $PSScriptRoot "gates_attest_main.txt"
$skipLocalGates = $false
if ($Branch -eq "main" -and (Test-Path $gatesAttestPath)) {
  $hasPassed = Select-String -Path $gatesAttestPath -Pattern "PASSED" -Quiet
  if ($hasPassed) {
    Say "Remote gates attested for main -> skipping local gates"
    $skipLocalGates = $true
  }
}

if (-not $skipLocalGates) {
  $gatesState = $null
  if (Test-Path $gatesStatePath) {
    $gatesState = Get-Content -Path $gatesStatePath -Raw -ErrorAction Stop | ConvertFrom-Json
  }

  $needsGates = $true
  if ($gatesState -and $gatesState.head -eq $currentHead -and $gatesState.status -eq "passed") {
    $needsGates = $false
  }

  if ($needsGates) {
    Say "Gates missing/stale -> running ops/gates_run.ps1"
    & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "gates_run.ps1")
  }

  $gatesState = $null
  if (Test-Path $gatesStatePath) {
    $gatesState = Get-Content -Path $gatesStatePath -Raw -ErrorAction Stop | ConvertFrom-Json
  }

  if (-not $gatesState -or $gatesState.head -ne $currentHead -or $gatesState.status -ne "passed") {
    Fail "Gates failed or stale. Expected head '$currentHead' with status 'passed' in $gatesStatePath."
  }
}

if ($DryRun) {
  $dryRunDirs = @('packages', 'lovelace', 'custom_components', 'themes')
  if ($IncludeBlueprints) { $dryRunDirs += 'blueprints' }
  if ($IncludeWww) { $dryRunDirs += 'www' }
  if ($IncludeTts) { $dryRunDirs += 'tts' }
  $dryRunFiles = @('configuration.yaml', 'automations.yaml', 'scripts.yaml', 'scenes.yaml', 'groups.yaml', 'customize.yaml')
  Say "`n==> DRY RUN (no backup, upload, extraction, restart or marker)"
  Say ("Transport : bounded SSH archive; timeout={0}s; heartbeat={1}s" -f $TransferTimeoutSeconds, $HeartbeatSeconds)
  Say ("Destination: {0}:{1}:{2}" -f $RemoteHost, $RemoteContainer, $RemotePath)
  Say ("Directories: {0}" -f ($dryRunDirs -join ', '))
  Say ("Files      : {0}" -f ($dryRunFiles -join ', '))
  Say 'Excluded   : secrets.yaml, .storage, .cloud, backup, backups, media, tts/www unless explicitly enabled'
  Say '[OK] Deploy SAFE dry run completed without runtime writes.'
  if ($cleanupKeyPath -and (Test-Path -LiteralPath $cleanupKeyPath)) {
    Remove-Item -LiteralPath $cleanupKeyPath -Force -ErrorAction SilentlyContinue
  }
  exit 0
}

# --------------------------------------------------
# 3) BACKUP target -> LOCAL backup (NO .storage)
# --------------------------------------------------
$stamp = (Get-Date -Format "yyyyMMdd_HHmmss")
$resolvedBackupRoot = Resolve-BackupRoot -RepoRoot $repoRoot -ConfiguredBackupRoot $BackupRoot
$backupDir = Join-Path $resolvedBackupRoot ("deploy_" + $stamp)
New-Item -ItemType Directory -Force -Path $backupDir | Out-Null

Say "`n==> BACKUP target to $backupDir"

$backupAllowedDirs = @(
  "packages",
  "lovelace",
  "custom_components",
  "themes"
)

if ($IncludeBlueprints) { $backupAllowedDirs += "blueprints" }
if ($IncludeWww) { $backupAllowedDirs += "www" }
if ($IncludeTts) { $backupAllowedDirs += "tts" }

$backupAllowedFiles = @(
  "configuration.yaml",
  "automations.yaml",
  "scripts.yaml",
  "scenes.yaml",
  "groups.yaml",
  "customize.yaml"
)
if ($useRemoteDeploy) {
  $backupEntries = @()
  $backupEntries += $backupAllowedDirs
  $backupEntries += $backupAllowedFiles
  Invoke-RemoteMirror -HaSshScript $haSshScript -TarExe $tarExe -KeyPath $keyPath -KnownHostsPath $knownHostsPath -RemoteHostName $RemoteHost -Port $RemotePort -RemoteContainer $RemoteContainer -RemotePath $RemotePath -LocalPath $backupDir -Entries $backupEntries
} else {
  Mirror-Allowed -SourceRoot $Target -TargetRoot $backupDir -AllowedDirs $backupAllowedDirs -AllowedFiles $backupAllowedFiles
}

# --------------------------------------------------
# 4) DEPLOY repo -> TARGET (NO .storage)
# --------------------------------------------------
Say "`n==> DEPLOY repo -> target"

$allowedDirs = @(
  "packages",
  "lovelace",
  "custom_components",
  "themes"
)

if ($IncludeBlueprints) { $allowedDirs += "blueprints" }
if ($IncludeWww) { $allowedDirs += "www" }
if ($IncludeTts) { $allowedDirs += "tts" }

$allowedFiles = @(
  "configuration.yaml",
  "automations.yaml",
  "scripts.yaml",
  "scenes.yaml",
  "groups.yaml",
  "customize.yaml"
)

if ($useRemoteDeploy) {
  $deployEntries = @()
  $deployEntries += $allowedDirs
  $deployEntries += $allowedFiles
  Invoke-RemoteDeploy -HaSshScript $haSshScript -TarExe $tarExe -KeyPath $keyPath -KnownHostsPath $knownHostsPath -RemoteHostName $RemoteHost -Port $RemotePort -RemoteContainer $RemoteContainer -RemotePath $RemotePath -SourceRoot $repoRoot -Entries $deployEntries
} else {
  Copy-Allowed -SourceRoot $repoRoot -TargetRoot $Target -AllowedDirs $allowedDirs -AllowedFiles $allowedFiles
}

# --------------------------------------------------
# 5) Optional post-deploy config check (best effort)
# --------------------------------------------------
if ($RunConfigCheck) {
  Say "`n==> POST-DEPLOY: Home Assistant config check"
  if ($useRemoteDeploy) {
    $checkCommand = "docker exec $RemoteContainer python -m homeassistant --script check_config -c $RemotePath"
    $checkArgs = Get-AebSshArguments -KeyPath $keyPath -KnownHostsPath $knownHostsPath -RemoteHostName $RemoteHost -Port $RemotePort -RemoteCommand $checkCommand
    $check = Invoke-AebBoundedProcess -FilePath (Get-SshExe) -ArgumentList $checkArgs -TimeoutSeconds $TransferTimeoutSeconds -HeartbeatSeconds $HeartbeatSeconds -Label 'Home Assistant config check'
    if ($check.Stdout) { Write-Host $check.Stdout.TrimEnd() }
    if ($check.ExitCode -ne 0) { throw "Remote Home Assistant config check failed (RC=$($check.ExitCode)): $($check.Stderr.Trim())" }
    Say ("[OK] Remote Home Assistant config check passed in {0}s." -f $check.DurationSeconds)
  } elseif (Get-Command ha -ErrorAction SilentlyContinue) {
    & ha core check
    if ($LASTEXITCODE -ne 0) {
      throw "ha core check failed (RC=$LASTEXITCODE)"
    }
    Say "[OK] ha core check passed."
  } else {
    Say "ha CLI not found. Run on HA host: 'ha core check' or use UI -> Server Controls -> Check Configuration."
  }
}

if ($Restart) {
  Say "`n==> POST-DEPLOY: controlled Home Assistant restart"
  if (-not $useRemoteDeploy) { throw 'Controlled restart is supported only for remote Docker deploys.' }
  $restartArgs = Get-AebSshArguments -KeyPath $keyPath -KnownHostsPath $knownHostsPath -RemoteHostName $RemoteHost -Port $RemotePort -RemoteCommand "docker restart $RemoteContainer"
  $restartResult = Invoke-AebBoundedProcess -FilePath (Get-SshExe) -ArgumentList $restartArgs -TimeoutSeconds 120 -HeartbeatSeconds $HeartbeatSeconds -Label 'Home Assistant restart'
  if ($restartResult.ExitCode -ne 0) { throw "Remote Home Assistant restart failed (RC=$($restartResult.ExitCode)): $($restartResult.Stderr.Trim())" }
  Say ("[OK] Home Assistant restart completed in {0}s." -f $restartResult.DurationSeconds)
}

# --------------------------------------------------
# 6) Scrive last_deploy.ok e consuma gates.ok
# --------------------------------------------------
New-Item -ItemType Directory -Force -Path $opsStateDir | Out-Null
Write-OpsStateFile -Path (Join-Path $opsStateDir "last_deploy.ok") -Head $currentHead -Branch $currentBranch
Remove-Item -Force -ErrorAction SilentlyContinue $gatesFile

Say "`n[OK] Deploy SAFE completed."

if ($cleanupKeyPath -and (Test-Path -LiteralPath $cleanupKeyPath)) {
  Remove-Item -LiteralPath $cleanupKeyPath -Force -ErrorAction SilentlyContinue
}
