# STEP79 - MIRAI observed run window result

Date: 2026-04-24
Scope: record the manual observed MIRAI run window executed on 2026-04-24 and decide whether `runtime truth` can be closed.

## FACT

- A controlled human-observed MIRAI window was executed on 2026-04-24 evening.
- `riduzione notturna` was disabled before the test, so the thermostat adjustment acted on the live setpoint and not on the reduced/night setback.
- The thermostat setpoint was raised manually to force a real heating call.
- Human field observation during the window reported:
  - machine really running
  - thermal behavior visible on the machine
  - probe-like temperatures rising
  - electrical consumption increased

## Evidence collected

- Snapshot 1:
  - `docs/runtime_evidence/2026-04-24/aeb_runtime_audit_snapshot_20260424_212952.md`
- Snapshot 2:
  - `docs/runtime_evidence/2026-04-24/aeb_runtime_audit_snapshot_20260424_213310.md`
- Snapshot 3:
  - `docs/runtime_evidence/2026-04-24/aeb_runtime_audit_snapshot_20260424_214113.md`
- Register change scans:
  - `tmp/mirai_scan_changes.csv`
  - `tmp/mirai_scan_changes_followup.csv`
  - `tmp/mirai_scan_changes_final.csv`

## FACT

- MIRAI branch posture stayed coherent:
  - `input_boolean.cm_mirai_branch_powered = on`
  - `binary_sensor.cm_modbus_mirai_ready = on`
- Runtime snapshots showed power increase above idle:
  - `21:29:52` -> `sensor.mirai_power_w = 10.9`
  - `21:33:10` -> `sensor.mirai_power_w = 106.7`
  - `21:41:13` -> `sensor.mirai_power_w = 112.4`
- Despite that, runtime state remained:
  - `sensor.mirai_machine_state = OFF`
  - `binary_sensor.mirai_machine_running = off`
- Modbus scans during the window showed repeated movement in:
  - `1013`
  - `1015`
  - `3547`
  - `3548`
  - `9087`
- The strongest and most repeatable thermal-motion pair in this window was:
  - `3548`
  - `9087`

## IPOTESI

- Confidenza alta: the machine really entered a meaningful active state.
- Confidenza alta: the current runtime detection model is not promoting that active state to `RUN`.
- Confidenza alta: this is not a "no evidence" failure; it is a model-alignment failure.
- Confidenza alta: `sensor.mirai_probe_temp_a_c` should no longer be described primarily as a likely physical probe; current evidence makes a target/setpoint interpretation more plausible.

## Diagnostic reading

### What this window proves

FACT
- The MIRAI domain can be forced into a real observed active state from thermostat demand.
- Modbus remains alive and responsive during the window.
- Physical evidence and measured power moved together.

DECISIONE
- Treat this window as successful proof of:
  - real machine response to thermostat demand
  - live Modbus observability during the run

### What this window does NOT yet prove

FACT
- The official runtime-truth entities did not promote the window to `RUN` / `coherent_run`.

DECISIONE
- Do not mark `MIRAI runtime truth = CLOSED` yet.
- Mark the result as:
  - `PARTIAL STRONG EVIDENCE`
  - `model misalignment identified`

## Mapping impact

FACT
- `3548 / 9087` moved during the observed active window.
- `4000 / 9050 / 9086` did not emerge in this window as the most useful moving thermal channel.
- User field observation indicates the value exposed as `mirai_probe_temp_a_c` behaves more like a fixed water target around `34°C` than a true varying probe.

DECISIONE
- Reclassify `4000 / 9050 / 9086` from "probe A candidate" to "target/setpoint candidate".
- Promote `3548 / 9087` as the better moving thermal candidate pair for real machine behavior.

## Next closure action

DECISIONE
- The next action is not another blind manual window.
- The next action is a minimal MIRAI model alignment step:
  1. adjust run-detection interpretation to account for the real active state seen here
  2. update the semantic description of `4000 / 9050 / 9086`
  3. then perform one short confirmatory observed window if needed

## Final decision

DECISIONE
- `MIRAI runtime truth` after the 2026-04-24 window: `PARTIAL STRONG EVIDENCE`
- Project blocker status:
  - the blocker is no longer "missing observed window"
  - the blocker is now "runtime truth model not yet aligned to observed reality"
