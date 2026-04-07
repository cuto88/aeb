# STEP48 Solar gain advisory scaffold (2026-04-06)

## Scope
- Add one independent advisory-only module to estimate passive solar gain and overheating risk.
- Expose a dedicated Lovelace dashboard for observation and threshold tuning.
- Do not add shutter actuation in this step.

## Why this step
- The next decision target is operational:
  - understand whether recent sunny days are producing useful passive heat gains
  - derive a practical recommendation about when shutters should be closed to avoid overheating
- Current repo already exposes enough signals for a first indirect estimate:
  - `sensor.t_in_med`
  - `sensor.t_out`
  - `sensor.pv_power_now`
  - `binary_sensor.windows_all_closed`
  - `switch.heating_master`
  - `switch.ac_giorno`
  - `switch.ac_notte`

## Implemented

### 1. Independent package
New package:
- `packages/solar_gain_advisory.yaml`

Main entities added:
- thresholds / tuning:
  - `input_number.solar_gain_pv_active_w`
  - `input_number.solar_gain_pv_strong_w`
  - `input_number.solar_gain_indoor_warm_c`
  - `input_number.solar_gain_indoor_hot_c`
  - `input_number.solar_gain_rise_warn_cph`
  - `input_number.solar_gain_rise_high_cph`
  - `input_number.solar_gain_outdoor_hotter_delta_c`
- advisory logic:
  - `binary_sensor.solar_gain_advisory_inputs_ready`
  - `binary_sensor.solar_gain_passive_candidate`
  - `binary_sensor.close_shutters_recommended`
  - `sensor.solar_gain_indoor_rise_rate_cph`
  - `sensor.solar_gain_passive_index`
  - `sensor.solar_gain_passive_level`
  - `sensor.solar_gain_overheating_reason`
- daily observation helpers:
  - `sensor.solar_gain_passive_candidate_hours_today`
  - `sensor.close_shutters_recommended_hours_today`

Design notes:
- `sensor.pv_power_now` is used as a practical proxy for solar availability
- periods with heating / AC active or windows open are excluded from the passive-gain candidate flag
- current output is advisory only; no `cover.*` or shutter actuation was introduced

### 2. Dedicated dashboard
First-pass Lovelace dashboard:
- standalone Solar Gain draft dashboard, later removed after consolidation

Historical note:
- the standalone dashboard was later absorbed into the `Passive House` view inside
  `lovelace/climate_casa_unified_plancia.yaml`
- no separate active sidebar entry is retained in the current configuration

Dashboard content:
- current solar gain index
- current shutter-close recommendation
- thermal context and diagnostics
- 24h trends
- daily observation counters
- threshold tuning section

## Validation and deploy
- local gates:
  - `ops/validate.ps1 = passed`
- runtime config:
  - `ha core check = Command completed successfully.`
- deployed to runtime:
  - `/homeassistant/packages/solar_gain_advisory.yaml`
  - first-pass standalone Solar Gain dashboard on runtime, later removed after UI consolidation
  - updated `/homeassistant/configuration.yaml`

Follow-up:
- the dedicated Solar Gain dashboard was later consolidated into the unified climate dashboard,
  so the active operator entrypoint is now `lovelace/climate_casa_unified_plancia.yaml`

## Current limitation
- The new module is not yet calibrated on a full sunny-day observation window.
- Therefore today's output should be treated as structural validation and first tuning only.
- A more trustworthy interpretation requires at least one daytime cycle with:
  - meaningful sun / PV production
  - windows closed
  - heating and AC off
  - visible indoor response

## Decision
- Module scaffold: CLOSED
- Runtime deploy: CLOSED
- Advisory quality for real shutter decisions: OPEN

## Recommended next step
- Observe the `Passive House` view in `lovelace/climate_casa_unified_plancia.yaml` through the next sunny day and tune thresholds from real behavior before introducing any shutter automation.
