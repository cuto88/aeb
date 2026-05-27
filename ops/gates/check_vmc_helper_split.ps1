param(
  [string]$RepoRoot = (Resolve-Path '.')
)

$ErrorActionPreference = 'Stop'

Write-Host 'Gate: check_vmc_helper_split'

$monolithic = Join-Path $RepoRoot 'packages/climate_ventilation.yaml'
$helpers = Join-Path $RepoRoot 'packages/climate_ventilation_helpers.yaml'

if (-not (Test-Path -LiteralPath $monolithic)) {
  Write-Host 'OK: climate_ventilation.yaml not found, skipping.'
  exit 0
}

if (-not (Test-Path -LiteralPath $helpers)) {
  Write-Host 'OK: climate_ventilation_helpers.yaml not found, skipping.'
  exit 0
}

$helperDomains = @(
  'input_select',
  'input_boolean',
  'input_number',
  'input_text',
  'input_datetime',
  'timer',
  'counter'
)

$domainPattern = '^(' + ($helperDomains -join '|') + '):\s*$'
$monolithicLines = Get-Content -LiteralPath $monolithic
$violations = @()

for ($i = 0; $i -lt $monolithicLines.Count; $i++) {
  $line = $monolithicLines[$i]
  if ($line -match $domainPattern) {
    $violations += [PSCustomObject]@{
      File = $monolithic
      Line = $i + 1
      Domain = $Matches[1]
    }
  }
}

if ($violations.Count -gt 0) {
  Write-Host 'FAIL: Helper domains must live only in climate_ventilation_helpers.yaml.' -ForegroundColor Red
  $violations | ForEach-Object {
    Write-Host ("- {0}:{1} top-level {2}: found in climate_ventilation.yaml" -f $_.File, $_.Line, $_.Domain) -ForegroundColor Red
  }
  exit 1
}

Write-Host 'OK: climate_ventilation.yaml does not duplicate helper domains.'
exit 0
