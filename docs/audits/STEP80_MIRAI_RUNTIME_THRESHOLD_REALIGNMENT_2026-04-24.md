# STEP80 - MIRAI runtime threshold realignment

Date: 2026-04-24
Scope: apply the smallest defensible runtime-model change after the observed MIRAI run window of 2026-04-24.

## FACT

- The observed MIRAI window on 2026-04-24 showed real machine activity with:
  - human-observed machine run
  - thermal movement
  - `sensor.mirai_power_w` around `106-112 W`
- Runtime detection still remained `OFF` during that window.
- The current configured thresholds were:
  - `input_number.mirai_running_power_on_w = 150`
  - `input_number.mirai_runtime_truth_min_run_w = 150`

## IPOTESI

- Confidenza alta: the thresholds were too conservative for at least one real active operating regime of MIRAI.
- Confidenza alta: lowering the thresholds is the smallest high-ROI correction before attempting any broader logic remap.
- Confidenza media: `100 W` is a better operational threshold than `150 W` for the current profile, while still remaining comfortably above idle values.

## DECISIONE

- Realign both MIRAI power-based thresholds from `150 W` to `100 W`:
  - `input_number.mirai_running_power_on_w`
  - `input_number.mirai_runtime_truth_min_run_w`

## Why this is the right minimal fix

FACT
- Idle MIRAI posture in prior evidence was around single-digit watts.
- The observed active window stayed well above idle, but below the previous `150 W` threshold.

DECISIONE
- Do not expand run logic first.
- Do not reinterpret more registers first.
- First, allow the existing power-based branch of the model to see the real window that was already observed.

## What this does NOT claim

DECISIONE
- This step does not claim MIRAI runtime truth is now fully closed.
- This step does not promote unknown probe semantics to final truth.
- This step does not authorize any MIRAI actuation expansion.

## Expected effect

- `binary_sensor.mirai_machine_running_by_power` should become able to turn `on` during the type of real active window seen on 2026-04-24.
- `binary_sensor.mirai_machine_running` and runtime-truth advisory entities should become more likely to classify the next observed real window correctly.

## Final decision

DECISIONE
- Apply the minimal threshold correction now.
- Use the next short confirmatory MIRAI window to decide whether runtime truth can finally be closed.
