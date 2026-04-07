# STEP49 Open items and closure sequence (2026-04-07)

## Scope
- Reconstruct what is still open at repo/runtime level after Step47 and Step48.
- Clarify whether MIRAI has already been brought into AEB actuation scope.
- Define one pragmatic closure sequence instead of continuing with scattered follow-ups.

## Executive answer
- `MIRAI in AEB actuation`: **NOT CLOSED**
- `MIRAI in runtime / observability`: **PARTIAL**
- `DHW / EHW AEB MVP live path`: **CLOSED for first conservative pass**
- `Broader AEB orchestration`: **NOT CLOSED**

In practice:
- MIRAI is already part of the runtime context and energy observability.
- MIRAI is not yet closed as an explicitly governed AEB-dispatchable load.

## What is already closed

### Repo/runtime foundations
- ClimateOps runtime authority baseline: closed in earlier Step1/2/3 stream.
- Forecast, tariff/grid, KPI, hierarchy scaffolding: closed at repo level in Step7.x / Step8 stream.
- EHW read-feedback chain: closed.
- DHW writer path: closed.
- First conservative AEB MVP live pass on DHW/EHW: closed.
- DHW post-live semantic reconciliation: closed.
- Solar gain advisory scaffold: closed as module scaffold, still open for calibration.

### Why this matters
- The system is no longer missing the basic AEB control scaffolding.
- What remains open is not “foundation work”; it is closure of the last governed load paths and cross-load orchestration.

## What is still open

### 1. MIRAI runtime closure is still incomplete
Status:
- `OPEN`

Facts from prior audit stream:
- Step32 explicitly left MIRAI in `HOLD for validation in RUN reale`.
- Power/snapshot path is alive, but forensic closure on real `OFF -> RUN` evidence is not final.

Why still open:
- We still do not have a fully closed runtime truth chain proving stable real-run state transitions on MIRAI in the current profile.
- Without that closure, MIRAI cannot be promoted safely into stronger AEB actuation logic.

What closure means:
- observed real-run window
- correlated `power + state/snapshot + raw/effective status`
- no ambiguity about idle vs real active machine state

### 2. MIRAI is not yet a governed AEB-dispatchable load
Status:
- `OPEN`

Current code reality:
- `packages/climateops/strategies/planner.yaml` produces high-level `HEAT / COOL / IDLE`
- `packages/climateops/strategies/arbiter.yaml` observes `HEAT / COOL / VENT / IDLE`
- current AEB MVP live path exists only for DHW/EHW

Why still open:
- there is no equivalent MIRAI load-shift or surplus-driven writer/dispatcher closure
- there is no narrow “AEB MIRAI MVP” comparable to the DHW/EHW path

What closure means:
- explicit MIRAI control boundary
- gated/safe-by-default authority path
- observability and rollback posture
- at least one narrow live pass if actuation is introduced

### 3. AC single-writer authority cleanup remains open
Status:
- `OPEN`

Source:
- Step43 listed `AC single-writer authority cleanup` as a remaining AEB gap.

Why it matters:
- broader orchestration is weak if AC still has authority ambiguity
- cross-load decisions become harder to trust when one branch is not fully normalized

What closure means:
- one explicit authority chain for AC
- no ambiguity between legacy/manual/external writers and ClimateOps intent

### 4. Planner-actuated DHW / load shifting formalization remains open
Status:
- `OPEN`

Current reality:
- DHW writer exists and AEB MVP can reach a controlled live request
- but broader planner-driven formalization is still intentionally not enabled

Why still open:
- current path is still MVP/narrow
- there is no fully formalized planner-to-writer production policy beyond the conservative pass

What closure means:
- explicit promotion from MVP to governed planner-actuated path
- documented policy boundaries
- stable runtime evidence beyond one conservative pass

### 5. Multi-load dispatch closure remains open
Status:
- `OPEN`

Why still open:
- repo has hierarchy/planner signals, but not a closed cross-load dispatch surface across:
  - DHW/EHW
  - MIRAI
  - AC
  - VMC / noncritical climate loads

Current implication:
- the system can explain priorities, but not yet close the loop on a unified explicit energy hierarchy across all relevant loads

What closure means:
- one dispatch model that is both explainable and runtime-verifiable
- clear “who wins” and “who is held” semantics across loads

### 6. Windows real integration remains partial
Status:
- `OPEN`

Current reality:
- `packages/climate_ventilation_windows.yaml` still uses placeholder/input booleans

Why it matters:
- any solar/comfort/ventilation strategy remains weaker if open-window truth is partially synthetic

### 7. Solar gain advisory calibration remains open
Status:
- `OPEN`

Current reality:
- scaffold + dashboard are deployed
- thresholds are not yet tuned on a full sunny day

Why it matters:
- shutter recommendations should not be promoted to action logic before one real observation/tuning cycle

## Closure sequence recommended

### P1. MIRAI runtime truth closure
Reason:
- it is the blocking fact gap before promoting MIRAI into stronger AEB control

Target outcome:
- MIRAI real-run evidence closed

### P2. AC single-writer authority cleanup
Reason:
- before broad orchestration, the controllable climate branches need clean authority boundaries

Target outcome:
- AC authority ambiguity removed

### P3. MIRAI AEB MVP boundary
Reason:
- once MIRAI runtime truth is closed, it becomes the next natural governed load after DHW/EHW

Target outcome:
- narrow, safe, observable MIRAI AEB control surface

### P4. Planner-driven DHW formalization
Reason:
- DHW already has the most mature writer path; formalization should happen after the load set is cleaner

Target outcome:
- DHW promoted from narrow MVP to explicit planner-governed production logic

### P5. Multi-load dispatch closure
Reason:
- only after DHW/MIRAI/AC boundaries are individually trustworthy

Target outcome:
- explicit cross-load energy hierarchy closed at runtime, not only in repo heuristics

### P6. Windows real integration and solar gain tuning
Reason:
- useful, but not on the critical path for MIRAI/AEB closure

## Immediate next best step
- Start with `MIRAI runtime truth closure`, because it is the smallest meaningful blocker between the current system and “MIRAI inside AEB”.

## Decision
- Open-items map: `CLOSED`
- Closure sequence: `DEFINED`
- Next operational work item: `MIRAI RUNTIME TRUTH CLOSURE`
