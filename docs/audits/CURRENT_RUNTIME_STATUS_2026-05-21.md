# Current Runtime Status (2026-05-21)

## Scope
- Punto di ingresso unico per lo stato repo/runtime corrente dopo il burn-in operativo e la chiusura del bridge supervisore.
- Questo documento aggiorna il quadro operativo precedente con l'evidenza giornaliera raccolta tra `2026-05-18` e `2026-05-21`.

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
- Solar Gain calibration for decision-grade use: `OPEN`
- Security / secrets hygiene: `OPEN`
- Source/runtime naming drift: `SOURCE FIXED / runtime verify pending`

## What is now closed

### Daily burn-in
- The daily runtime chain produced `GO` on:
  - `2026-05-18`
  - `2026-05-19`
  - `2026-05-20`
  - `2026-05-21`
- The supporting checkpoints all passed:
  - `HA core check`
  - `Current boot Phase1 errors`
  - `Phase1 writer service scan`
- `phase7_executive_status` on `2026-05-21` correctly reported `task_state=Running` as `IN_PROGRESS_PREVIOUS_RESULT`, not as a failure.

### Supervisor bridge
- `STEP110_AEB_SUPERVISOR_BRIDGE_CLOSURE_2026-05-15.md` closed the AEB supervisor bridge block.
- The host bridge is reachable from `n8n` and the canonical payload write path is working again.

### Runtime truth and control
- MIRAI runtime truth is closed and remains observed in daily snapshots.
- AC feedback cleanup is closed enough for current MVP work.
- ClimateOps authority baseline remains stable.
- DHW/EHW governed writer path remains closed.

## What remains open, but is not the next blocker

### 1. Security / secrets hygiene
- The project still has a critical documented secret issue in `.env`.
- This is the highest-risk residual item because it is a real security concern, not a feature gap.
- It needs rotation and hygiene, but it does not block reading the runtime posture.

### 2. Source/runtime naming drift
- The repo still has a residual verification step, but the source has been realigned on the canonical planner/arbiter names.
- The drift is now narrowed to runtime verification after reload, not to source contract ambiguity.

### 3. Supervisor / governance trail
- `CURRENT_SUPERVISOR_STATUS.md` is still a useful but stale generated snapshot.
- The dirty-worktree warning in that report is still a governance concern, but it is separate from runtime health.

### 4. Solar Gain
- `solar gain` remains advisory/calibration-bound, not action-grade.
- This is still open, but it is not the top ROI blocker after the current burn-in closure.

## Deferred by user priority
- Wired contacts integration: standby.
- CO2 first wave: standby.
- Garage main door state: standby.

## Operational interpretation
- The project is no longer blocked by observability continuity.
- The next highest-ROI work is not more runtime discovery.
- The next highest-ROI work is:
  - security hygiene around the exposed token
  - drift cleanup in the source/runtime contracts
  - small governance trail updates so the status docs stay current

## Historical sources absorbed by this summary
- `STEP109_RUNTIME_BURN_IN_FREEZE_PLAN_2026-05-14.md`
- `STEP110_AEB_SUPERVISOR_BRIDGE_CLOSURE_2026-05-15.md`
- `docs/runtime_evidence/2026-05-18/aeb_runtime_audit_snapshot_20260518_073035.md`
- `docs/runtime_evidence/2026-05-19/aeb_runtime_audit_snapshot_20260519_073150.md`
- `docs/runtime_evidence/2026-05-20/aeb_runtime_audit_snapshot_20260520_073151.md`
- `docs/runtime_evidence/2026-05-21/aeb_runtime_audit_snapshot_20260521_073151.md`
- `docs/runtime_evidence/2026-05-21/phase4_daily_summary_20260521_073007.md`
- `docs/runtime_evidence/2026-05-21/phase7_executive_status_20260521_073159.txt`

## Use rule
- Use this file as the default entrypoint when the question is "what is the current runtime/repo posture after the 2026-05-21 burn-in closure?"
- Use `CURRENT_RUNTIME_STATUS_2026-04-15.md` when you need the pre-burn-in baseline snapshot.
- Use the original `STEP*` files when the question is forensic, date-specific, or needs exact evidence provenance.
