$ErrorActionPreference = 'Stop'

function Get-RepoRoot {
  $root = $null
  try {
    $root = (& git rev-parse --show-toplevel 2>$null)
  } catch {
    $root = $null
  }
  if ($root) {
    return $root.Trim()
  }
  $fallback = Split-Path -Parent $PSScriptRoot
  if ((Test-Path -LiteralPath (Join-Path $fallback 'packages')) -and (Test-Path -LiteralPath (Join-Path $fallback 'ops'))) {
    return $fallback
  }
  Write-Error 'Unable to resolve repo root.'
  exit 1
}

function Get-TrackedFilesByGlob {
  param(
    [Parameter(Mandatory = $true)][string]$Root,
    [Parameter(Mandatory = $true)][string]$Glob
  )
  $output = $null
  $gitOk = $false
  try {
    $output = & git -C $Root ls-files -- $Glob 2>$null
    $gitOk = ($LASTEXITCODE -eq 0)
  } catch {
    $gitOk = $false
  }
  if ($gitOk) {
    if (-not $output) {
      return @()
    }
    return @($output)
  }
  $pattern = $Glob -replace '^\*', '*'
  $rootPrefix = $Root.TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar
  return @(
    Get-ChildItem -Path $Root -Recurse -File -Filter $pattern -ErrorAction SilentlyContinue |
      ForEach-Object { $_.FullName.Substring($rootPrefix.Length) -replace '\\', '/' } |
      Where-Object { $_ -notmatch '(^|/)(\.git-local|tools|docs/runtime_evidence)(/|$)' }
  )
}

function Get-DisallowedByRegexAllowlist {
  param(
    [Parameter(Mandatory = $true)][string[]]$Files,
    [Parameter(Mandatory = $true)][string[]]$AllowRegex
  )
  $disallowed = @()
  foreach ($file in $Files) {
    $isAllowed = $false
    foreach ($pattern in $AllowRegex) {
      if ($file -match $pattern) {
        $isAllowed = $true
        break
      }
    }
    if (-not $isAllowed) {
      $disallowed += $file
    }
  }
  return $disallowed
}

$repoRoot = Get-RepoRoot

$trackedPyCache = Get-TrackedFilesByGlob -Root $repoRoot -Glob '*__pycache__*'

$trackedMap = Get-TrackedFilesByGlob -Root $repoRoot -Glob '*.map'
$mapAllowRegex = @(
  '^custom_components/hacs/hacs_frontend/.+\.map$'
)
$disallowedMap = Get-DisallowedByRegexAllowlist -Files $trackedMap -AllowRegex $mapAllowRegex

$trackedGz = Get-TrackedFilesByGlob -Root $repoRoot -Glob '*.gz'
$gzAllowRegex = @(
  '^custom_components/hacs/hacs_frontend/.+\.gz$',
  '^www/community/.+\.gz$'
)
$disallowedGz = Get-DisallowedByRegexAllowlist -Files $trackedGz -AllowRegex $gzAllowRegex

$fail = $false

if ($trackedPyCache.Count -gt 0) {
  $fail = $true
  Write-Host 'ARTIFACT_POLICY: tracked __pycache__ entries are not allowed:'
  $trackedPyCache | ForEach-Object { Write-Host ("- {0}" -f $_) }
}

if ($disallowedMap.Count -gt 0) {
  $fail = $true
  Write-Host 'ARTIFACT_POLICY: disallowed .map files detected:'
  $disallowedMap | ForEach-Object { Write-Host ("- {0}" -f $_) }
}

if ($disallowedGz.Count -gt 0) {
  $fail = $true
  Write-Host 'ARTIFACT_POLICY: disallowed .gz files detected:'
  $disallowedGz | ForEach-Object { Write-Host ("- {0}" -f $_) }
}

if ($fail) {
  exit 1
}

Write-Host ("ARTIFACT_POLICY: OK (__pycache__={0}, map={1}, gz={2})" -f $trackedPyCache.Count, $trackedMap.Count, $trackedGz.Count)
exit 0
