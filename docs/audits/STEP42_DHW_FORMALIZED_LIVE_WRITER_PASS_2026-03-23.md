# STEP42 - DHW Formalized Live Writer Pass (2026-03-23)

## Scope

Document the successful reversible live validation of the formalized DHW writer path in runtime.

## Deploy / Activation

- patched [climateops_dhw_writer.yaml](C:\2_OPS\aeb\packages\climateops_dhw_writer.yaml) deployed to `/homeassistant/packages/climateops_dhw_writer.yaml`
- runtime activation via:
  - `ha core check`
  - `ha core restart`

## Baseline

- `binary_sensor.cm_modbus_ehw_ready = on`
- `sensor.ehw_setpoint_raw_a = 150`
- `sensor.ehw_setpoint_raw_calc = 150`
- `sensor.ehw_setpoint = 45.0`
- `sensor.climateops_dhw_actual_feedback = 45.0`

## Forward Request

- timestamp: `2026-03-23T21:29:03`
- requested target: `45.5°C`
- formalized writer result:
  - `LIVE_WRITE_SENT:hub=ehw_modbus|addr=1104|raw=152|target_c=45.5`

## Observed Forward Feedback

- first observed at: `2026-03-23T21:31:04`
- `sensor.ehw_setpoint_raw_a: 150 -> 152`
- `sensor.ehw_setpoint_raw_calc: 150 -> 152`
- `sensor.ehw_setpoint: 45.0 -> 45.6`
- `binary_sensor.cm_modbus_ehw_ready` stayed `on`

## Rollback

- rollback request timestamp: `2026-03-23T21:35:05`
- baseline restored by: `2026-03-23T21:37:07`

Restored values:

- `sensor.ehw_setpoint_raw_a = 150`
- `sensor.ehw_setpoint_raw_calc = 150`
- `sensor.ehw_setpoint = 45.0`
- `binary_sensor.cm_modbus_ehw_ready = on`

## Safe Default Restore

- restored at: `2026-03-23T21:41:08`
- `input_boolean.climateops_cutover_dhw = off`
- `input_boolean.climateops_dhw_write_enable = off`
- `input_boolean.climateops_dhw_request = off`
- `input_boolean.climateops_dhw_dry_run = on`

## Decision

`FORMALIZED LIVE WRITER VALIDATION PASSED`

## Remaining Refinement

Expected scaled-value semantics should be aligned from human `45.5` request wording to the observed device-consistent `45.6` runtime behavior before broader use.

## Boundary

This step validates the formalized DHW writer path only.

It does not yet authorize planner-driven DHW actuation or broader multi-load orchestration.
