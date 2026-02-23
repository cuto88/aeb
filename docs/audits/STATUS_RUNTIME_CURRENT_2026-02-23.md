# Runtime Status Current (Post Stabilization)
Date: 2026-02-23
Scope: Operational snapshot after heating/AC runtime hardening

## Current State

### FACT
- Writer authority is centralized on `automation.climateops_system_actuate` for heating, VMC and AC command path.
- Heating mode mapping is active via `binary_sensor.heating_should_run` -> `sensor.cm_system_mode_suggested=HEAT`.
- Heating relay runtime mapping is corrected to `switch.4_ch_interruttore_3` (fixed typo `interrutore`).
- `sensor.heating_minutes_since_change` template was hardened to avoid persistent `unknown` due to relay object lookup drift.
- AC anti-churn is active:
  - `script.ac_giorno_apply`/`script.ac_notte_apply` are called only when target switch is OFF and run is allowed.
- AC safety-off enforcement is active and independent:
  - if AC is not requested, both `switch.ac_giorno` and `switch.ac_notte` are turned OFF (independent checks).
- Runtime reaction was improved:
  - `automation.climateops_system_actuate` now also triggers on `switch.ac_giorno` and `switch.ac_notte` state changes.

### FACT (runtime evidence)
- Recorder evidence confirms an event where both AC switches were manually ON and then both turned OFF in the same ClimateOps actuation cycle while mode was `HEAT`.
- Recorder evidence confirms heating chain execution on runtime:
  - `climateops_system_actuate` -> `switch.heating_master` -> physical relay `switch.4_ch_interruttore_3`.

## AEB Gap (What Is Still Missing)

### UNKNOWN / NOT IMPLEMENTED
- Forecast-based control (weather/PV forecast integration in runtime arbitration).
- Unified multi-load orchestration (heating/AC/VMC/DHW under one explicit energy hierarchy).
- Tariff/grid-aware optimization logic (import/export or dynamic price-aware policies).
- Formal KPI closure for AEB (self-consumption, shifting effectiveness, comfort-energy tradeoff dashboard).
- PV surplus runtime quality remains open:
  - `binary_sensor.policy_surplus_ok` is often `off/unknown` in sampled windows, limiting effective PV boost behavior.

## Operational Notes

### FACT
- Runtime evidence raw exports are local-only (`docs/runtime_evidence/`) and ignored by Git.
- SSH runtime access baseline is documented in `AGENTS.md` (host, port, key, path).
- `policy_surplus_ok` now has runtime fallback on `sensor.pv_power_now` (threshold helper `input_number.policy_surplus_pv_min_w`) when legacy `binary_sensor.surplus_ok` is not available.
