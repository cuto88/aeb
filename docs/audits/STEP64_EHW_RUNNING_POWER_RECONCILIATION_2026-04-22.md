# STEP64 - EHW running/power reconciliation

Date: 2026-04-22
Scope: EHW semantic hardening, no writer change.

## FACT

- Runtime snapshot showed:
  - `binary_sensor.ehw_running = on`
  - `sensor.ehw_power_w = 0.0`
  - `binary_sensor.cm_modbus_ehw_ready = on`
- Code inspection shows `binary_sensor.ehw_running` is derived from thermal demand:
  - `sensor.ehw_setpoint - sensor.ehw_tank_top >= 1.0`
- Therefore `binary_sensor.ehw_running` does not prove electrical or compressor/heater activity.
- Existing entity is used by dashboards/contracts and is left unchanged for compatibility.
- `packages/ehw_reconciliation.yaml` was copied to `/homeassistant/packages/ehw_reconciliation.yaml`.
- `ha core check` completed successfully after the file deploy.

## IPOTESI

- Confidenza alta: the observed mismatch is semantic, not necessarily a hardware fault.
- Confidenza alta: the BMS needs separate terms for demand, power-confirmed activity and mismatch.
- Confidenza media: `30 W` is a conservative threshold for "real EHW electrical activity" and can be tuned after observation.

## DECISIONE

- Keep `binary_sensor.ehw_running` as legacy thermal-demand indicator.
- Add non-breaking derived entities in `packages/ehw_reconciliation.yaml`:
  - `sensor.ehw_operation_state`
  - `binary_sensor.ehw_power_confirmed`
  - `binary_sensor.ehw_demand_power_mismatch`
- Do not change the DHW writer path.
- Do not infer equipment failure from `ehw_running=on` and `ehw_power_w=0` without checking the new reconciliation state.

## Expected Semantics

| state | meaning |
|---|---|
| `idle` | no thermal demand and no power |
| `active_power_confirmed` | power >= 30 W |
| `demand_no_power` | tank is below setpoint threshold but no meaningful power draw |
| `demand_power_unknown` | thermal demand exists but power source is unavailable |
| `idle_power_unknown` | no thermal demand, power source unavailable |

## Runtime Risk

- Low: additions are read-only template entities.
- No actuation path changes.
- No Modbus polling changes.
- No existing entity removed or renamed.

## Verification

- `yamllint packages/ehw_modbus.yaml packages/ehw_reconciliation.yaml`: PASS.
- Runtime file deploy: PASS.
- `ha core check`: PASS.

## Next Verification

- Reload/restart Home Assistant in a controlled window so the new package is loaded.
- Confirm new entities resolve in HA.
- Watch whether `demand_no_power` is a normal waiting state or a persistent anomaly.
