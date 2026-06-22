[CmdletBinding()]
param(
  [string]$BackupRoot = ".\_dr_backups",
  [int]$MaxAgeHours = 24
)

$ErrorActionPreference = 'Stop'

function Fail([string]$Message) {
  Write-Host "BACKUP_VERIFY_FAIL $Message"
  exit 1
}

if ($MaxAgeHours -le 0) {
  Fail "invalid_max_age_hours value=$MaxAgeHours"
}

if (-not (Test-Path -LiteralPath $BackupRoot)) {
  Fail "backup_root_missing path=$BackupRoot"
}

$dirs = Get-ChildItem -LiteralPath $BackupRoot -Directory -ErrorAction SilentlyContinue |
  Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'manifest.json') } |
  Sort-Object LastWriteTime -Descending

if (-not $dirs) {
  Fail "no_valid_backup_found root=$BackupRoot"
}

$latest = $dirs | Select-Object -First 1
$manifestPath = Join-Path $latest.FullName 'manifest.json'

try {
  $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
} catch {
  Fail "manifest_unreadable path=$manifestPath"
}

if ($manifest.schema -ne 'aeb.dr.backup.v1') {
  Fail "manifest_schema_invalid latest=$($latest.Name)"
}

if (-not $manifest.configuration_present) {
  Fail "configuration_not_confirmed latest=$($latest.Name)"
}

$restoreReadme = Join-Path $latest.FullName 'README_RESTORE.txt'
if (-not (Test-Path -LiteralPath $restoreReadme -PathType Leaf)) {
  Fail "restore_readme_missing latest=$($latest.Name)"
}

$created = $null
if ($manifest.created_at) {
  try {
    $created = [datetime]::Parse($manifest.created_at)
  } catch {
    $created = $null
  }
}

if (-not $created) {
  $created = $latest.LastWriteTime
}

$ageHours = [math]::Round(((Get-Date) - $created).TotalHours, 2)
if ($ageHours -gt $MaxAgeHours) {
  Fail "backup_stale latest=$($latest.Name) age_hours=$ageHours max_age_hours=$MaxAgeHours"
}

$itemCount = 0
if ($manifest.items) {
  $itemCount = @($manifest.items).Count
}

if ($itemCount -le 0) {
  Fail "manifest_empty latest=$($latest.Name)"
}

$configurationRecord = @($manifest.items) |
  Where-Object { $_.relative_path -eq 'configuration.yaml' } |
  Select-Object -First 1

if (-not $configurationRecord) {
  Fail "configuration_missing_from_manifest latest=$($latest.Name)"
}

$configurationBackupPath = Join-Path $latest.FullName 'configuration.yaml'
if (-not (Test-Path -LiteralPath $configurationBackupPath -PathType Leaf)) {
  Fail "configuration_missing_from_snapshot latest=$($latest.Name)"
}

Write-Host "BACKUP_VERIFY_OK latest=$($latest.Name) age_hours=$ageHours items=$itemCount root=$BackupRoot"
exit 0
