param(
  [string]$Branch = "main",
  [string]$Target = "Z:\",
  [string]$BackupRoot = ".\_ha_runtime_backups",
  [switch]$IncludeTts,
  [switch]$IncludeWww,
  [switch]$IncludeBlueprints,
  [switch]$AllowDirty,
  [switch]$RunConfigCheck,
  [switch]$RunGates
)

$ErrorActionPreference = "Stop"

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

Say "== Deploy SAFE =="

# --------------------------------------------------
# Repo context
# --------------------------------------------------
Resolve-StaleGitIndexLocks -RepoPath $PSScriptRoot\..
$repoRoot = (git rev-parse --show-toplevel)
Set-Location $repoRoot

Say "Repo   : $repoRoot"
Say "Target : $Target"
Say "Branch : $Branch"
Say "IncludeTts : $IncludeTts"
Say "IncludeWww : $IncludeWww"
Say "IncludeBlueprints : $IncludeBlueprints"
Say "AllowDirty : $AllowDirty"
Say "RunGates   : $RunGates"

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

# --------------------------------------------------
# 0b) Preflight target path (map Z: if needed)
# --------------------------------------------------
if (!(Test-Path $Target)) {
  if ($Target -match '^[Zz]:\\?$') {
    $share = if ($env:HA_SMB_SHARE) { $env:HA_SMB_SHARE } else { "\\192.168.178.84\config" }
    $user = $env:HA_SMB_USER
    $pass = $env:HA_SMB_PASS
    $drive = "Z:"

    $netUseCommand = "net use $drive $share"
    $netUseArgs = @($drive, $share)
    if ($user) {
      $netUseCommand += " /USER:$user"
      $netUseArgs += "/USER:$user"
      if ($pass) {
        $netUseCommand += " $pass"
        $netUseArgs += $pass
      }
    }

    Say "`n==> map $drive to $share"
    & net use @netUseArgs | Out-Null

    if ($LASTEXITCODE -ne 0 -or !(Test-Path $Target)) {
      throw "Target path '$Target' not available. Failed to map drive. Run: $netUseCommand"
    }
  } elseif ($Target -like "Z:\\*") {
    $share = if ($env:HA_SMB_SHARE) { $env:HA_SMB_SHARE } else { "\\192.168.178.84\config" }
    $user = $env:HA_SMB_USER
    $pass = $env:HA_SMB_PASS
    $drive = "Z:"

    $netUseCommand = "net use $drive $share"
    $netUseArgs = @($drive, $share)
    if ($user) {
      $netUseCommand += " /USER:$user"
      $netUseArgs += "/USER:$user"
      if ($pass) {
        $netUseCommand += " $pass"
        $netUseArgs += $pass
      }
    }

    Say "`n==> map $drive to $share"
    & net use @netUseArgs | Out-Null

    if ($LASTEXITCODE -ne 0 -or !(Test-Path $Target)) {
      throw "Target path '$Target' not available. Failed to map drive. Run: $netUseCommand"
    }
  } else {
    throw "Target path '$Target' not available."
  }
}

# --------------------------------------------------
# 0c) Preflight target sanity (secrets/config present)
# --------------------------------------------------
Assert-HaConfigTarget -Path $Target

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

Mirror-Allowed -SourceRoot $Target -TargetRoot $backupDir -AllowedDirs $backupAllowedDirs -AllowedFiles $backupAllowedFiles

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

Copy-Allowed -SourceRoot $repoRoot -TargetRoot $Target -AllowedDirs $allowedDirs -AllowedFiles $allowedFiles

# --------------------------------------------------
# 5) Optional post-deploy config check (best effort)
# --------------------------------------------------
if ($RunConfigCheck) {
  Say "`n==> POST-DEPLOY: Home Assistant config check"
  if (Get-Command ha -ErrorAction SilentlyContinue) {
    & ha core check
    if ($LASTEXITCODE -ne 0) {
      throw "ha core check failed (RC=$LASTEXITCODE)"
    }
    Say "[OK] ha core check passed."
  } else {
    Say "ha CLI not found. Run on HA host: 'ha core check' or use UI -> Server Controls -> Check Configuration."
  }
}

# --------------------------------------------------
# 6) Scrive last_deploy.ok e consuma gates.ok
# --------------------------------------------------
New-Item -ItemType Directory -Force -Path $opsStateDir | Out-Null
Write-OpsStateFile -Path (Join-Path $opsStateDir "last_deploy.ok") -Head $currentHead -Branch $currentBranch
Remove-Item -Force -ErrorAction SilentlyContinue $gatesFile

Say "`n[OK] Deploy SAFE completed."
