# STEP78 - MIRAI manual runtime truth execution runbook

Date: 2026-04-24
Scope: convert the existing MIRAI manual run-window plan into one execution-grade runbook that can be used live to close `runtime truth` without changing runtime logic.

This step does not close MIRAI by itself. It defines the exact evidence pack and pass/fail criteria for the manual observed window.

## FACT

- `STEP50` closed only the advisory scaffold.
- `STEP51` prepared the observed manual window, but the observed evidence pack has not yet been collected.
- Current season is not suitable for waiting on a natural winter demand window.
- Therefore the correct closure path is a controlled manual observed run.

## IPOTESI

- Confidenza alta: one well-observed manual `OFF -> RUN` window is enough to close MIRAI runtime truth if power, Modbus and corroboration signals align.
- Confidenza alta: the shortest useful window is `20-30 min`.
- Confidenza alta: `30-45 min` is preferable because it reduces ambiguity around startup transients.

## DECISIONE

- Execute MIRAI runtime-truth closure manually.
- Do not wait for winter conditions.
- Do not change mappings, advisory thresholds or branch topology during the observed window.

## Window target

- Start posture: MIRAI idle or effectively off.
- Action: manual controlled start.
- Observation duration:
  - minimum: `20 min`
  - target: `30-45 min`

## Live execution checklist

### 1. Pre-window

FACT
- The run should begin from a clean idle posture.

DECISIONE
- Before starting, verify on dashboard `8 Mirai`:
  - `binary_sensor.mirai_runtime_truth_coherent_run = off`
  - `binary_sensor.mirai_runtime_truth_run_window_candidate = off` or clearly idle
  - `sensor.mirai_runtime_truth_reason` indicates no active run window or equivalent
  - `sensor.mirai_power_w_effective` is near idle baseline

### 2. Start action

FACT
- The closure depends on a human-observed transition, not on a synthetic paper check.

DECISIONE
- Force MIRAI ON manually in a controlled way.
- Keep other unrelated domains unchanged during the window:
  - no unrelated branch toggles
  - no mapping edits
  - no dashboard/entity renames

### 3. Immediate capture

DECISIONE
- As soon as MIRAI is visibly starting or immediately after the manual start action, run locally:

```powershell
python ops\mirai_scan_runtime.py --rounds 6 --interval 20 --profile quick
```

- This produces:
  - `tmp/mirai_scan_changes.csv`

### 4. Signals to observe live

DECISIONE
- Watch these entities on dashboard `8 Mirai` during the full window:
  - `binary_sensor.mirai_runtime_truth_run_window_candidate`
  - `binary_sensor.mirai_runtime_truth_modbus_run_confirmed`
  - `binary_sensor.mirai_runtime_truth_pump_corroborated`
  - `binary_sensor.mirai_runtime_truth_coherent_run`
  - `sensor.mirai_runtime_truth_score`
  - `sensor.mirai_runtime_truth_reason`
  - `sensor.mirai_machine_state`
  - `sensor.mirai_machine_running_source`
  - `sensor.mirai_power_w_effective`

### 5. Evidence to save

DECISIONE
- Save one evidence pack containing:
  - screenshot before start
  - screenshot during stable run
  - screenshot near stop or end of observation
  - `tmp/mirai_scan_changes.csv`
  - one short manual note:
    - start timestamp
    - stop timestamp
    - whether `coherent_run` turned `on`
    - whether the machine was audibly/visibly running

Recommended target directory:

```text
docs/runtime_evidence/2026-04-24/
```

## Pass / fail criteria

### PASS

FACT
- MIRAI runtime truth can be considered closed if a coherent run is observed, not just inferred.

DECISIONE
- Close MIRAI runtime truth only if:
  - `binary_sensor.mirai_runtime_truth_coherent_run = on`
  - for a meaningful part of the observed window
  - with coherent alignment of:
    - power rise
    - Modbus run confirmation
    - pump/probe corroboration
    - human-observed machine behavior

### PARTIAL

DECISIONE
- Mark the window as partial if:
  - `run_window_candidate = on`
  - but `modbus_run_confirmed` and/or `pump_corroborated` stay `off`
  - or the machine behavior remains ambiguous

### FAIL / REPEAT

DECISIONE
- Repeat the window if:
  - MIRAI never truly enters run
  - the window is too short
  - evidence artifacts are missing
  - unrelated changes polluted the session

## Post-window closure artifact

DECISIONE
- After the observed window, write one short audit note with:
  - execution date/time
  - evidence directory
  - pass/partial/fail verdict
  - promoted or non-promoted runtime-truth status

## Final decision

DECISIONE
- MIRAI runtime truth is not waiting on more analysis.
- It is waiting on one controlled manual observed run.
- After that evidence pack, the project can either:
  - close MIRAI runtime truth
  - or isolate the remaining gap precisely with no further generic discovery
