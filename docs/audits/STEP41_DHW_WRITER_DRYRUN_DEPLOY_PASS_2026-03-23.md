# STEP41 - DHW Writer Dry-Run Deploy Pass (2026-03-23)

## Scope

Document the controlled deploy and dry-run validation pass of the additive DHW writer path.

## Deploy Method

- single-file deploy of [climateops_dhw_writer.yaml](../../packages/climateops_dhw_writer.yaml) to `/homeassistant/packages/climateops_dhw_writer.yaml`
- activation via:
  - `ha core check`
  - `ha core restart`

## Entity Materialization

The following entities materialized in live Home Assistant runtime:

- `input_boolean.climateops_dhw_write_enable`
- `input_boolean.climateops_dhw_dry_run`
- `input_boolean.climateops_dhw_request`
- `input_boolean.climateops_dhw_commanded`
- `input_number.climateops_dhw_requested_setpoint`
- `input_datetime.climateops_dhw_last_write_ts`
- `input_text.climateops_dhw_write_result`
- `binary_sensor.climateops_dhw_permitted`
- `sensor.climateops_dhw_actual_feedback`
- `sensor.climateops_dhw_blocked_reason`

## Safe Defaults

Verified at rest before dry-run trigger:

- `input_boolean.climateops_cutover_dhw = off`
- `input_boolean.climateops_dhw_write_enable = off`
- `input_boolean.climateops_dhw_request = off`
- `input_boolean.climateops_dhw_dry_run = on`
- `binary_sensor.cm_modbus_ehw_ready = on`
- `sensor.ehw_setpoint_raw_a = 150`
- `sensor.ehw_setpoint_raw_calc = 150`
- `sensor.ehw_setpoint = 45.0`

## Dry-Run Validation

Dry-run target:

- `45.5°C`

Observed dry-run result:

- `input_text.climateops_dhw_write_result = DRY_RUN:hub=ehw_modbus|addr=1104|raw=152|target_c=45.5`
- `input_boolean.climateops_dhw_commanded = on`
- `input_datetime.climateops_dhw_last_write_ts = 2026-03-23 10:06:35`
- `sensor.climateops_dhw_actual_feedback = 45.0`

Post-trigger steady state:

- `binary_sensor.climateops_dhw_permitted = off`
- `sensor.climateops_dhw_blocked_reason = IDLE`

This is coherent with request auto-reset after the dry-run path executed.

## No Live Write Proof

No live DHW write occurred during this validation.

Proof:

- `binary_sensor.cm_modbus_ehw_ready: on -> on`
- `sensor.ehw_setpoint_raw_a: 150 -> 150`
- `sensor.ehw_setpoint_raw_calc: 150 -> 150`
- `sensor.ehw_setpoint: 45.0 -> 45.0`

## Evidence

- [ehw_dhw_writer_dryrun_validation_20260323_100643.md](../runtime_evidence/2026-03-23/ehw_dhw_writer_dryrun_validation_20260323_100643.md)

## Decision

`DRY-RUN VALIDATION PASSED`

## Boundary

This step does not authorize planner-driven actuation or multi-load orchestration.

The next boundary is controlled live-write validation of the formalized DHW writer path.
