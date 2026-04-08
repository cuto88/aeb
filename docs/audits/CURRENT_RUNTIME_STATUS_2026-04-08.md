# Current Runtime Status (2026-04-08)

## Scope
- Punto di ingresso unico per lo stato runtime corrente dopo la sequenza di refresh audit tra febbraio e aprile 2026.
- Questo documento non sostituisce il dettaglio storico dei singoli `STEP*`, ma ne assorbe il quadro operativo.

## Executive summary
- Repo/gate posture: `PASS`
- Runtime host/config posture: `PASS`
- ClimateOps baseline authority: `CLOSED`
- DHW/EHW writer path: `CLOSED`
- AEB MVP observability and first conservative live pass: `CLOSED`
- MIRAI runtime truth: `PARTIAL`
- MIRAI as governed AEB-dispatchable load: `OPEN`
- AC single-writer authority cleanup: `OPEN`
- Solar Gain advisory scaffold: `CLOSED`
- Solar Gain calibration for decision-grade use: `OPEN`

## Current position

### Closed and stable
- Writer authority and core ClimateOps command chain are no longer the main open risk.
- Local quality gates are part of the normal operating posture and currently pass.
- DHW/EHW read-feedback, writer semantics, post-live reconciliation, and first conservative live write path are all closed.
- The unified operator-facing Lovelace posture is now centered on `lovelace/climate_casa_unified_plancia.yaml`.

### Open but bounded
- MIRAI is observable and partially validated, but not yet forensically closed on a real `OFF -> RUN` operating window in the current profile.
- MIRAI is still not formalized as a governed AEB-dispatchable load comparable to the DHW/EHW MVP path.
- AC authority cleanup remains unfinished, which weakens broader multi-load orchestration confidence.
- Solar Gain is structurally deployed and visible, but still requires calibration before it should influence any automation.

## Runtime health snapshot

### Repo and validation
- Repo gates: passing in current local state.
- Docs/gates structure: aligned after Lovelace archive handling and audit index consolidation.

### Host/runtime posture
- Recent refresh audits confirm:
  - `ha core check` passing
  - runtime package deployment coherent with repo intent
  - Home Assistant reachable and operational in the sampled windows

### DHW / EHW
- Current judgement: `GO`
- Why:
  - Modbus readiness and mapping are stable enough for current operating use
  - writer state and semantic reconciliation are coherent
  - conservative live path was already exercised and documented

### MIRAI
- Current judgement: `HOLD for closure`
- Why:
  - runtime observability exists
  - posture/modbus semantics have been improved
  - but there is still no final evidence pack for a clean real-run transition under demand

### ClimateOps automation health
- Current judgement: `WATCH but acceptable`
- Why:
  - no current evidence of systemic regression in the recent audit sequence
  - prior isolated runtime concerns have follow-up coverage and do not currently block operation

### Solar Gain / Passive House
- Current judgement: `advisory-only`
- Why:
  - package and UI integration are present
  - the active operator view is now `Passive House` inside the unified climate dashboard
  - calibration and trustworthiness for action-grade use remain open

## Recommended operational priorities
1. Close MIRAI runtime truth with one observed real-demand window and correlated evidence.
2. Finish AC single-writer authority cleanup.
3. Define a narrow MIRAI AEB MVP boundary only after runtime truth closure.
4. Promote DHW from conservative MVP path to planner-governed policy only after the load boundaries are cleaner.
5. Calibrate Solar Gain on real sunny-day evidence before any move toward cover/shutter actuation.

## Historical sources absorbed by this summary
- `STATUS_RUNTIME_CURRENT_2026-02-23.md`
- `DELTA_AUDIT_STATUS_2026-02-25.md`
- `STEP33_GENERAL_AUDIT_STATUS_2026-03-13.md`
- `STEP34_RUNTIME_REFRESH_AUDIT_2026-03-13.md`
- `STEP37_RUNTIME_REFRESH_FOLLOWUP_2026-03-21.md`
- `STEP47_POST_DEPLOY_RUNTIME_AUDIT_2026-04-06.md`
- `STEP49_OPEN_ITEMS_AND_CLOSURE_SEQUENCE_2026-04-07.md`

## Use rule
- Use this file as the default entrypoint when the question is “what is the current runtime status?”
- Use the original `STEP*` files when the question is forensic, date-specific, or needs exact evidence provenance.
