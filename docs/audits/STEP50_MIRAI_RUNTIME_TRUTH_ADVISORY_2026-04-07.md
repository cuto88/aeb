# STEP50 MIRAI runtime truth advisory (2026-04-07)

## Scope
- Add one independent advisory layer to support MIRAI runtime-truth closure.
- Make the next observed MIRAI run window easier to classify as:
  - only power evidence
  - partially corroborated
  - coherent real run

## Implemented

New package:
- `packages/mirai_runtime_truth_advisory.yaml`

New entities:
- `binary_sensor.mirai_runtime_truth_inputs_ready`
- `binary_sensor.mirai_runtime_truth_run_window_candidate`
- `binary_sensor.mirai_runtime_truth_modbus_run_confirmed`
- `binary_sensor.mirai_runtime_truth_pump_corroborated`
- `binary_sensor.mirai_runtime_truth_coherent_run`
- `sensor.mirai_runtime_truth_score`
- `sensor.mirai_runtime_truth_reason`
- `sensor.mirai_runtime_truth_run_window_hours_today`
- `sensor.mirai_runtime_truth_coherent_run_hours_today`
- tuning helper:
  - `input_number.mirai_runtime_truth_min_run_w`

UI:
- `lovelace/8_mirai_plancia.yaml` extended with a dedicated `Runtime truth closure` block.

## Logic intent
- `run_window_candidate`:
  - sustained power-based run window
- `modbus_run_confirmed`:
  - Modbus ready and status bit 01 indicating run
- `pump_corroborated`:
  - candidate pump/runtime signal (`3547`) aligned with power-based run
- `coherent_run`:
  - all three layers aligned for a sustained window

## Why this step matters
- MIRAI was still blocked at `runtime truth closure` before any safe AEB promotion.
- This step does not close MIRAI itself.
- It reduces ambiguity in the next observed real-run window.

## Validation and deploy
- `ops/validate.ps1 = passed`
- `ha core check = Command completed successfully.`
- deployed to runtime:
  - `/homeassistant/packages/mirai_runtime_truth_advisory.yaml`
  - updated `/homeassistant/lovelace/8_mirai_plancia.yaml`

## Closure criterion for next runtime window
- `binary_sensor.mirai_runtime_truth_coherent_run = on`
- sustained for a meaningful interval
- with coherent `power / modbus / pump-candidate` signals

## Decision
- Advisory scaffold for MIRAI runtime closure: `CLOSED`
- MIRAI runtime truth closure itself: `OPEN`
