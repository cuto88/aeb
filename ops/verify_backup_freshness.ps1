[CmdletBinding()]
param(
  [string]$BackupRoot = ".\_dr_backups",
  [int]$MaxAgeHours = 24
)

$ErrorActionPreference = 'Stop'

function Fail([string]$Message) {
  Write-Host "WARN $Message"
  exit 1
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

Write-Host "OK latest=$($latest.Name) age_hours=$ageHours items=$itemCount root=$BackupRoot"
exit 0

