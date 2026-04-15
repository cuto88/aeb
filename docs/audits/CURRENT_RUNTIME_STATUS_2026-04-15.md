# Current Runtime Status (2026-04-15)

## Scope
- Punto di ingresso unico per lo stato repo/runtime corrente dopo il refresh operativo del `2026-04-15`.
- Questo documento aggiorna `CURRENT_RUNTIME_STATUS_2026-04-08.md` e assorbe i commit separati creati oggi su clima, ops hygiene, audit tooling, supervisor draft e MIRAI draft pack.

## Executive summary
- Repo/gate posture: `PASS with local audit follow-up`
- Runtime host/config posture: `PASS`
- ClimateOps baseline authority: `CLOSED`
- DHW/EHW writer path: `CLOSED`
- AEB MVP observability and first conservative live pass: `CLOSED`
- Outdoor temperature fallback hardening: `CLOSED`
- Involucro runtime audit toolkit: `CLOSED`
- Supervisor/n8n governance design: `DRAFT / PARTIAL`
- MIRAI Smart-MT validation pack: `DRAFT / PARTIAL`
- MIRAI runtime truth: `PARTIAL`
- MIRAI as governed AEB-dispatchable load: `OPEN`
- AC single-writer authority cleanup: `OPEN`
- Solar Gain package posture: `GO`
- Solar Gain calibration for decision-grade use: `OPEN`

## What changed on 2026-04-15

### Closed or materially improved
- `sensor.t_out_effective` and `binary_sensor.t_out_stale` are now part of the runtime package layer and are wired into climate/envelope/solar-gain consumers.
- `packages/climateops/strategies/requests.yaml` is now aligned with runtime reality:
  - `sensor.planner_recommended_mode` exists
  - legacy `sensor.climateops_planner_recommended_mode` does not exist
- `ops/deploy_safe.ps1` now preflights stale Git locks and `.gitignore` now excludes temp lock noise.
- A repeatable involucro audit toolkit now exists in repo:
  - runbook
  - checklist
  - handoff note
  - runtime snapshot script

### Added but still governance-scoped
- A read-only `supervisor` / `n8n` / host-bridge design and draft implementation is now present in repo.
- A MIRAI Smart-MT validation pack now exists as a read-first draft set:
  - do-not-touch-live note
  - profiled mapping plan
  - validation checklist
  - candidate registry
  - disabled-by-default probe package

## Runtime and repo judgement

### Climate / envelope
- Current judgement: `GO`
- Why:
  - runtime verification on `2026-04-15` confirmed:
    - `sensor.t_out_effective`
    - `binary_sensor.t_out_stale`
    - `sensor.planner_recommended_mode`
  - request sensors remain coherent with planner mode in sampled runtime state

### DHW / EHW
- Current judgement: `GO`
- Why:
  - no new regression signal was introduced by the current refresh
  - closure posture from `2026-04-08` remains valid

### Involucro / Solar Gain
- Current judgement: `GO for audit tooling`, `WATCH for calibration`
- Why:
  - operator-facing audit method is now clearer and more repeatable
  - solar gain remains advisory/calibration-bound, not action-grade

### Supervisor / n8n
- Current judgement: `HOLD as draft implementation`
- Why:
  - path safety is implemented in writer scripts
  - but the implementation does not yet fully match its own declared contract:
    - `runtime_evidence` block is described but not yet emitted by payload builder
    - workflow notification is Gmail with hardcoded recipient, while docs/tasks describe Telegram/env-var posture

### MIRAI
- Current judgement: `HOLD for runtime closure`
- Why:
  - branch posture and documentation quality improved
  - Smart-MT material is now better structured
  - but full real-demand runtime truth is still not closed

## Open but bounded
- Close MIRAI runtime truth with one observed real-demand evidence pack.
- Finish AC single-writer authority cleanup.
- Reconcile supervisor draft implementation with its documented contract before treating it as MVP-ready.
- Decide whether MIRAI Smart-MT draft material should remain on `main` as planning assets or stay branch-scoped.
- Decide whether the local `CURRENT_SUPERVISOR_STATUS.md` and human triage note should be promoted into the official audit trail.

## Local governance notes not yet absorbed into official trail
- `docs/audits/CURRENT_SUPERVISOR_STATUS.md` exists locally but is not yet committed.
- `docs/audits/HUMAN_REVIEW_TRIAGE_2026-04-15.md` exists locally but is not yet committed.
- These files are useful and current, but they are not yet part of the durable audit chain.

## Historical sources absorbed by this summary
- `CURRENT_RUNTIME_STATUS_2026-04-08.md`
- `CURRENT_DHW_WRITER_STATUS_2026-04-08.md`
- `CURRENT_SOLAR_GAIN_AND_BRANCH_POSTURE_STATUS_2026-04-08.md`
- commit `86d79c2` `feat(climate): add effective outdoor temperature fallback`
- commit `b35e47f` `chore(ops): harden git lock preflight and temp ignores`
- commit `c2e2885` `docs(audit): add involucro runtime audit toolkit`
- commit `74f6966` `feat(supervisor): add readonly supervisor design and bridge draft`
- commit `398f96b` `docs(mirai): add smartmt validation draft pack`
- commit `b2311e9` `docs(ops): document git write operations outside sandbox`

## Use rule
- Use this file as the default entrypoint when the question is “what is the current runtime/repo posture after the 2026-04-15 refresh?”
- Use `CURRENT_RUNTIME_STATUS_2026-04-08.md` when you need the pre-refresh baseline snapshot.
- Use the original `STEP*` files when the question is forensic, date-specific, or needs exact evidence provenance.
