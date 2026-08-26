param(
  [string]$OutputPath = 'docs/architecture/AEB_DASHBOARD_NAVIGATION.generated.md'
)

$ErrorActionPreference = 'Stop'

function Get-RepoRoot {
  $root = $null
  try {
    $root = (& git rev-parse --show-toplevel 2>$null)
  } catch {
    $root = $null
  }
  if ($root) { return $root.Trim() }

  $fallback = Split-Path -Parent $PSScriptRoot
  if ((Test-Path -LiteralPath (Join-Path $fallback 'configuration.yaml')) -and
      (Test-Path -LiteralPath (Join-Path $fallback 'lovelace'))) {
    return $fallback
  }
  throw 'Unable to resolve repo root.'
}

function Get-DashboardRegistry {
  param([string]$ConfigPath)

  $registry = [ordered]@{}
  $inDashboards = $false
  $currentId = $null

  foreach ($line in Get-Content -LiteralPath $ConfigPath) {
    if ($line -match '^\s{2}dashboards:\s*$') {
      $inDashboards = $true
      $currentId = $null
      continue
    }
    if ($inDashboards -and $line -match '^\S') { break }
    if (-not $inDashboards) { continue }

    if ($line -match '^\s{4}([A-Za-z0-9_-]+):\s*$') {
      $currentId = $matches[1]
      if (-not $registry.Contains($currentId)) {
        $registry[$currentId] = [ordered]@{ File = $null; Title = $currentId; Views = @() }
      }
      continue
    }
    if ($currentId -and $line -match '^\s{6}filename:\s*lovelace/([^\s#]+)\s*$') {
      $registry[$currentId].File = $matches[1]
      continue
    }
    if ($currentId -and $line -match '^\s{6}title:\s*["'']?(.+?)["'']?\s*$') {
      $registry[$currentId].Title = $matches[1]
    }
  }

  return $registry
}

function Get-ViewPaths {
  param([string]$Path)

  $views = New-Object System.Collections.Generic.List[string]
  foreach ($line in Get-Content -LiteralPath $Path) {
    if ($line -match '^\s{4}path:\s*["'']?([^"''\s#]+)["'']?\s*$') {
      if (-not $views.Contains($matches[1])) { $views.Add($matches[1]) }
    }
  }
  return ,$views
}

function Get-NavigationLinks {
  param(
    [string]$Path,
    [string]$SourceDashboard
  )

  $links = New-Object System.Collections.Generic.List[object]
  $currentView = '(unknown)'

  foreach ($line in Get-Content -LiteralPath $Path) {
    if ($line -match '^\s{4}path:\s*["'']?([^"''\s#]+)["'']?\s*$') {
      $currentView = $matches[1]
      continue
    }
    if ($line -match 'navigation_path:\s*["'']?([^"''\s#]+)["'']?') {
      $target = $matches[1]
      if ($target -notmatch '^/') { continue }
      $parts = @($target.Trim('/') -split '/')
      if ($parts.Count -lt 1 -or -not $parts[0]) { continue }

      $links.Add([pscustomobject]@{
        SourceDashboard = $SourceDashboard
        SourceView = $currentView
        NavigationPath = $target
        TargetDashboard = $parts[0]
        TargetView = if ($parts.Count -ge 2) { $parts[1] } else { '' }
      })
    }
  }

  return ,$links
}

function Escape-Mermaid([string]$Value) {
  return ($Value -replace '"', "'")
}

$repoRoot = Get-RepoRoot
$configPath = Join-Path $repoRoot 'configuration.yaml'
$registry = Get-DashboardRegistry -ConfigPath $configPath

$links = New-Object System.Collections.Generic.List[object]
foreach ($id in $registry.Keys) {
  $file = $registry[$id].File
  if (-not $file) { continue }
  $path = Join-Path $repoRoot ('lovelace/' + $file)
  if (-not (Test-Path -LiteralPath $path)) { continue }
  $registry[$id].Views = @(Get-ViewPaths -Path $path)
  foreach ($link in (Get-NavigationLinks -Path $path -SourceDashboard $id)) {
    $links.Add($link)
  }
}

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add('# AEB Dashboard Navigation - generated')
$lines.Add('')
$lines.Add('> GENERATED ARTIFACT. Do not edit by hand. Source of truth: `configuration.yaml` and `lovelace/*.yaml`.')
$lines.Add('')
$lines.Add('Generate with: `pwsh -File ./ops/generate_dashboard_navigation.ps1`')
$lines.Add('')
$lines.Add('## Dashboard graph')
$lines.Add('')
$lines.Add('```mermaid')
$lines.Add('flowchart TD')
foreach ($id in $registry.Keys) {
  $title = Escape-Mermaid $registry[$id].Title
  $nodeId = 'D_' + ($id -replace '[^A-Za-z0-9_]', '_')
  $lines.Add(('  {0}["{1}<br/>{2}"]' -f $nodeId, $title, $id))
}
foreach ($link in $links) {
  if (-not $registry.Contains($link.TargetDashboard)) { continue }
  $src = 'D_' + ($link.SourceDashboard -replace '[^A-Za-z0-9_]', '_')
  $dst = 'D_' + ($link.TargetDashboard -replace '[^A-Za-z0-9_]', '_')
  $label = Escape-Mermaid (($link.SourceView + ' -> ' + $link.TargetView).TrimEnd(' ', '-', '>'))
  $lines.Add(('  {0} -->|"{1}"| {2}' -f $src, $label, $dst))
}
$lines.Add('```')
$lines.Add('')
$lines.Add('## Registered dashboards')
$lines.Add('')
$lines.Add('| ID | Title | File | Views |')
$lines.Add('|---|---|---|---|')
foreach ($id in $registry.Keys) {
  $views = ($registry[$id].Views -join ', ')
  $lines.Add(('| `{0}` | {1} | `{2}` | `{3}` |' -f $id, $registry[$id].Title, $registry[$id].File, $views))
}
$lines.Add('')
$lines.Add('## Navigation paths')
$lines.Add('')
$lines.Add('| Source dashboard | Source view | navigation_path | Target dashboard | Target view |')
$lines.Add('|---|---|---|---|---|')
foreach ($link in $links) {
  $lines.Add(('| `{0}` | `{1}` | `{2}` | `{3}` | `{4}` |' -f $link.SourceDashboard, $link.SourceView, $link.NavigationPath, $link.TargetDashboard, $link.TargetView))
}

$outPath = if ([System.IO.Path]::IsPathRooted($OutputPath)) { $OutputPath } else { Join-Path $repoRoot $OutputPath }
$outDir = Split-Path -Parent $outPath
if (-not (Test-Path -LiteralPath $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }
$lines | Set-Content -LiteralPath $outPath -Encoding utf8
Write-Host ("[OK] Dashboard navigation generated: {0} dashboards, {1} navigation paths -> {2}" -f $registry.Count, $links.Count, $outPath)
