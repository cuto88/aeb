# Current Runtime Status (2026-05-23)

## Scope
- Punto di ingresso unico per lo stato repo/runtime corrente dopo la verifica live del veto termico VMC.
- Questo documento aggiorna il quadro operativo precedente con l'evidenza live raccolta il `2026-05-23`.

## Executive summary
- Repo/gate posture: `PASS with audit follow-up`
- Runtime host/config posture: `PASS`
- Daily observability burn-in: `CLOSED`
- AEB supervisor bridge: `CLOSED`
- ClimateOps baseline authority: `CLOSED`
- DHW/EHW writer path: `CLOSED`
- AEB MVP observability and first conservative live pass: `CLOSED`
- MIRAI runtime truth: `CLOSED`
- AC single-writer authority cleanup: `CLOSED enough for current MVP`
- VMC delta UR policy tuning: `CLOSED`
- Solar Gain calibration for decision-grade use: `OPEN`
- Security / secrets hygiene: `OPEN`
- Source/runtime naming drift: `CLOSED`

## What is now closed

### Daily burn-in
- The daily runtime chain produced `GO` on `2026-05-22`.
- The supporting checkpoints all passed:
  - `HA core check`
  - `Current boot Phase1 errors`
  - `Phase1 writer service scan`

### Supervisor bridge
- `STEP110_AEB_SUPERVISOR_BRIDGE_CLOSURE_2026-05-15.md` closed the AEB supervisor bridge block.
- The host bridge remains reachable from the live runtime config path.

### Runtime truth and control
- MIRAI runtime truth remains closed and observed in daily snapshots.
- AC feedback cleanup remains closed enough for current MVP work.
- ClimateOps authority baseline remains stable.
- DHW/EHW governed writer path remains closed.
- VMC `P1_delta_ur` now uses a dedicated hysteresis helper plus a thermal veto in source, and the live runtime has been verified.

### Source-side realignment
- The planner/arbiter naming drift has been closed on the source side.
- The runtime confirmation has already been observed and closed.

### UI / notification ergonomics
- The envelope and ventilation notification controls are exposed as explicit opt-in flags in the dashboard trail.
- The `Passive House` overview was reduced toward a clearer summary role, while `10 Involucro` remains the technical drill-down.

## What remains open, but is not the next blocker

### 1. Security / secrets hygiene
- The project still has a critical documented secret issue in `.env`.
- This is the highest-risk residual item because it is a real security concern, not a feature gap.
- It needs rotation and hygiene, but it does not block reading the runtime posture.

### 2. Solar Gain
- `solar gain` remains advisory/calibration-bound, not action-grade.
- This is still open, but it is not the top ROI blocker after the current burn-in closure.

## Historical provenance retained

### Supervisor / governance trail
- `CURRENT_SUPERVISOR_STATUS.md` is historical provenance for the 2026-05-15 bridge/supervisor work.
- The dirty-worktree warning in that report belongs to the older snapshot and is not a current runtime blocker.

## Deferred by user priority
- Wired contacts integration: standby.
- CO2 first wave: standby.
- Garage main door state: standby.

## Operational interpretation
- The project is no longer blocked by observability continuity.
- The VMC delta UR policy change is now both source-fixed and runtime-verified.
- The next highest-ROI work remains:
  - security hygiene around the exposed token
  - drift cleanup in the source/runtime contracts
  - small governance trail updates so the status docs stay current

## Historical sources absorbed by this summary
- `STEP109_RUNTIME_BURN_IN_FREEZE_PLAN_2026-05-14.md`
- `STEP110_AEB_SUPERVISOR_BRIDGE_CLOSURE_2026-05-15.md`
- `STEP118_VMC_DELTA_UR_THERMAL_VETO_2026-05-23.md`
- `STEP119_VMC_DELTA_UR_RUNTIME_VERIFY_CLOSURE_2026-05-23.md`
- `docs/runtime_evidence/2026-05-22/aeb_runtime_audit_snapshot_20260522_073155.md`
- `docs/runtime_evidence/2026-05-22/phase4_daily_summary_20260522_073008.md`
- `docs/runtime_evidence/2026-05-22/phase7_executive_status_20260522_073203.txt`

## Use rule
- Use this file as the default entrypoint when the question is "what is the current runtime/repo posture after the 2026-05-23 VMC runtime verification closure?"
- Use `CURRENT_RUNTIME_STATUS_2026-05-22.md` when you need the immediately previous baseline snapshot.
- Use the original `STEP*` files when the question is forensic, date-specific, or needs exact evidence provenance.
