[CmdletBinding(SupportsShouldProcess = $true)]
param(
  [string]$EvidencePath = "docs/runtime_evidence",
  [string]$BackupPath = "_ha_runtime_backups",
  [int]$EvidenceRetentionDays = 14,
  [int]$BackupRetentionDays = 21,
  [int]$KeepLatestEvidence = 3,
  [int]$KeepLatestBackups = 5
)

$ErrorActionPreference = "Stop"

function Get-RepoRoot {
  $root = (& git rev-parse --show-toplevel 2>$null)
  if (-not $root) {
    throw "Unable to resolve git repo root."
  }
  return $root.Trim()
}

function Get-PruneCandidates {
  param(
    [Parameter(Mandatory = $true)][string]$Path,
    [Parameter(Mandatory = $true)][int]$RetentionDays,
    [Parameter(Mandatory = $true)][int]$KeepLatest
  )

  if (-not (Test-Path -Path $Path)) {
    return @()
  }

  $cutoff = (Get-Date).AddDays(-1 * $RetentionDays)
  $entries = Get-ChildItem -Path $Path -Directory -Force |
    Sort-Object LastWriteTime -Descending

  if (-not $entries) {
    return @()
  }

  $protected = @($entries | Select-Object -First ([Math]::Max(0, $KeepLatest)))
  $protectedSet = New-Object System.Collections.Generic.HashSet[string]([System.StringComparer]::OrdinalIgnoreCase)
  foreach ($entry in $protected) {
    [void]$protectedSet.Add($entry.FullName)
  }

  $candidates = @()
  foreach ($entry in $entries) {
    if ($protectedSet.Contains($entry.FullName)) {
      continue
    }
    if ($entry.LastWriteTime -lt $cutoff) {
      $candidates += $entry
    }
  }

  return $candidates
}

function Invoke-Prune {
  param(
    [Parameter(Mandatory = $true)][string]$Label,
    [Parameter(Mandatory = $true)][string]$Path,
    [Parameter(Mandatory = $true)][int]$RetentionDays,
    [Parameter(Mandatory = $true)][int]$KeepLatest
  )

  Write-Host ""
  Write-Host ("==> {0}" -f $Label)
  Write-Host ("Path          : {0}" -f $Path)
  Write-Host ("RetentionDays : {0}" -f $RetentionDays)
  Write-Host ("KeepLatest    : {0}" -f $KeepLatest)

  if (-not (Test-Path -Path $Path)) {
    Write-Host "Path not found, skipping."
    return
  }

  $candidates = Get-PruneCandidates -Path $Path -RetentionDays $RetentionDays -KeepLatest $KeepLatest
  if (-not $candidates -or $candidates.Count -eq 0) {
    Write-Host "Nothing to prune."
    return
  }

  $removed = 0
  foreach ($candidate in $candidates) {
    $target = $candidate.FullName
    if ($PSCmdlet.ShouldProcess($target, "Remove old runtime retention directory")) {
      Remove-Item -Path $target -Recurse -Force
      $removed++
      Write-Host ("Removed: {0}" -f $target)
    }
  }

  Write-Host ("Prune result: removed={0} candidates={1}" -f $removed, $candidates.Count)
}

$repoRoot = Get-RepoRoot
Set-Location $repoRoot

$evidenceFullPath = Join-Path $repoRoot $EvidencePath
$backupFullPath = Join-Path $repoRoot $BackupPath

Write-Host "========================================="
Write-Host " Runtime Retention Prune"
Write-Host "========================================="
Write-Host ("Repo: {0}" -f $repoRoot)

Invoke-Prune -Label "Runtime evidence" -Path $evidenceFullPath -RetentionDays $EvidenceRetentionDays -KeepLatest $KeepLatestEvidence
Invoke-Prune -Label "Runtime backups" -Path $backupFullPath -RetentionDays $BackupRetentionDays -KeepLatest $KeepLatestBackups

Write-Host ""
Write-Host "Done."
exit 0
