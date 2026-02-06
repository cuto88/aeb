$ErrorActionPreference = 'Stop'

function Get-RepoRoot {
  $root = (& git rev-parse --show-toplevel 2>$null)
  if (-not $root) {
    Write-Error 'Unable to resolve git repo root.'
    exit 1
  }
  return $root.Trim()
}

function Get-TrackedYamlFiles {
  param([string]$Root)
  $tracked = @()
  $output = & git -C $Root ls-files -z -- '*.yaml' '*.yml' 2>$null
  if ($LASTEXITCODE -ne 0) {
    Write-Error 'Unable to enumerate tracked YAML files.'
    exit 1
  }
  if ($output) {
    $tracked = $output -split "`0" | Where-Object { $_ -ne '' }
  }
  return $tracked
}

function Invoke-GateScript {
  param(
    [Parameter(Mandatory = $true)][string]$Path,
    [string[]]$Args = @()
  )

  & pwsh -NoProfile -ExecutionPolicy Bypass -File $Path @Args
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

$repoRoot = Get-RepoRoot
Set-Location $repoRoot

Invoke-GateScript -Path 'ops/gate_include_tree.ps1'
Invoke-GateScript -Path 'ops/gate_ha_structure.ps1' -Args @('-CheckEntityMap')
Invoke-GateScript -Path 'ops/gate_vmc_dashboards.ps1'
Invoke-GateScript -Path 'ops/gate_entity_naming.ps1'
Invoke-GateScript -Path 'ops/gate_docs_links.ps1'

if (-not (Get-Command yamllint -ErrorAction SilentlyContinue)) {
  Write-Error 'yamllint not found.'
  exit 1
}

$trackedYamlFiles = Get-TrackedYamlFiles -Root $repoRoot
if ($trackedYamlFiles.Count -eq 0) {
  Write-Host 'No tracked YAML files found. Skipping yamllint.'
} else {
  & yamllint @($trackedYamlFiles)
  $code = $LASTEXITCODE
  if ($code -eq 1) {
    Write-Host 'yamllint returned warnings only; continuing.'
    $code = 0
  }
  if ($code -ne 0) {
    exit $code
  }
}

Write-Host 'ALL GATES PASSED'
exit 0
