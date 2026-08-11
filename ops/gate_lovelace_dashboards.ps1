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

function Get-ViewPaths([string]$path) {
  $views = New-Object System.Collections.Generic.HashSet[string]
  foreach ($line in Get-Content -LiteralPath $path) {
    if ($line -match '^\s{4}path:\s*["'']?([^"''\s#]+)["'']?\s*$') {
      [void]$views.Add($matches[1])
    }
  }
  return $views
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
$dashboardFiles = @{}
$inDashboards = $false
$currentDashboardId = $null

foreach ($line in $configLines) {
  if ($line -match "^\s*filename:\s*lovelace/(_archive|_baseline)(/|\\)") {
    Fail "Archived or baseline Lovelace files must not be registered as operational dashboards: $($line.Trim())"
  }

  if ($line -match '^\s{2}dashboards:\s*$') {
    $inDashboards = $true
    $currentDashboardId = $null
    continue
  }
  if ($inDashboards -and $line -match '^\S') {
    $inDashboards = $false
    $currentDashboardId = $null
  }
  if ($inDashboards -and $line -match '^\s{4}([A-Za-z0-9_-]+):\s*$') {
    $currentDashboardId = $matches[1]
    continue
  }
  if ($inDashboards -and $currentDashboardId -and $line -match '^\s{6}filename:\s*lovelace/([A-Za-z0-9_.-]+\.(yaml|yml))\s*$') {
    $name = $matches[1]
    [void]$active.Add($name)
    $dashboardFiles[$currentDashboardId] = $name
  }
}

if ($active.Count -eq 0) {
  Fail "No Lovelace dashboard files detected in configuration.yaml."
}
if ($dashboardFiles.Count -eq 0) {
  Fail "No Lovelace dashboard IDs detected in configuration.yaml."
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

# Navigation validation. YAML remains the SSOT: dashboard IDs come from
# configuration.yaml and target view paths come from the registered Lovelace files.
$viewsByDashboard = @{}
foreach ($dashboardId in $dashboardFiles.Keys) {
  $path = Join-Path $repoRoot ("lovelace/" + $dashboardFiles[$dashboardId])
  $viewsByDashboard[$dashboardId] = Get-ViewPaths -path $path
}

$builtInPrefixes = @(
  'calendar', 'config', 'developer-tools', 'energy', 'history', 'logbook',
  'map', 'media-browser', 'profile', 'todo', 'hacs'
)
$navigationErrors = @()
$outbound = @{}
$inbound = @{}
$navigationCount = 0

foreach ($sourceDashboard in $dashboardFiles.Keys) {
  $path = Join-Path $repoRoot ("lovelace/" + $dashboardFiles[$sourceDashboard])
  foreach ($line in Get-Content -LiteralPath $path) {
    if ($line -notmatch 'navigation_path:\s*["'']?([^"''\s#]+)["'']?') { continue }
    $target = $matches[1]
    if ($target -notmatch '^/') { continue }

    $parts = @($target.Trim('/') -split '/')
    if ($parts.Count -lt 1 -or -not $parts[0]) { continue }
    $targetDashboard = $parts[0]
    $targetView = if ($parts.Count -ge 2) { $parts[1] } else { '' }
    $navigationCount++

    if ($targetDashboard -in $builtInPrefixes) { continue }

    if (-not $dashboardFiles.ContainsKey($targetDashboard)) {
      # Fail for dashboard-shaped local routes; warn for other HA/custom routes.
      if ($targetDashboard -match '^\d{2}-') {
        $navigationErrors += ("{0} -> {1}: target dashboard is not registered" -f $sourceDashboard, $target)
      } else {
        Warn ("Unclassified navigation target from {0}: {1}" -f $sourceDashboard, $target)
      }
      continue
    }

    $outbound[$sourceDashboard] = $true
    $inbound[$targetDashboard] = $true

    if ($targetView -and -not $viewsByDashboard[$targetDashboard].Contains($targetView)) {
      $navigationErrors += ("{0} -> {1}: view '{2}' does not exist in dashboard '{3}'" -f $sourceDashboard, $target, $targetView, $targetDashboard)
    }
  }
}

if ($navigationErrors.Count -gt 0) {
  $navigationErrors | ForEach-Object { Write-Host ("[NAV-FAIL] {0}" -f $_) }
  Fail "Dashboard navigation contains broken local routes."
}

foreach ($dashboardId in $dashboardFiles.Keys | Sort-Object) {
  if (-not $inbound.ContainsKey($dashboardId) -and -not $outbound.ContainsKey($dashboardId)) {
    Warn ("Isolated dashboard (no detected dashboard-to-dashboard navigation): {0}" -f $dashboardId)
  }
}

Write-Host ("[OK] Lovelace dashboards gate passed. Active={0}, TopLevel={1}, NavigationPaths={2}" -f $active.Count, $topLevel.Count, $navigationCount)
exit 0
