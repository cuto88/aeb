# STEP71 - AC reader feedback cleanup

Date: 2026-04-23
Scope: AC feedback/authority cleanup, no new hardware, no new AC writer.

## FACT

- Step70 introduced the canonical observed feedback layer:
  - `binary_sensor.cm_driver_ac_giorno_is_on`
  - `binary_sensor.cm_driver_ac_notte_is_on`
- The physical AC actuators remain:
  - `switch.ac_giorno`
  - `switch.ac_notte`
- Several non-writer consumers still used `switch.ac_*` as feedback source:
  - AC min ON/OFF lock diagnostics
  - AC last ON/OFF timestamp sensors
  - AC history_stats counters
  - ClimateOps AC KPI counters
  - VMC/AC request flag
  - envelope free-decay advisory logic

## IPOTESI

- Confidenza alta: `switch.ac_*` is still the correct physical actuation target for scripts and authority enforcement.
- Confidenza alta: diagnostic/advisory readers should consume `cm_driver_*`, because branch-off or unknown switch states should not pollute feedback semantics.
- Confidenza media: the current proxy remains diagnostic-grade, not physical proof of compressor state; future AC metering would improve confidence.

## DECISIONE

- Keep `switch.ac_*` for physical actuation paths:
  - `packages/climate_ac_mapping.yaml`
  - `packages/climateops/actuators/system_actuator.yaml`
  - `packages/climateops/drivers/ac_proxy.yaml` as the low-level proxy source
- Move reader/diagnostic consumers to canonical feedback:
  - `packages/climate_ac_logic.yaml`
  - `packages/climate_sensors.yaml`
  - `packages/climateops_phase1_kpi.yaml`
  - `packages/envelope_efficiency_advisory.yaml`
- Leave the broader room/solar advisory package cleanup as a separate backlog item to avoid mixing AC authority cleanup with passive-envelope tuning.

## ROI

- Reduces seasonal-rest false ambiguity when `switch.ac_*` is `unknown`.
- Makes AC telemetry consistent with the ClimateOps canonical driver bridge.
- Keeps single-writer discipline intact: no additional writer was introduced.
- Improves summer-readiness before enabling stronger AC orchestration.

## Verification

- `ops/gate_entity_map.ps1 -Mode strict_clima`: passed, `Missing in map (clima only): 0`.
- `ops/gates_run_ci.ps1`: `ALL GATES PASSED`.
- Runtime deploy completed for:
  - `/homeassistant/packages/climate_ac_logic.yaml`
  - `/homeassistant/packages/climate_sensors.yaml`
  - `/homeassistant/packages/climateops_phase1_kpi.yaml`
  - `/homeassistant/packages/envelope_efficiency_advisory.yaml`
- `ha core check`: passed.
- Controlled Home Assistant restart completed to load `history_stats` entity source changes.
- Runtime API after restart:
  - `binary_sensor.cm_driver_ac_giorno_is_on = off`
  - `binary_sensor.cm_driver_ac_notte_is_on = off`
  - `sensor.ac_giorno_tempo_on_oggi = 0.0`
  - `sensor.ac_giorno_cicli_on_oggi = 0`
  - `sensor.ac_notte_tempo_on_oggi = 0.0`
  - `sensor.ac_notte_cicli_on_oggi = 0`
  - `sensor.climateops_kpi_ac_cycles_today = 0`
  - `binary_sensor.clima_ac_from_vmc_request = off`

## Remaining boundary

- `switch.ac_*` may still be shown in Lovelace as raw actuator state.
- Some passive-envelope/solar advisory readers still use raw `switch.ac_*`; they are non-writer advisory paths and remain backlog.
- AC feedback remains proxy-based until a physical energy/status signal is added.
- No automatic AC promotion is authorized by this step.
