# STEP40 - DHW Writer Validation Pass (2026-03-23)

## Scope

Document the reversible writer validation pass for EHW holding register `1104` after DHW feedback-chain closure.

## Precondition

The DHW feedback chain was already closed before this test:

- `sensor.ehw_setpoint_raw_a`
- `sensor.ehw_setpoint_raw_calc`
- `sensor.ehw_setpoint`
- `binary_sensor.cm_modbus_ehw_ready`

## Validation Surface

Authenticated Home Assistant Core fallback service path:

- `POST /api/services/modbus/write_register`

Exactly one forward write and one rollback write were executed against register `1104`.

## Baseline

- `binary_sensor.cm_modbus_ehw_ready = on`
- `sensor.ehw_setpoint_raw_a = 150`
- `sensor.ehw_setpoint_raw_calc = 150`
- `sensor.ehw_setpoint = 45.0`

## Forward Write

- timestamp: `2026-03-23T09:12:55`
- written raw target: `153`
- expected scaled target: `45.9`

## Observed Forward Feedback

- first observed change: `2026-03-23T09:15:25`
- `sensor.ehw_setpoint_raw_a: 150 -> 153`
- `sensor.ehw_setpoint_raw_calc: 150 -> 153`
- `sensor.ehw_setpoint: 45.0 -> 45.9`
- `binary_sensor.cm_modbus_ehw_ready` stayed `on`

## Rollback

- timestamp: `2026-03-23T09:17:55`
- raw rollback target: `150`
- return to baseline first observed: `2026-03-23T09:18:26`
- `sensor.ehw_setpoint_raw_a` back to `150`
- `sensor.ehw_setpoint_raw_calc` back to `150`
- `sensor.ehw_setpoint` back to `45.0`
- `binary_sensor.cm_modbus_ehw_ready` stayed `on`

## Evidence

- [ehw_writer_validation_1104_forward_20260323_092256.csv](C:\2_OPS\aeb\docs\runtime_evidence\2026-03-22\ehw_writer_validation_1104_forward_20260323_092256.csv)
- [ehw_writer_validation_1104_rollback_20260323_092256.csv](C:\2_OPS\aeb\docs\runtime_evidence\2026-03-22\ehw_writer_validation_1104_rollback_20260323_092256.csv)
- [ehw_writer_validation_1104_result_20260323_092256.md](C:\2_OPS\aeb\docs\runtime_evidence\2026-03-22\ehw_writer_validation_1104_result_20260323_092256.md)

## Cleanup

The temporary validation surface was removed after the test.

## Decision

`WRITE VALIDATION PASSED`

## Boundary

This does not formalize a production DHW writer yet.

The next boundary is production writer formalization with explicit authority, gates, and rollback semantics.
