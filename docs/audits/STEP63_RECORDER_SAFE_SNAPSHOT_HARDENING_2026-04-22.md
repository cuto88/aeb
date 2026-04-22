# STEP63 - Recorder-safe snapshot hardening

Date: 2026-04-22
Scope: host-side ops scripts only. No Home Assistant runtime deploy.

## FACT

- `ops/aeb_runtime_audit_snapshot.ps1` already existed and generated local Markdown/JSON evidence under `docs/runtime_evidence/<date>/`.
- STEP60 ranked recorder-independent evidence snapshots as the highest ROI item after the recorder DB incident.
- The previous snapshot did not include all STEP60 critical reconciliation signals:
  - VMC running/speed feedback
  - AC branch posture and climate state
  - MIRAI branch posture and runtime truth
  - EHW running-vs-power reconciliation fields
- `ops/phase5_task_runner.ps1` did not execute `aeb_runtime_audit_snapshot.ps1`.
- Local shell proxy environment uses dead proxy values (`127.0.0.1:9`), which made HA API calls fail until bypassed.

## IPOTESI

- Confidenza alta: daily file-based snapshots reduce future audit loss when recorder history is incomplete or corrupt.
- Confidenza alta: adding read-only state capture has high ROI and low runtime risk.
- Confidenza media: making the scheduled runner fail if the AEB snapshot fails is acceptable because missing evidence should be visible, not silently ignored.

## DECISIONE

- Extend `aeb_runtime_audit_snapshot.ps1` with the missing critical state families.
- Make `aeb_runtime_audit_snapshot.ps1` use `HA_URL` from `.env` and bypass local proxy variables for the HA API host.
- Add the snapshot script to `phase5_task_runner.ps1` before GO/NO-GO guard, retention and executive status.
- Update scheduler description and ops documentation to reflect recorder-safe snapshot capture.
- Do not deploy Home Assistant runtime changes for this step.

## Added Snapshot Fields

- `binary_sensor.vmc_is_running_proxy`
- `sensor.vmc_active_speed_proxy`
- `climate.ac_giorno`
- `climate.ac_notte`
- `input_boolean.cm_ac_branch_powered`
- `sensor.cm_ac_branch_advice`
- `input_boolean.cm_mirai_branch_powered`
- `sensor.cm_mirai_branch_advice`
- `binary_sensor.cm_modbus_mirai_ready`
- `sensor.mirai_machine_state`
- `binary_sensor.mirai_machine_running`
- `sensor.mirai_power_w`
- `binary_sensor.cm_modbus_ehw_ready`
- `sensor.ehw_tank_top`
- `sensor.ehw_tank_bottom`
- `binary_sensor.ehw_running`
- `sensor.ehw_power_w`

## Verification

- Manual run of `ops/aeb_runtime_audit_snapshot.ps1` generated:
  - `docs/runtime_evidence/2026-04-22/aeb_runtime_audit_snapshot_20260422_170733.md`
  - `docs/runtime_evidence/2026-04-22/aeb_runtime_audit_snapshot_20260422_170733.json`
- HA API state errors after proxy bypass: `0`.
- Recorder SSH section returned DB status and no recent recorder log matches.

## Next Verification

- Run `ops/phase5_task_runner.ps1` manually if `.env` and HA access are available.
- Do not run the full runner casually: it includes actual retention cleanup.
- Keep MIRAI manual run window separate; this step only improves observability continuity.
