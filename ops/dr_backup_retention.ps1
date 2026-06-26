[CmdletBinding(SupportsShouldProcess = $true)]
param(
  [ValidateSet("Preview", "Prune")]
  [string]$Action = "Preview",
  [string]$BackupRoot = "",
  [int]$KeepDailyDays = 14,
  [int]$KeepWeeklyWeeks = 8,
  [string[]]$ProtectedSnapshots = @(),
  [switch]$ConfirmPrune
)

$ErrorActionPreference = "Stop"

function Say([string]$Message) {
  Write-Host $Message
}

function Write-Log([string]$LogFile, [string]$Message) {
  if (-not [string]::IsNullOrWhiteSpace($LogFile)) {
    Add-Content -LiteralPath $LogFile -Value $Message
  }
  Write-Host $Message
}

function Get-LogContext {
  param([string]$Root)

  $logRoot = Join-Path $Root "logs"
  try {
    New-Item -ItemType Directory -Force -Path $logRoot | Out-Null
    $probe = Join-Path $logRoot ("retention_probe_" + ([guid]::NewGuid().ToString("N")) + ".tmp")
    Set-Content -LiteralPath $probe -Value "probe" -Encoding utf8
    Remove-Item -LiteralPath $probe -Force -ErrorAction SilentlyContinue
    return $logRoot
  } catch {
    $fallback = Join-Path $repoRoot ".tmp\dr_backup_retention_logs"
    New-Item -ItemType Directory -Force -Path $fallback | Out-Null
    return $fallback
  }
}

function Get-SnapshotInfo {
  param([System.IO.DirectoryInfo]$Directory)

  $manifestPath = Join-Path $Directory.FullName 'manifest.json'
  if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
    return $null
  }

  try {
    $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
  } catch {
    return $null
  }

  if ($manifest.schema -ne 'aeb.dr.backup.v1') {
    return $null
  }

  if (-not $manifest.configuration_present) {
    return $null
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
    $created = $Directory.LastWriteTime
  }

  $itemCount = 0
  if ($manifest.items) {
    $itemCount = @($manifest.items).Count
  }

  if ($itemCount -le 0) {
    return $null
  }

  return [pscustomobject]@{
    Name = $Directory.Name
    FullName = $Directory.FullName
    CreatedAt = $created
    LastWriteTime = $Directory.LastWriteTime
    ItemCount = $itemCount
    SizeBytes = [int64](Get-ChildItem -LiteralPath $Directory.FullName -File -Recurse -Force | Measure-Object -Property Length -Sum).Sum
    Manifest = $manifest
  }
}

function Get-SnapshotCatalog {
  param([string]$Root)

  if (-not (Test-Path -LiteralPath $Root)) {
    throw "Backup root not found: $Root"
  }

  $regex = '^ha_runtime_snapshot_(\d{8})_(\d{6})$'
  $items = Get-ChildItem -LiteralPath $Root -Directory -Force |
    Where-Object { $_.Name -match $regex } |
    ForEach-Object { Get-SnapshotInfo -Directory $_ } |
    Where-Object { $null -ne $_ } |
    Sort-Object -Property @{ Expression = 'CreatedAt'; Descending = $true }, @{ Expression = 'Name'; Descending = $true }

  return @($items)
}

function Get-ProtectionSet {
  param([object[]]$Snapshots)

  $set = New-Object System.Collections.Generic.HashSet[string]([System.StringComparer]::OrdinalIgnoreCase)
  foreach ($snapshot in $Snapshots) {
    if ($null -eq $snapshot) {
      continue
    }
    if ($snapshot -is [string]) {
      $value = [string]$snapshot
      if (-not [string]::IsNullOrWhiteSpace($value)) {
        [void]$set.Add($value)
      }
      continue
    }

    $name = [string]$snapshot.Name
    $path = [string]$snapshot.FullName
    if (-not [string]::IsNullOrWhiteSpace($name)) {
      [void]$set.Add($name)
    }
    if (-not [string]::IsNullOrWhiteSpace($path)) {
      [void]$set.Add($path)
    }
  }
  return $set
}

function Get-RetentionPlan {
  param(
    [object[]]$Snapshots,
    [int]$KeepDailyDays,
    [int]$KeepWeeklyWeeks,
    [System.Collections.Generic.HashSet[string]]$ProtectedSet
  )

  $keepMap = New-Object System.Collections.Generic.HashSet[string]([System.StringComparer]::OrdinalIgnoreCase)
  $keepReasons = @{}
  $keep = New-Object System.Collections.Generic.List[object]
  if ($null -eq $ProtectedSet) {
    $ProtectedSet = New-Object System.Collections.Generic.HashSet[string]([System.StringComparer]::OrdinalIgnoreCase)
  }

  if (-not $Snapshots -or $Snapshots.Count -eq 0) {
    return [pscustomobject]@{
      Keep = @()
      Delete = @()
      EstimatedFreedBytes = [int64]0
    }
  }

  function Add-KeepSnapshot {
    param(
      [Parameter(Mandatory = $true)]$Snapshot,
      [Parameter(Mandatory = $true)][string]$Reason
    )

    if ($keepMap.Contains($Snapshot.FullName)) {
      return
    }

    [void]$keepMap.Add($Snapshot.FullName)
    $keepReasons[$Snapshot.FullName] = $Reason
    [void]$keep.Add([pscustomobject]@{
      Snapshot = $Snapshot
      Decision = 'keep'
      Reason = $Reason
    })
  }

  $latest = $Snapshots | Select-Object -First 1
  Add-KeepSnapshot -Snapshot $latest -Reason 'latest'

  foreach ($snapshot in $Snapshots) {
    if ($ProtectedSet.Contains($snapshot.Name) -or $ProtectedSet.Contains($snapshot.FullName)) {
      Add-KeepSnapshot -Snapshot $snapshot -Reason 'protected'
    }
  }

  $dailyCutoff = (Get-Date).Date.AddDays(-1 * [Math]::Max(0, $KeepDailyDays))
  $weeklyCutoff = (Get-Date).Date.AddDays(-7 * [Math]::Max(0, $KeepWeeklyWeeks))

  $dailyBuckets = @{}
  foreach ($snapshot in $Snapshots) {
    if ($snapshot.CreatedAt -lt $dailyCutoff) {
      continue
    }

    $dayKey = $snapshot.CreatedAt.ToString('yyyy-MM-dd')
    if (-not $dailyBuckets.ContainsKey($dayKey) -or $snapshot.CreatedAt -gt $dailyBuckets[$dayKey].CreatedAt) {
      $dailyBuckets[$dayKey] = $snapshot
    }
  }

  foreach ($entry in $dailyBuckets.GetEnumerator() | Sort-Object Name) {
    $snapshot = $entry.Value
    Add-KeepSnapshot -Snapshot $snapshot -Reason 'daily'
  }

  $weeklyBuckets = @{}
  foreach ($snapshot in $Snapshots) {
    if ($snapshot.CreatedAt -ge $dailyCutoff) {
      continue
    }
    if ($snapshot.CreatedAt -lt $weeklyCutoff) {
      continue
    }

    $week = [System.Globalization.ISOWeek]::GetWeekOfYear($snapshot.CreatedAt)
    $year = [System.Globalization.ISOWeek]::GetYear($snapshot.CreatedAt)
    $weekKey = ('{0:D4}-W{1:D2}' -f $year, $week)
    if (-not $weeklyBuckets.ContainsKey($weekKey) -or $snapshot.CreatedAt -gt $weeklyBuckets[$weekKey].CreatedAt) {
      $weeklyBuckets[$weekKey] = $snapshot
    }
  }

  foreach ($entry in $weeklyBuckets.GetEnumerator() | Sort-Object Name) {
    $snapshot = $entry.Value
    Add-KeepSnapshot -Snapshot $snapshot -Reason 'weekly'
  }

  $delete = New-Object System.Collections.Generic.List[object]
  foreach ($snapshot in $Snapshots) {
    if ($keepMap.Contains($snapshot.FullName)) {
      continue
    }
    $delete.Add([pscustomobject]@{ Snapshot = $snapshot; Decision = 'delete_candidate'; Reason = 'retention' }) | Out-Null
  }

  $freed = [int64]0
  foreach ($entry in $delete) {
    $freed += [int64]$entry.Snapshot.SizeBytes
  }

  return [pscustomobject]@{
    Keep = $keep.ToArray()
    Delete = $delete.ToArray()
    EstimatedFreedBytes = $freed
  }
}

$repoRoot = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($BackupRoot)) {
  $BackupRoot = Join-Path $repoRoot "_dr_backups"
}
$logRoot = Get-LogContext -Root $BackupRoot
$logFile = Join-Path $logRoot ("dr_retention_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".log")

if ($KeepDailyDays -lt 0) { throw "KeepDailyDays must be >= 0" }
if ($KeepWeeklyWeeks -lt 0) { throw "KeepWeeklyWeeks must be >= 0" }

$catalog = Get-SnapshotCatalog -Root $BackupRoot
$protectedSet = Get-ProtectionSet -Snapshots $ProtectedSnapshots
$plan = Get-RetentionPlan -Snapshots $catalog -KeepDailyDays $KeepDailyDays -KeepWeeklyWeeks $KeepWeeklyWeeks -ProtectedSet $protectedSet

Write-Log -LogFile $logFile -Message ("DR_RETENTION_PREVIEW root={0} keep_daily_days={1} keep_weekly_weeks={2} snapshots={3} log={4}" -f $BackupRoot, $KeepDailyDays, $KeepWeeklyWeeks, $catalog.Count, $logFile)

foreach ($entry in $plan.Keep) {
  Write-Log -LogFile $logFile -Message ("KEEP {0} reason={1} created_at={2:o} size_bytes={3}" -f $entry.Snapshot.Name, $entry.Reason, $entry.Snapshot.CreatedAt, $entry.Snapshot.SizeBytes)
}

foreach ($entry in $plan.Delete) {
  Write-Log -LogFile $logFile -Message ("DELETE_CANDIDATE {0} reason={1} created_at={2:o} size_bytes={3}" -f $entry.Snapshot.Name, $entry.Reason, $entry.Snapshot.CreatedAt, $entry.Snapshot.SizeBytes)
}

Write-Log -LogFile $logFile -Message ("estimated_freed_bytes={0}" -f $plan.EstimatedFreedBytes)

if ($Action -eq 'Prune') {
  if (-not $ConfirmPrune) {
    Write-Log -LogFile $logFile -Message "PRUNE_DISABLED missing_confirm_prune=true"
    exit 1
  }

  foreach ($entry in $plan.Delete) {
    $target = $entry.Snapshot.FullName
    if ($PSCmdlet.ShouldProcess($target, "Remove retention candidate")) {
      Remove-Item -LiteralPath $target -Recurse -Force
      Write-Log -LogFile $logFile -Message ("REMOVED {0}" -f $entry.Snapshot.Name)
    }
  }
}

exit 0
