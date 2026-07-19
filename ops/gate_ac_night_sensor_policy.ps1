$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$policyFile = Join-Path $repoRoot 'packages/climate_ac_comfort_control.yaml'

if (-not (Test-Path -LiteralPath $policyFile)) {
  Write-Error "AC night sensor policy gate failed: missing $policyFile"
  exit 1
}

$content = Get-Content -LiteralPath $policyFile -Raw
$checks = @(
  @{ Name = 'temperature'; Start = 'AC Notte Temperatura Camere'; Stop = 'AC Notte Umidita Camere'; Forbidden = 'sensor.t_in_bagno' },
  @{ Name = 'humidity'; Start = 'AC Notte Umidita Camere'; Stop = 'AC Notte Dew Point'; Forbidden = 'sensor.ur_in_bagno' }
)

foreach ($check in $checks) {
  $pattern = '(?s)' + [regex]::Escape($check.Start) + '(.*?)' + [regex]::Escape($check.Stop)
  $match = [regex]::Match($content, $pattern)
  if (-not $match.Success) {
    Write-Error "AC night sensor policy gate failed: unable to locate $($check.Name) control block."
    exit 1
  }
  if ($match.Groups[1].Value.Contains($check.Forbidden)) {
    Write-Error "AC night sensor policy gate failed: $($check.Forbidden) must remain excluded from AC notte control."
    exit 1
  }
}

Write-Host 'AC night sensor policy gate passed: bathroom temperature and humidity are excluded.'

