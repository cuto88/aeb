[CmdletBinding()]
param(
  [string]$Source = "Z:\",
  [string]$DestinationRoot = ".\_dr_backups",
  [switch]$IncludeStorage,
  [switch]$IncludeSecrets,
  [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

function Say([string]$Message) {
  Write-Host $Message
}

function Resolve-FullPath([string]$Path) {
  return [System.IO.Path]::GetFullPath((Resolve-Path -LiteralPath $Path).Path)
}

function Get-RelativePath {
  param(
    [Parameter(Mandatory = $true)][string]$Root,
    [Parameter(Mandatory = $true)][string]$Path
  )

  $rootFull = [System.IO.Path]::GetFullPath($Root.TrimEnd('\', '/'))
  if (-not $rootFull.EndsWith([System.IO.Path]::DirectorySeparatorChar)) {
    $rootFull += [System.IO.Path]::DirectorySeparatorChar
  }

  $pathFull = [System.IO.Path]::GetFullPath($Path)
  if ($pathFull.StartsWith($rootFull, [System.StringComparison]::OrdinalIgnoreCase)) {
    return $pathFull.Substring($rootFull.Length)
  }
  return [System.IO.Path]::GetFileName($pathFull)
}

function New-ItemRecord {
  param(
    [Parameter(Mandatory = $true)][string]$SourceRoot,
    [Parameter(Mandatory = $true)][string]$ItemPath,
    [Parameter(Mandatory = $true)][string]$BackupRoot
  )

  $item = Get-Item -LiteralPath $ItemPath
  $relative = Get-RelativePath -Root $SourceRoot -Path $ItemPath
  $backupPath = Join-Path $BackupRoot $relative
  $record = [ordered]@{
    relative_path   = $relative
    backup_path     = $backupPath
    kind            = if ($item.PSIsContainer) { 'directory' } else { 'file' }
    bytes           = if ($item.PSIsContainer) { $null } else { [int64]$item.Length }
    last_write_time = $item.LastWriteTimeUtc.ToString('o')
    sha256          = $null
  }

  if (-not $item.PSIsContainer) {
    $record.sha256 = (Get-FileHash -LiteralPath $ItemPath -Algorithm SHA256).Hash
  }

  return [pscustomobject]$record
}

if (-not (Test-Path -LiteralPath $Source)) {
  throw "Source path not found: $Source"
}

$sourceRoot = (Resolve-Path -LiteralPath $Source).Path
$destinationRootFull = if ([System.IO.Path]::IsPathRooted($DestinationRoot)) {
  [System.IO.Path]::GetFullPath($DestinationRoot)
} else {
  [System.IO.Path]::GetFullPath((Join-Path (Get-Location) $DestinationRoot))
}

$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$snapshotName = "ha_runtime_snapshot_$timestamp"
$snapshotRoot = Join-Path $destinationRootFull $snapshotName

$rootFiles = @(
  'configuration.yaml',
  'automations.yaml',
  'scripts.yaml',
  'scenes.yaml',
  'groups.yaml',
  'customize.yaml',
  '.HA_VERSION'
)

$rootDirs = @(
  'packages',
  'lovelace',
  'custom_components',
  'themes',
  'blueprints',
  'www',
  'tts'
)

$plannedItems = New-Object System.Collections.Generic.List[object]

foreach ($file in $rootFiles) {
  $path = Join-Path $sourceRoot $file
  if (Test-Path -LiteralPath $path) {
    $plannedItems.Add((New-ItemRecord -SourceRoot $sourceRoot -ItemPath $path -BackupRoot $snapshotRoot))
  }
}

foreach ($dir in $rootDirs) {
  $path = Join-Path $sourceRoot $dir
  if (Test-Path -LiteralPath $path) {
    foreach ($child in Get-ChildItem -LiteralPath $path -File -Recurse) {
      $plannedItems.Add((New-ItemRecord -SourceRoot $sourceRoot -ItemPath $child.FullName -BackupRoot $snapshotRoot))
    }
  }
}

if ($IncludeStorage) {
  $storagePath = Join-Path $sourceRoot '.storage'
  if (Test-Path -LiteralPath $storagePath) {
    foreach ($child in Get-ChildItem -LiteralPath $storagePath -File -Recurse) {
      $plannedItems.Add((New-ItemRecord -SourceRoot $sourceRoot -ItemPath $child.FullName -BackupRoot $snapshotRoot))
    }
  }
}

if ($IncludeSecrets) {
  $secretPath = Join-Path $sourceRoot 'secrets.yaml'
  if (Test-Path -LiteralPath $secretPath) {
    $plannedItems.Add((New-ItemRecord -SourceRoot $sourceRoot -ItemPath $secretPath -BackupRoot $snapshotRoot))
  }
}

$requiredConfig = Join-Path $sourceRoot 'configuration.yaml'
if (-not (Test-Path -LiteralPath $requiredConfig)) {
  throw "Source does not look like a Home Assistant config: missing configuration.yaml"
}

if ($DryRun) {
  Say "DRY-RUN source=$sourceRoot destination=$snapshotRoot items=$($plannedItems.Count)"
  Say "No files were written."
  exit 0
}

New-Item -ItemType Directory -Force -Path $snapshotRoot | Out-Null

foreach ($dir in $rootDirs) {
  $path = Join-Path $sourceRoot $dir
  if (Test-Path -LiteralPath $path) {
    $dest = Join-Path $snapshotRoot $dir
    New-Item -ItemType Directory -Force -Path $dest | Out-Null
    & robocopy $path $dest /MIR /R:1 /W:1 /NFL /NDL /NP /NJH /NJS | Out-Null
    if ($LASTEXITCODE -ge 8) {
      throw "Failed to copy directory '$dir' (RC=$LASTEXITCODE)"
    }
  }
}

foreach ($file in $rootFiles) {
  $path = Join-Path $sourceRoot $file
  if (Test-Path -LiteralPath $path) {
    Copy-Item -LiteralPath $path -Destination (Join-Path $snapshotRoot $file) -Force
  }
}

if ($IncludeStorage) {
  $storagePath = Join-Path $sourceRoot '.storage'
  if (Test-Path -LiteralPath $storagePath) {
    $dest = Join-Path $snapshotRoot '.storage'
    New-Item -ItemType Directory -Force -Path $dest | Out-Null
    & robocopy $storagePath $dest /MIR /R:1 /W:1 /NFL /NDL /NP /NJH /NJS | Out-Null
    if ($LASTEXITCODE -ge 8) {
      throw "Failed to copy .storage (RC=$LASTEXITCODE)"
    }
  }
}

if ($IncludeSecrets) {
  $secretPath = Join-Path $sourceRoot 'secrets.yaml'
  if (Test-Path -LiteralPath $secretPath) {
    Copy-Item -LiteralPath $secretPath -Destination (Join-Path $snapshotRoot 'secrets.yaml') -Force
  }
}

$manifest = [ordered]@{
  schema            = 'aeb.dr.backup.v1'
  created_at        = (Get-Date).ToString('o')
  source           = $sourceRoot
  destination_root = $destinationRootFull
  snapshot_root    = $snapshotRoot
  include_storage  = [bool]$IncludeStorage
  include_secrets  = [bool]$IncludeSecrets
  dry_run          = [bool]$DryRun
  items            = $plannedItems
}

$manifestPath = Join-Path $snapshotRoot 'manifest.json'
$manifest | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $manifestPath -Encoding utf8

$restoreText = @"
AEB Disaster Recovery snapshot
Created at: $((Get-Date).ToString('o'))
Source: $sourceRoot
Snapshot: $snapshotRoot

Restore order:
1. Stop Home Assistant.
2. Restore configuration.yaml and the runtime folders.
3. Restore .storage if it was included.
4. Restore secrets.yaml only if IncludeSecrets was enabled and the file belongs outside Git.
5. Start Home Assistant and run validation.

Do not treat this snapshot as a Git substitute.
"@

Set-Content -LiteralPath (Join-Path $snapshotRoot 'README_RESTORE.txt') -Value $restoreText -Encoding utf8

Say "OK source=$sourceRoot snapshot=$snapshotRoot items=$($plannedItems.Count)"
