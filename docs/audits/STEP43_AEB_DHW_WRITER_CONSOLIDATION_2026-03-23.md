# STEP43 - AEB DHW Writer Consolidation Checkpoint (2026-03-23)

## Scope

Consolidate the completed DHW / EHW writer work into one repo-level checkpoint covering runtime truth, writer boundary, UI visibility, and remaining AEB gaps.

No new control logic is introduced in this step.

## Consolidated Runtime Truth

Closed and runtime-validated:

- DHW / EHW read-feedback chain
- reversible write validation on register `1104`
- formalized DHW writer path in `packages/climateops_dhw_writer.yaml`
- dry-run observability semantics

Current DHW writer posture:

- single logical writer path
- safe-by-default
- gated by:
  - `input_boolean.climateops_cutover_dhw`
  - `input_boolean.climateops_dhw_write_enable`
  - `input_boolean.climateops_dhw_dry_run`
  - `input_boolean.climateops_dhw_request`
- broader orchestration not enabled

## Writer Boundary

What is ready:

- direct DHW setpoint write path to holding register `1104`
- readback correlation through:
  - `sensor.ehw_setpoint_raw_a`
  - `sensor.ehw_setpoint_raw_calc`
  - `sensor.ehw_setpoint`
- operator observability through:
  - `sensor.climateops_dhw_actual_feedback`
  - `sensor.climateops_dhw_expected_feedback`
  - `binary_sensor.climateops_dhw_feedback_matches_expected`
  - `binary_sensor.climateops_dhw_permitted`
  - `sensor.climateops_dhw_blocked_reason`
  - `input_text.climateops_dhw_write_result`
  - `input_datetime.climateops_dhw_last_write_ts`

What is not ready:

- planner-driven DHW actuation
- PV/tariff/load-shifting orchestration for DHW
- multi-load dispatch closure

## UI / Plancia

`lovelace/climate_casa_unified_plancia.yaml` now includes a `DHW / EHW` block aligned to the existing `1 Clima Casa` style.

The UI block is operator-facing and observability-focused. It does not change authority or writer behavior.

## Evidence Trail

Primary closure notes:

- `docs/audits/STEP38_DHW_DERIVED_CHAIN_CLOSURE_2026-03-22.md`
- `docs/audits/STEP40_DHW_WRITER_VALIDATION_PASS_2026-03-23.md`
- `docs/audits/STEP41_DHW_WRITER_DRYRUN_DEPLOY_PASS_2026-03-23.md`
- `docs/audits/STEP42_DHW_FORMALIZED_LIVE_WRITER_PASS_2026-03-23.md`

Primary runtime evidence:

- `docs/runtime_evidence/2026-03-22/`
- `docs/runtime_evidence/2026-03-23/`

## Remaining AEB Gaps

Still open:

- AC single-writer authority cleanup
- planner-actuated DHW / load shifting formalization
- multi-load dispatch closure
- windows real integration still partial
- broader MIRAI runtime closure still not final

## Decision

`DHW WRITER PATH CONSOLIDATED`

## Next Best Step

Address AC single-writer authority cleanup before enabling broader cross-load orchestration.
