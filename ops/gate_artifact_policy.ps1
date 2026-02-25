$ErrorActionPreference = 'Stop'

function Get-RepoRoot {
  $root = (& git rev-parse --show-toplevel 2>$null)
  if (-not $root) {
    Write-Error 'Unable to resolve git repo root.'
    exit 1
  }
  return $root.Trim()
}

function Get-TrackedFilesByGlob {
  param(
    [Parameter(Mandatory = $true)][string]$Root,
    [Parameter(Mandatory = $true)][string]$Glob
  )
  $output = & git -C $Root ls-files -- $Glob 2>$null
  if ($LASTEXITCODE -ne 0) {
    Write-Error ("Unable to enumerate tracked files for pattern: {0}" -f $Glob)
    exit 1
  }
  if (-not $output) {
    return @()
  }
  return @($output)
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

# Any tracked __pycache__ path is disallowed.
$trackedPyCache = Get-TrackedFilesByGlob -Root $repoRoot -Glob '*__pycache__*'

# Source maps are allowed only for vendored HACS frontend assets.
$trackedMap = Get-TrackedFilesByGlob -Root $repoRoot -Glob '*.map'
$mapAllowRegex = @(
  '^custom_components/hacs/hacs_frontend/.+\.map$'
)
$disallowedMap = Get-DisallowedByRegexAllowlist -Files $trackedMap -AllowRegex $mapAllowRegex

# Gzip assets are allowed for vendored HACS frontend and selected Lovelace community cards.
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
