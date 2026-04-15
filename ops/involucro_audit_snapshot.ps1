param(
  [ValidateSet("baseline_mattino", "carico_solare", "tardo_pomeriggio", "night_flush")]
  [string]$WindowType = "night_flush",
  [string]$EnvPath = ".env",
  [string]$HaHost = "root@192.168.178.84",
  [int]$Port = 2222,
  [string]$KeyPath = "C:\Users\randalab\.ssh\ha_ed25519"
)

$ErrorActionPreference = "Stop"

function Read-DotEnv {
  param([string]$Path)

  if (-not (Test-Path -LiteralPath $Path)) {
    throw "Missing env file: $Path"
  }

  $map = @{}
  foreach ($line in Get-Content -LiteralPath $Path) {
    if ([string]::IsNullOrWhiteSpace($line)) {
      continue
    }
    if ($line.TrimStart().StartsWith("#")) {
      continue
    }
    $parts = $line -split "=", 2
    if ($parts.Count -eq 2) {
      $map[$parts[0].Trim()] = $parts[1].Trim()
    }
  }
  return $map
}

function Get-HaState {
  param(
    [string]$SshExe,
    [string]$HaHost,
    [int]$Port,
    [string]$KeyPath,
    [string]$Token,
    [string]$EntityId
  )

  try {
    $remoteCmd = "curl -s -H 'Authorization: Bearer $Token' http://172.30.32.1:8123/api/states/$EntityId"
    $raw = & $SshExe -T -p $Port -i $KeyPath $HaHost $remoteCmd
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($raw)) {
      throw "SSH/Core API call failed for $EntityId"
    }
    return ($raw | ConvertFrom-Json)
  } catch {
    return [pscustomobject]@{
      entity_id = $EntityId
      state = "error"
      attributes = @{
        error = $_.Exception.Message
      }
    }
  }
}

function Get-StateValue {
  param($StateObject)

  if ($null -eq $StateObject) {
    return "missing"
  }
  if ($null -eq $StateObject.state -or [string]::IsNullOrWhiteSpace([string]$StateObject.state)) {
    return "missing"
  }
  return [string]$StateObject.state
}

function New-Line {
  param(
    [string]$Label,
    [string]$Value
  )
  return "- ``$Label``: $Value"
}

$repoRoot = Split-Path -Parent $PSScriptRoot
$sshExe = "C:\Windows\System32\OpenSSH\ssh.exe"
$resolvedEnvPath = if ([System.IO.Path]::IsPathRooted($EnvPath)) {
  $EnvPath
} else {
  Join-Path $repoRoot $EnvPath
}

$envMap = Read-DotEnv -Path $resolvedEnvPath
$haToken = $envMap["HA_TOKEN"]

if ([string]::IsNullOrWhiteSpace($haToken)) {
  throw "HA_TOKEN missing in $resolvedEnvPath"
}

$date = Get-Date -Format "yyyy-MM-dd"
$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$timeNow = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$dateDir = Join-Path $repoRoot ("docs\runtime_evidence\" + $date)
New-Item -ItemType Directory -Force -Path $dateDir | Out-Null

$outputMd = Join-Path $dateDir ("involucro_audit_snapshot_" + $WindowType + "_" + $stamp + ".md")
$outputJson = Join-Path $dateDir ("involucro_audit_snapshot_" + $WindowType + "_" + $stamp + ".json")

$globalEntities = @(
  "sensor.t_in_med",
  "sensor.t_out_effective",
  "sensor.pv_power_now",
  "binary_sensor.casa_chiusa",
  "switch.heating_master",
  "switch.ac_giorno",
  "switch.ac_notte"
)

$summaryEntities = @(
  "sensor.envelope_worst_room_name",
  "sensor.envelope_worst_room_overheating_risk",
  "sensor.envelope_house_passive_gain_state",
  "sensor.envelope_house_night_flush_potential",
  "sensor.envelope_outdoor_cooling_window_state",
  "sensor.envelope_time_to_cool_window",
  "sensor.envelope_thermal_rebound_risk",
  "sensor.envelope_recommended_action"
)

$roomEntities = @(
  "sensor.t_in_giorno",
  "sensor.envelope_giorno_rise_rate_cph",
  "sensor.envelope_giorno_overheating_risk",
  "sensor.t_in_notte1",
  "sensor.envelope_notte1_rise_rate_cph",
  "sensor.envelope_notte1_overheating_risk",
  "sensor.t_in_notte2",
  "sensor.envelope_notte2_rise_rate_cph",
  "sensor.envelope_notte2_overheating_risk",
  "sensor.t_in_bagno",
  "sensor.envelope_bagno_rise_rate_cph",
  "sensor.envelope_bagno_overheating_risk"
)

$trendEntities = @(
  "sensor.envelope_t_out_rise_rate_cph",
  "sensor.envelope_t_out_drop_rate_cph",
  "sensor.envelope_delta_t_in_out_trend"
)

$entityIds = @($globalEntities + $summaryEntities + $roomEntities + $trendEntities)
$states = [ordered]@{}
foreach ($entityId in $entityIds) {
  $states[$entityId] = Get-HaState -SshExe $sshExe -HaHost $HaHost -Port $Port -KeyPath $KeyPath -Token $haToken -EntityId $entityId
}

$jsonPayload = [pscustomobject]@{
  captured_at = $timeNow
  window_type = $WindowType
  defaults = @{
    scuri = "aperti"
    note = "Assumere scuri aperti salvo evidenza contraria o test mirato."
  }
  states = $states
}
$jsonPayload | ConvertTo-Json -Depth 8 | Set-Content -Path $outputJson -Encoding utf8

$md = @()
$md += "# Involucro Audit Snapshot ($date)"
$md += ""
$md += "- timestamp: $timeNow"
$md += "- window_type: $WindowType"
$md += '- default operativo scuri: `aperti`'
$md += ""
$md += "## Stato casa"
$md += New-Line "binary_sensor.casa_chiusa" (Get-StateValue $states["binary_sensor.casa_chiusa"])
$md += New-Line "switch.heating_master" (Get-StateValue $states["switch.heating_master"])
$md += New-Line "switch.ac_giorno" (Get-StateValue $states["switch.ac_giorno"])
$md += New-Line "switch.ac_notte" (Get-StateValue $states["switch.ac_notte"])
$md += ""
$md += "## Globali"
$md += New-Line "sensor.t_in_med" (Get-StateValue $states["sensor.t_in_med"])
$md += New-Line "sensor.t_out_effective" (Get-StateValue $states["sensor.t_out_effective"])
$md += New-Line "sensor.pv_power_now" (Get-StateValue $states["sensor.pv_power_now"])
$md += ""
$md += "## Sintesi involucro"
$md += New-Line "sensor.envelope_worst_room_name" (Get-StateValue $states["sensor.envelope_worst_room_name"])
$md += New-Line "sensor.envelope_worst_room_overheating_risk" (Get-StateValue $states["sensor.envelope_worst_room_overheating_risk"])
$md += New-Line "sensor.envelope_house_passive_gain_state" (Get-StateValue $states["sensor.envelope_house_passive_gain_state"])
$md += New-Line "sensor.envelope_house_night_flush_potential" (Get-StateValue $states["sensor.envelope_house_night_flush_potential"])
$md += New-Line "sensor.envelope_outdoor_cooling_window_state" (Get-StateValue $states["sensor.envelope_outdoor_cooling_window_state"])
$md += New-Line "sensor.envelope_time_to_cool_window" (Get-StateValue $states["sensor.envelope_time_to_cool_window"])
$md += New-Line "sensor.envelope_thermal_rebound_risk" (Get-StateValue $states["sensor.envelope_thermal_rebound_risk"])
$md += New-Line "sensor.envelope_recommended_action" (Get-StateValue $states["sensor.envelope_recommended_action"])

$source = $states["sensor.t_out_effective"]
if ($null -ne $source.attributes) {
  $sourceValue = if ($source.attributes.PSObject.Properties.Name -contains "source") { [string]$source.attributes.source } else { "n/a" }
  $staleFlag = if ($source.attributes.PSObject.Properties.Name -contains "stale_flag") { [string]$source.attributes.stale_flag } else { "n/a" }
  $md += New-Line "sensor.t_out_effective.source" $sourceValue
  $md += New-Line "sensor.t_out_effective.stale_flag" $staleFlag
}

$md += ""
$md += "## Trend esterni"
$md += New-Line "sensor.envelope_t_out_rise_rate_cph" (Get-StateValue $states["sensor.envelope_t_out_rise_rate_cph"])
$md += New-Line "sensor.envelope_t_out_drop_rate_cph" (Get-StateValue $states["sensor.envelope_t_out_drop_rate_cph"])
$md += New-Line "sensor.envelope_delta_t_in_out_trend" (Get-StateValue $states["sensor.envelope_delta_t_in_out_trend"])
$md += ""
$md += "## Stanze"
$md += "- giorno: t_in=$(Get-StateValue $states["sensor.t_in_giorno"]); rise_rate_cph=$(Get-StateValue $states["sensor.envelope_giorno_rise_rate_cph"]); overheating_risk=$(Get-StateValue $states["sensor.envelope_giorno_overheating_risk"])"
$md += "- notte1: t_in=$(Get-StateValue $states["sensor.t_in_notte1"]); rise_rate_cph=$(Get-StateValue $states["sensor.envelope_notte1_rise_rate_cph"]); overheating_risk=$(Get-StateValue $states["sensor.envelope_notte1_overheating_risk"])"
$md += "- notte2: t_in=$(Get-StateValue $states["sensor.t_in_notte2"]); rise_rate_cph=$(Get-StateValue $states["sensor.envelope_notte2_rise_rate_cph"]); overheating_risk=$(Get-StateValue $states["sensor.envelope_notte2_overheating_risk"])"
$md += "- bagno: t_in=$(Get-StateValue $states["sensor.t_in_bagno"]); rise_rate_cph=$(Get-StateValue $states["sensor.envelope_bagno_rise_rate_cph"]); overheating_risk=$(Get-StateValue $states["sensor.envelope_bagno_overheating_risk"])"
$md += ""
$md += "## Note operative"
$md += "- default scuri: aperti"
$md += "- annotare manualmente gli scuri solo se li hai chiusi davvero o se stai facendo un test mirato"
$md += ('- file raw JSON: `' + [System.IO.Path]::GetFileName($outputJson) + '`')

$md -join "`r`n" | Set-Content -Path $outputMd -Encoding utf8

Write-Host "Snapshot markdown: $outputMd"
Write-Host "Snapshot json    : $outputJson"
