$ErrorActionPreference = "Stop"

function Fail([string]$msg) {
  Write-Host "[FAIL] $msg"
  exit 1
}

function Warn([string]$msg) {
  Write-Host "[WARN] $msg"
}

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
  if ((Test-Path -LiteralPath (Join-Path $fallback "configuration.yaml")) -and
      (Test-Path -LiteralPath (Join-Path $fallback "lovelace"))) {
    return $fallback
  }
  return $null
}

$repoRoot = Get-RepoRoot
if (-not $repoRoot) {
  Fail "Unable to resolve repo root."
}

$configPath = Join-Path $repoRoot "configuration.yaml"
if (-not (Test-Path $configPath)) {
  Fail "Missing configuration.yaml."
}

$configLines = Get-Content -Path $configPath
$active = New-Object System.Collections.Generic.HashSet[string]
foreach ($line in $configLines) {
  if ($line -match "^\s*filename:\s*lovelace/(_archive|_baseline)(/|\\)") {
    Fail "Archived or baseline Lovelace files must not be registered as operational dashboards: $($line.Trim())"
  }
  if ($line -match "^\s*filename:\s*lovelace/([A-Za-z0-9_.-]+\.(yaml|yml))\s*$") {
    [void]$active.Add($matches[1])
  }
}

if ($active.Count -eq 0) {
  Fail "No Lovelace dashboard files detected in configuration.yaml."
}

$missingFiles = @()
foreach ($name in $active) {
  $path = Join-Path $repoRoot ("lovelace/" + $name)
  if (-not (Test-Path $path)) {
    $missingFiles += $name
  }
}
if ($missingFiles.Count -gt 0) {
  $missingFiles | ForEach-Object { Write-Host ("[MISSING] lovelace/{0}" -f $_) }
  Fail "Dashboard references missing files."
}

$topLevel = @(
  Get-ChildItem -Path (Join-Path $repoRoot "lovelace") -File |
    Where-Object { $_.Extension -in ".yaml", ".yml" } |
    ForEach-Object { $_.Name } |
    Sort-Object -Unique
)
if ($topLevel.Count -eq 0) {
  Fail "No top-level Lovelace YAML files found."
}

$allowOrphans = @(
  ".gitkeep"
)
$orphans = $topLevel | Where-Object { -not $active.Contains($_) -and $_ -notin $allowOrphans }
if ($orphans.Count -gt 0) {
  $orphans | ForEach-Object { Write-Host ("[ORPHAN] lovelace/{0}" -f $_) }
  Fail "Tracked Lovelace files not referenced by configuration dashboards."
}

$forbiddenHits = @()
foreach ($name in $active) {
  $path = Join-Path $repoRoot ("lovelace/" + $name)
  $todo = Select-String -Path $path -Pattern "TODO" -SimpleMatch
  if ($todo) {
    $forbiddenHits += ("TODO in lovelace/{0}" -f $name)
  }
  $collapsible = Select-String -Path $path -Pattern "collapsible:\s*true"
  if ($collapsible) {
    $forbiddenHits += ("collapsible:true in lovelace/{0}" -f $name)
  }
}

if ($forbiddenHits.Count -gt 0) {
  $forbiddenHits | ForEach-Object { Write-Host ("[FORBIDDEN] {0}" -f $_) }
  Fail "Dashboard hygiene violations detected."
}

Write-Host ("[OK] Lovelace dashboards gate passed. Active={0}, TopLevel={1}" -f $active.Count, $topLevel.Count)
exit 0
