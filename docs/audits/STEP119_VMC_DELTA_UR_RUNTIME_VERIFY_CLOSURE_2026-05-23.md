# STEP119 - VMC delta UR runtime verify closure (2026-05-23)

## Goal
- Close the runtime verification gap after the `P1_delta_ur` hysteresis + thermal veto source change.

## What was verified
- The updated template was published to the live Home Assistant config mounted at `Z:\packages\climate_ventilation_templates.yaml`.
- `template.reload` completed successfully through the Home Assistant API.
- The runtime now exposes `binary_sensor.vmc_delta_ur_active`.
- Live state during verification:
  - `binary_sensor.vmc_delta_ur_active = on`
  - `sensor.delta_t_in_out = -3.8`
  - `sensor.ventilation_priority = P4_baseline`

## Interpretation
- The helper is not just present in source; it is live in runtime.
- The thermal veto is active as intended during a thermally unfavorable condition (`delta_t_in_out < 0.5`), preventing `P1_delta_ur` from firing.
- This closes the remaining runtime verification gap for the VMC tuning change.

## Result
- `P1_delta_ur` tuning: `CLOSED`
- Runtime verify: `CLOSED`
