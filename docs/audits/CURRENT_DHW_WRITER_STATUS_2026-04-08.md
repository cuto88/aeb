# Current DHW Writer Status (2026-04-08)

## Scope
- Punto di ingresso unico per lo stato corrente del writer DHW / EHW.
- Riassume la sequenza di chiusura tra Step38 e Step43 senza sostituire il dettaglio storico.

## Executive summary
- Feedback chain DHW / EHW: `CLOSED`
- Reversible register write validation (`1104`): `PASSED`
- Dry-run writer validation: `PASSED`
- Formalized live writer validation: `PASSED`
- Post-live semantic reconciliation: `CLOSED`
- Planner-driven DHW actuation: `OPEN`
- Multi-load orchestration on DHW: `OPEN`

## Current position

### What is already closed
- The DHW/EHW feedback path is operational and coherent across:
  - `sensor.ehw_setpoint_raw_a`
  - `sensor.ehw_setpoint_raw_calc`
  - `sensor.ehw_setpoint`
- The writer boundary in `packages/climateops_dhw_writer.yaml` is real, gated, and safe-by-default.
- Dry-run and live-write paths have both been validated.
- Runtime semantics between requested, expected, and actual feedback have been reconciled.
- Operator-facing observability is present in the unified climate dashboard.

### What remains open
- Promotion from narrow writer path to planner-governed DHW policy.
- Explicit DHW participation in broader load-shifting and multi-load dispatch.
- Final closure depends on orchestration policy, not on the writer transport itself.

## Runtime judgement
- Transport/write path: `GO`
- Safety posture: `GO`
- Observability posture: `GO`
- Planner authority: `HOLD`

## Historical sources absorbed by this summary
- `STEP38_DHW_DERIVED_CHAIN_CLOSURE_2026-03-22.md`
- `STEP40_DHW_WRITER_VALIDATION_PASS_2026-03-23.md`
- `STEP41_DHW_WRITER_DRYRUN_DEPLOY_PASS_2026-03-23.md`
- `STEP42_DHW_FORMALIZED_LIVE_WRITER_PASS_2026-03-23.md`
- `STEP43_AEB_DHW_WRITER_CONSOLIDATION_2026-03-23.md`
- `STEP47_POST_DEPLOY_RUNTIME_AUDIT_2026-04-06.md`

## Use rule
- Use this file when the question is “is the DHW writer path closed and safe to reason about?”
- Use the original `STEP40`-`STEP43` notes when exact timestamps, evidence files, or validation staging details matter.
