$ErrorActionPreference = "Stop"

function Fail([string]$msg) {
  Write-Host "[FAIL] $msg"
  exit 1
}

function Warn([string]$msg) {
  Write-Host "[WARN] $msg"
}

$repoRoot = (& git rev-parse --show-toplevel).Trim()
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

$trackedRaw = (& git -C $repoRoot ls-files -- "lovelace/*.yaml" "lovelace/*.yml")
$tracked = @()
if ($trackedRaw) {
  $tracked = $trackedRaw |
    Where-Object { Test-Path (Join-Path $repoRoot $_) } |
    ForEach-Object { [System.IO.Path]::GetFileName($_) } |
    Sort-Object -Unique
}

$allowOrphans = @(
  ".gitkeep"
)
$orphans = $tracked | Where-Object { -not $active.Contains($_) -and $_ -notin $allowOrphans }
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

Write-Host ("[OK] Lovelace dashboards gate passed. Active={0}, Tracked={1}" -f $active.Count, $tracked.Count)
exit 0
