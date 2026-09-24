# EHW runtime evidence — 2026-09-24

Workstream: M63 / AEB-DHW-001  
Audit timestamp: 2026-09-24T05:58:00Z  
Method: read-only SSH and Home Assistant Recorder SQLite  
Runtime writes: 0

## Verified snapshot

| Signal | Value | Classification |
|---|---:|---|
| `binary_sensor.cm_modbus_ehw_ready` | `on` | available |
| `sensor.ehw_tank_top` | 45.9 degC | value verified; report freshness not reconstructable from Recorder `last_updated` alone |
| `sensor.ehw_tank_bottom` | 42.0 degC | value verified; report freshness not reconstructable from Recorder `last_updated` alone |
| `sensor.ehw_setpoint` | 45.0 degC | value verified; unchanged-value freshness requires `last_reported` |
| `sensor.ehw_power_w` | 43.91 W | operational evidence, not dedicated PM4 measurement |
| `sensor.ehw_operation_state` | `active_power_confirmed` | available |
| `binary_sensor.policy_surplus_ok` | `off` | no preheat eligibility |
| grid import | 646.11 W | import confirmed |
| `sensor.pm4_acs_power` | `unavailable` | gap |

The simultaneous PV-derived surplus value of 112.78 W and measured grid import
prove that PV production/surplus estimation alone is insufficient. Preheat must
require stable measured export.

## Controls and authority

- ClimateOps DHW dry-run: on.
- DHW write enable: off.
- DHW commanded/cutover/permission/boost: off.
- No Home Assistant service call, deploy, reload, restart or Modbus write occurred.

## Open evidence

- Installed `g01..g04` values and native treatment schedule/state.
- Direct runtime validation of `last_reported` behavior across at least one EHW
  poll and one SDM120 poll.
- Dedicated PM4 ACS measurement remains unavailable; it is not required to run
  non-actuating shadow evaluation, but prevents causal energy attribution.
- Comfort/normal/preheat targets remain subject to explicit approval.

## Decision

The owner approved the 45/50/55 degC shadow bounds on 2026-09-24. The package is
not authorized for deployment yet: the remaining pre-deploy gate is validation
of its freshness logic against `last_reported`. Missing `g01..g04` blocks live promotion and any
attempt to control treatment; it does not justify inventing Modbus registers.
