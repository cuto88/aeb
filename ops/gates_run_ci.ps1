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
    Write-Host "Git repo root unavailable; using script-relative root: $fallback"
    return $fallback
  }
  Write-Error 'Unable to resolve repo root.'
  exit 1
}

function Get-TrackedYamlFiles {
  param([string]$Root)
  $tracked = @()
  $output = $null
  $gitOk = $false
  try {
    $output = & git -C $Root ls-files -z -- '*.yaml' '*.yml' 2>$null
    $gitOk = ($LASTEXITCODE -eq 0)
  } catch {
    $gitOk = $false
  }
  if ($gitOk -and $output) {
    $tracked = $output -split "`0" | Where-Object { $_ -ne '' }
  } elseif (Get-Command rg -ErrorAction SilentlyContinue) {
    Write-Host 'Git tracked file list unavailable; using scoped rg YAML list.'
    $tracked = & rg --files $Root -g '*.yaml' -g '*.yml' |
      ForEach-Object { [System.IO.Path]::GetRelativePath($Root, $_) }
  } else {
    Write-Error 'Unable to enumerate YAML files without Git or rg.'
    exit 1
  }
  return @(
    $tracked |
      Where-Object {
        $_ -notmatch '(^|[\/])(_archive|_backup|docs[\/]logic[\/]_backup|ops[\/]disabled_runtime)([\/]|$)'
      } |
      Where-Object {
        $_ -match '^(packages|lovelace|ops)([\/]|$)' -or $_ -match '^(configuration|automations|scripts|scenes|groups|customize)\.ya?ml$'
      }
  )
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
Invoke-GateScript -Path 'ops/gate_lovelace_dashboards.ps1'
Invoke-GateScript -Path 'ops/gate_entity_naming.ps1'
Invoke-GateScript -Path 'ops/gates/check_cm_naming.ps1'
Invoke-GateScript -Path 'ops/gates/check_no_nested_template.ps1'
Invoke-GateScript -Path 'ops/gate_docs_links.ps1'
Invoke-GateScript -Path 'ops/gate_artifact_policy.ps1'

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
  if ($code -ne 0) {
    exit $code
  }
}

Write-Host 'ALL GATES PASSED'
exit 0
