param(
  [string]$EnvPath = ".env",
  [string]$HaBaseUrl = "http://192.168.178.84:8123",
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
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    if ($line.TrimStart().StartsWith("#")) { continue }
    $parts = $line -split "=", 2
    if ($parts.Count -eq 2) {
      $map[$parts[0].Trim()] = $parts[1].Trim()
    }
  }
  return $map
}

function Get-HaState {
  param(
    [string]$HaBaseUrl,
    [string]$Token,
    [string]$EntityId
  )

  try {
    $uri = "$($HaBaseUrl.TrimEnd('/'))/api/states/$EntityId"
    return Invoke-RestMethod -Method Get -Uri $uri -Headers @{ Authorization = "Bearer $Token" } -TimeoutSec 15
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

  if ($null -eq $StateObject) { return "missing" }
  if ($null -eq $StateObject.state -or [string]::IsNullOrWhiteSpace([string]$StateObject.state)) { return "missing" }
  return [string]$StateObject.state
}

function New-Line {
  param(
    [string]$Label,
    [string]$Value
  )
  return "- ``$Label``: $Value"
}

function Invoke-HaSsh {
  param(
    [string]$SshExe,
    [string]$HaHost,
    [int]$Port,
    [string]$KeyPath,
    [string]$Command
  )

  try {
    $out = & $SshExe -T -p $Port -i $KeyPath $HaHost $Command 2>&1
    return [pscustomobject]@{
      ok = ($LASTEXITCODE -eq 0)
      output = (($out | Out-String).Trim())
    }
  } catch {
    return [pscustomobject]@{
      ok = $false
      output = $_.Exception.Message
    }
  }
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

if (-not $PSBoundParameters.ContainsKey("HaBaseUrl") -and -not [string]::IsNullOrWhiteSpace($envMap["HA_URL"])) {
  $HaBaseUrl = $envMap["HA_URL"]
}

$haUri = [System.Uri]$HaBaseUrl
$noProxyHosts = @("localhost", "127.0.0.1", "::1", $haUri.Host) | Select-Object -Unique
$env:NO_PROXY = ($noProxyHosts -join ",")
$env:HTTP_PROXY = ""
$env:HTTPS_PROXY = ""
$env:ALL_PROXY = ""

$date = Get-Date -Format "yyyy-MM-dd"
$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$capturedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss K"
$dateDir = Join-Path $repoRoot ("docs\runtime_evidence\" + $date)
New-Item -ItemType Directory -Force -Path $dateDir | Out-Null

$outputMd = Join-Path $dateDir ("aeb_runtime_audit_snapshot_" + $stamp + ".md")
$outputJson = Join-Path $dateDir ("aeb_runtime_audit_snapshot_" + $stamp + ".json")
$outputJsonName = Split-Path -Leaf $outputJson

$entityIds = @(
  "input_boolean.policy_vacation_mode",
  "binary_sensor.cm_policy_vacation_mode",
  "binary_sensor.policy_allow_ac",
  "binary_sensor.policy_allow_vmc_boost",
  "binary_sensor.policy_allow_shift_load",
  "binary_sensor.climateops_noncritical_loads_allowed",
  "sensor.climateops_hierarchy_reason",
  "sensor.climateops_aeb_mvp_reason",
  "sensor.climateops_aeb_mvp_mode",
  "binary_sensor.climateops_aeb_mvp_permitted",
  "input_boolean.envelope_giorno_shade_applied",
  "input_boolean.envelope_notte1_shade_applied",
  "input_boolean.envelope_notte2_shade_applied",
  "binary_sensor.envelope_any_shade_applied",
  "sensor.envelope_shade_applied_rooms",
  "sensor.envelope_recommended_action",
  "sensor.envelope_worst_room_name",
  "sensor.envelope_house_night_flush_potential",
  "sensor.envelope_house_passive_gain_state",
  "sensor.t_in_med",
  "sensor.t_in_notte2",
  "sensor.t_in_bagno",
  "sensor.t_out_effective",
  "switch.heating_master",
  "binary_sensor.vmc_is_running_proxy",
  "sensor.vmc_active_speed_proxy",
  "switch.ac_giorno",
  "switch.ac_notte",
  "climate.ac_giorno",
  "climate.ac_notte",
  "input_boolean.cm_ac_branch_powered",
  "sensor.cm_ac_branch_advice",
  "input_boolean.cm_mirai_branch_powered",
  "sensor.cm_mirai_branch_advice",
  "binary_sensor.cm_modbus_mirai_ready",
  "sensor.mirai_machine_state",
  "binary_sensor.mirai_machine_running",
  "sensor.mirai_power_w",
  "binary_sensor.cm_modbus_ehw_ready",
  "sensor.ehw_tank_top",
  "sensor.ehw_tank_bottom",
  "binary_sensor.ehw_running",
  "sensor.ehw_power_w"
)

$states = [ordered]@{}
foreach ($entityId in $entityIds) {
  $states[$entityId] = Get-HaState -HaBaseUrl $HaBaseUrl -Token $haToken -EntityId $entityId
}

$dbStatus = Invoke-HaSsh -SshExe $sshExe -HaHost $HaHost -Port $Port -KeyPath $KeyPath -Command "ls -lh /homeassistant/home-assistant_v2.db* 2>/dev/null | sed -n '1,20p'"
$recorderErrors = Invoke-HaSsh -SshExe $sshExe -HaHost $HaHost -Port $Port -KeyPath $KeyPath -Command "ha core logs -n 250 | grep -i -E 'recorder|SQLAlchemyError|StaleDataError|database|corrupt' | tail -n 80"

$payload = [pscustomobject]@{
  captured_at = $capturedAt
  scope = "aeb_runtime_audit_snapshot"
  recorder = [ordered]@{
    db_files = $dbStatus
    recent_log_matches = $recorderErrors
  }
  states = $states
}
$payload | ConvertTo-Json -Depth 8 | Set-Content -Path $outputJson -Encoding utf8

$md = @()
$md += "# AEB Runtime Audit Snapshot ($date)"
$md += ""
$md += "- timestamp: $capturedAt"
$md += "- scope: aeb runtime audit snapshot"
$md += "- raw_json: ``$outputJsonName``"
$md += ""
$md += "## Vacation / presence policy"
$md += New-Line "input_boolean.policy_vacation_mode" (Get-StateValue $states["input_boolean.policy_vacation_mode"])
$md += New-Line "binary_sensor.cm_policy_vacation_mode" (Get-StateValue $states["binary_sensor.cm_policy_vacation_mode"])
$md += New-Line "binary_sensor.policy_allow_ac" (Get-StateValue $states["binary_sensor.policy_allow_ac"])
$md += New-Line "binary_sensor.policy_allow_vmc_boost" (Get-StateValue $states["binary_sensor.policy_allow_vmc_boost"])
$md += New-Line "binary_sensor.policy_allow_shift_load" (Get-StateValue $states["binary_sensor.policy_allow_shift_load"])
$md += New-Line "binary_sensor.climateops_noncritical_loads_allowed" (Get-StateValue $states["binary_sensor.climateops_noncritical_loads_allowed"])
$md += ""
$md += "## Shading feedback"
$md += New-Line "input_boolean.envelope_giorno_shade_applied" (Get-StateValue $states["input_boolean.envelope_giorno_shade_applied"])
$md += New-Line "input_boolean.envelope_notte1_shade_applied" (Get-StateValue $states["input_boolean.envelope_notte1_shade_applied"])
$md += New-Line "input_boolean.envelope_notte2_shade_applied" (Get-StateValue $states["input_boolean.envelope_notte2_shade_applied"])
$md += New-Line "binary_sensor.envelope_any_shade_applied" (Get-StateValue $states["binary_sensor.envelope_any_shade_applied"])
$md += New-Line "sensor.envelope_shade_applied_rooms" (Get-StateValue $states["sensor.envelope_shade_applied_rooms"])
$md += ""
$md += "## Envelope"
$md += New-Line "sensor.envelope_recommended_action" (Get-StateValue $states["sensor.envelope_recommended_action"])
$md += New-Line "sensor.envelope_worst_room_name" (Get-StateValue $states["sensor.envelope_worst_room_name"])
$md += New-Line "sensor.envelope_house_night_flush_potential" (Get-StateValue $states["sensor.envelope_house_night_flush_potential"])
$md += New-Line "sensor.envelope_house_passive_gain_state" (Get-StateValue $states["sensor.envelope_house_passive_gain_state"])
$md += New-Line "sensor.t_in_med" (Get-StateValue $states["sensor.t_in_med"])
$md += New-Line "sensor.t_in_notte2" (Get-StateValue $states["sensor.t_in_notte2"])
$md += New-Line "sensor.t_in_bagno" (Get-StateValue $states["sensor.t_in_bagno"])
$md += New-Line "sensor.t_out_effective" (Get-StateValue $states["sensor.t_out_effective"])
$md += ""
$md += "## AEB / ClimateOps"
$md += New-Line "sensor.climateops_hierarchy_reason" (Get-StateValue $states["sensor.climateops_hierarchy_reason"])
$md += New-Line "sensor.climateops_aeb_mvp_reason" (Get-StateValue $states["sensor.climateops_aeb_mvp_reason"])
$md += New-Line "sensor.climateops_aeb_mvp_mode" (Get-StateValue $states["sensor.climateops_aeb_mvp_mode"])
$md += New-Line "binary_sensor.climateops_aeb_mvp_permitted" (Get-StateValue $states["binary_sensor.climateops_aeb_mvp_permitted"])
$md += New-Line "switch.heating_master" (Get-StateValue $states["switch.heating_master"])
$md += New-Line "binary_sensor.vmc_is_running_proxy" (Get-StateValue $states["binary_sensor.vmc_is_running_proxy"])
$md += New-Line "sensor.vmc_active_speed_proxy" (Get-StateValue $states["sensor.vmc_active_speed_proxy"])
$md += New-Line "switch.ac_giorno" (Get-StateValue $states["switch.ac_giorno"])
$md += New-Line "switch.ac_notte" (Get-StateValue $states["switch.ac_notte"])
$md += New-Line "climate.ac_giorno" (Get-StateValue $states["climate.ac_giorno"])
$md += New-Line "climate.ac_notte" (Get-StateValue $states["climate.ac_notte"])
$md += ""
$md += "## Branch feedback"
$md += New-Line "input_boolean.cm_ac_branch_powered" (Get-StateValue $states["input_boolean.cm_ac_branch_powered"])
$md += New-Line "sensor.cm_ac_branch_advice" (Get-StateValue $states["sensor.cm_ac_branch_advice"])
$md += New-Line "input_boolean.cm_mirai_branch_powered" (Get-StateValue $states["input_boolean.cm_mirai_branch_powered"])
$md += New-Line "sensor.cm_mirai_branch_advice" (Get-StateValue $states["sensor.cm_mirai_branch_advice"])
$md += New-Line "binary_sensor.cm_modbus_mirai_ready" (Get-StateValue $states["binary_sensor.cm_modbus_mirai_ready"])
$md += New-Line "binary_sensor.cm_modbus_ehw_ready" (Get-StateValue $states["binary_sensor.cm_modbus_ehw_ready"])
$md += ""
$md += "## MIRAI / EHW truth"
$md += New-Line "sensor.mirai_machine_state" (Get-StateValue $states["sensor.mirai_machine_state"])
$md += New-Line "binary_sensor.mirai_machine_running" (Get-StateValue $states["binary_sensor.mirai_machine_running"])
$md += New-Line "sensor.mirai_power_w" (Get-StateValue $states["sensor.mirai_power_w"])
$md += New-Line "sensor.ehw_tank_top" (Get-StateValue $states["sensor.ehw_tank_top"])
$md += New-Line "sensor.ehw_tank_bottom" (Get-StateValue $states["sensor.ehw_tank_bottom"])
$md += New-Line "binary_sensor.ehw_running" (Get-StateValue $states["binary_sensor.ehw_running"])
$md += New-Line "sensor.ehw_power_w" (Get-StateValue $states["sensor.ehw_power_w"])
$md += ""
$md += "## Recorder health"
$md += "### DB files"
$md += '```text'
$md += $dbStatus.output
$md += '```'
$md += ""
$md += "### Recent recorder log matches"
$md += '```text'
$md += $(if ([string]::IsNullOrWhiteSpace($recorderErrors.output)) { "none" } else { $recorderErrors.output })
$md += '```'

$md -join "`r`n" | Set-Content -Path $outputMd -Encoding utf8

Write-Host "Snapshot markdown: $outputMd"
Write-Host "Snapshot json    : $outputJson"
