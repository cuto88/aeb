[CmdletBinding()]
param(
  [string]$RepoRoot = (Join-Path $PSScriptRoot '..'),
  [switch]$Detailed
)

$ErrorActionPreference = 'Stop'

$resolvedRoot = (Resolve-Path -LiteralPath $RepoRoot).Path
$legacyPatterns = [ordered]@{
  'DS-01'            = '(?i)\bDS-01\b'
  'randalab'         = '(?i)\brandala[b]?\b'
  'C:\2_OPS'         = '(?i)C:\\2_OPS'
  'Z:\'               = '(?i)(?<![A-Za-z0-9_])Z:\\'
}

$excludedDirectories = @(
  '.git',
  '.git-local',
  '.tmp',
  'tmp',
  '.ops_state',
  '_dr_backups',
  '_ha_runtime_backups',
  'docs\runtime_evidence',
  'custom_components'
)

function Test-IsExcluded {
  param([string]$FullName)

  $relative = [System.IO.Path]::GetRelativePath($resolvedRoot, $FullName)
  foreach ($excluded in $excludedDirectories) {
    if (
      $relative.Equals($excluded, [System.StringComparison]::OrdinalIgnoreCase) -or
      $relative.StartsWith($excluded + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)
    ) {
      return $true
    }
  }
  return $false
}

function Get-Matches {
  param(
    [string]$Path,
    [string]$Category
  )

  $results = New-Object System.Collections.Generic.List[object]
  $lineNumber = 0
  foreach ($line in Get-Content -LiteralPath $Path -ErrorAction Stop) {
    $lineNumber++
    foreach ($entry in $legacyPatterns.GetEnumerator()) {
      if ($line -match $entry.Value) {
        $results.Add([pscustomobject]@{
          category = $Category
          pattern  = $entry.Key
          path     = [System.IO.Path]::GetRelativePath($resolvedRoot, $Path)
          line     = $lineNumber
        })
      }
    }
  }
  return $results
}

$activeExtensions = @('.ps1', '.psm1', '.py', '.cmd', '.bat')
$activeOps = Get-ChildItem -LiteralPath (Join-Path $resolvedRoot 'ops') -File -Recurse |
  Where-Object {
    $activeExtensions -contains $_.Extension.ToLowerInvariant() -and
    $_.FullName -ne $PSCommandPath -and
    $_.FullName -notmatch '[\\/]ops[\\/]_archive[\\/]' -and
    -not (Test-IsExcluded -FullName $_.FullName)
  }

$historicalRoots = @(
  (Join-Path $resolvedRoot 'docs'),
  (Join-Path $resolvedRoot 'AGENTS.md'),
  (Join-Path $resolvedRoot 'README.md')
)

$activeFindings = New-Object System.Collections.Generic.List[object]
foreach ($file in $activeOps) {
  foreach ($finding in Get-Matches -Path $file.FullName -Category 'active_ops') {
    $activeFindings.Add($finding)
  }
}

$historicalFindings = New-Object System.Collections.Generic.List[object]
foreach ($root in $historicalRoots) {
  if (-not (Test-Path -LiteralPath $root)) {
    continue
  }
  $item = Get-Item -LiteralPath $root
  $files = if ($item.PSIsContainer) {
    Get-ChildItem -LiteralPath $item.FullName -File -Recurse |
      Where-Object { -not (Test-IsExcluded -FullName $_.FullName) }
  } else {
    @($item)
  }
  foreach ($file in $files) {
    foreach ($finding in Get-Matches -Path $file.FullName -Category 'historical_docs') {
      $historicalFindings.Add($finding)
    }
  }
}

if ($Detailed) {
  foreach ($finding in $historicalFindings | Sort-Object path, line, pattern) {
    Write-Host "PORTABILITY_HISTORICAL pattern=$($finding.pattern) path=$($finding.path) line=$($finding.line)"
  }
}

foreach ($group in $activeFindings | Group-Object path | Sort-Object Name) {
  $patterns = ($group.Group.pattern | Sort-Object -Unique) -join ','
  $lines = ($group.Group.line | Sort-Object -Unique) -join ','
  Write-Host "PORTABILITY_BLOCKER path=$($group.Name) count=$($group.Count) patterns=$patterns lines=$lines"
}

if ($activeFindings.Count -gt 0) {
  Write-Host "PORTABILITY_FAIL active_ops=$($activeFindings.Count) historical_docs=$($historicalFindings.Count)"
  exit 1
}

Write-Host "PORTABILITY_OK active_ops=0 historical_docs=$($historicalFindings.Count)"
exit 0
