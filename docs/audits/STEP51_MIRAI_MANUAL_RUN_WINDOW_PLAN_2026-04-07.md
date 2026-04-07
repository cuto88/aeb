# STEP51 MIRAI manual run window plan (2026-04-07)

## Scope
- Prepare the controlled manual MIRAI run window needed to close the `runtime truth` gap.
- Do not change runtime logic in this step.
- Define exactly what to do during the observed window and what counts as closure evidence.

## Why this is needed
- Given the current outdoor temperatures, MIRAI may not enter a natural `RUN` window soon enough.
- `MIRAI runtime truth closure` is still the highest-ROI blocker before any safe AEB promotion of MIRAI.
- Therefore a short controlled manual run is acceptable as an evidence-gathering action.

## Pre-check
- Open dashboard: `8 Mirai`
- Confirm initial idle posture:
  - `binary_sensor.mirai_runtime_truth_coherent_run = off`
  - `sensor.mirai_runtime_truth_reason` reports no active run window or equivalent
  - `sensor.mirai_power_w_effective` is near idle baseline

## Controlled run procedure
1. Force MIRAI ON manually in a controlled way.
2. Keep all other unrelated branches unchanged during the observation window.
3. As soon as MIRAI starts, run locally:

```powershell
python ops\mirai_scan_runtime.py --rounds 6 --interval 20 --profile quick
```

4. Let MIRAI run for about `20-30 min`.
5. Observe live on dashboard `8 Mirai`:
   - `binary_sensor.mirai_runtime_truth_run_window_candidate`
   - `binary_sensor.mirai_runtime_truth_modbus_run_confirmed`
   - `binary_sensor.mirai_runtime_truth_pump_corroborated`
   - `binary_sensor.mirai_runtime_truth_coherent_run`
   - `sensor.mirai_runtime_truth_score`
   - `sensor.mirai_runtime_truth_reason`
   - `sensor.mirai_machine_state`
   - `sensor.mirai_machine_running_source`

## Closure criterion
- Preferred closure evidence:
  - `binary_sensor.mirai_runtime_truth_coherent_run = on`
  - sustained for a meaningful part of the observed window
  - with coherent `power + Modbus + pump/probe` confirmation

- Partial evidence only:
  - `run_window_candidate = on`
  - but `modbus_run_confirmed` and/or `pump_corroborated` remain `off`

## Evidence to save
- Dashboard screenshot(s) from `8 Mirai`
- output artifact:
  - `tmp/mirai_scan_changes.csv`
- manual note with:
  - start time
  - stop time
  - whether `coherent_run` turned `on`

## Post-window
- Return MIRAI to normal posture.
- Write one short runtime audit using the captured evidence.

## Decision
- Manual observed run window plan: `READY`
- MIRAI runtime truth closure: `PENDING OBSERVED WINDOW`
