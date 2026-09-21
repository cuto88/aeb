$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$comfortFile = Join-Path $repoRoot 'packages/climate_ac_comfort_control.yaml'
$mappingFile = Join-Path $repoRoot 'packages/climate_ac_mapping.yaml'
$actuatorFile = Join-Path $repoRoot 'packages/climateops/actuators/system_actuator.yaml'

foreach ($path in @($comfortFile, $mappingFile, $actuatorFile)) {
  if (-not (Test-Path -LiteralPath $path)) {
    Write-Error "AC DRY mode policy gate failed: missing $path"
    exit 1
  }
}

$comfort = Get-Content -LiteralPath $comfortFile -Raw
$mapping = Get-Content -LiteralPath $mappingFile -Raw
$actuator = Get-Content -LiteralPath $actuatorFile -Raw

$requiredComfortTokens = @(
  'ac_giorno_requested_hvac_mode',
  'ac_notte_requested_hvac_mode',
  'ac_auto_dry_enabled',
  "{% elif temp_start %}cool",
  "{% elif dry_enabled and dry_start %}dry",
  "this.state in ['cool','dry']",
  "'dry' in (state_attr('climate.ac_giorno','hvac_modes')",
  "'dry' in (state_attr('climate.ac_notte','hvac_modes')"
)

foreach ($token in $requiredComfortTokens) {
  if (-not $comfort.Contains($token)) {
    Write-Error "AC DRY mode policy gate failed: comfort policy is missing token: $token"
    exit 1
  }
}

if (($mapping | Select-String -Pattern 'service: climate.set_hvac_mode' -AllMatches).Matches.Count -ne 2) {
  Write-Error 'AC DRY mode policy gate failed: both zone apply scripts must set HVAC mode.'
  exit 1
}

foreach ($token in @(
  "requested_mode if requested_mode in supported_modes else 'cool'",
  "effective_mode == 'cool'"
)) {
  if (-not $mapping.Contains($token)) {
    Write-Error "AC DRY mode policy gate failed: actuator mapping is missing token: $token"
    exit 1
  }
}

foreach ($token in @(
  'sensor.ac_giorno_requested_hvac_mode',
  'sensor.ac_notte_requested_hvac_mode',
  "states('climate.ac_giorno') != ac_day_effective_hvac_mode",
  "states('climate.ac_notte') != ac_night_effective_hvac_mode"
)) {
  if (-not $actuator.Contains($token)) {
    Write-Error "AC DRY mode policy gate failed: system actuator is missing token: $token"
    exit 1
  }
}

Write-Host 'AC DRY mode policy gate passed: humidity-only demand selects DRY with COOL priority and fallback.'
