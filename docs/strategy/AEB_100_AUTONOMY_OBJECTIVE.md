# AEB 100% Autonomy Objective

## Purpose

This document defines the strategic target for evolving AEB from a mature Home Assistant / ClimateOps system into a fully autonomous, closed-loop home energy and comfort operating system.

The goal is not to add generic automation. The goal is to close the loop:

```text
observe -> understand -> predict -> decide -> act -> verify -> improve
```

AEB must remain safe-by-default, explainable, reversible, and governed by single-writer authority.

---

## Target state

AEB should become an autonomous home operating layer capable of coordinating:

- VMC / ventilation
- heating
- AC / cooling / dehumidification
- DHW / ACS through EHW
- PV surplus and grid import/export
- tariffs and time windows
- comfort and occupancy constraints
- runtime evidence and diagnostics
- alerts, fallback, and rollback

The long-term target is a system that requires no daily micromanagement and can optimize comfort, energy cost, and system resilience automatically.

---

## Current strategic distance

Estimated distance from the ideal 100% autonomous architecture:

```text
Current maturity: ~55-65%
Target after next 3 closures: ~75-80%
Full ideal maturity: 100%
```

AEB is already strong in:

- modular package architecture
- YAML dashboards
- entity map governance
- validation gates
- runtime audits
- ClimateOps baseline
- VMC / heating / AC observability and partial control
- EHW telemetry and governed writer path

The remaining distance is mainly in autonomous decision closure, not in dashboarding or basic modularity.

---

## Strategic gaps to close

### 1. DHW / ACS active policy

Goal:

Move from EHW telemetry and safe writer capability to a governed DHW production policy.

Required capabilities:

- use PV surplus, tariff, forecast, comfort and safety constraints
- define minimum guaranteed ACS availability
- define safe setpoint bounds
- support dry-run, shadow mode, limited live mode, full live mode
- expose reason sensors and operator override

Success condition:

AEB can decide when to raise, hold, or avoid ACS production without manual intervention.

---

### 2. Multi-load AEB dispatch

Goal:

Create a system-level dispatcher that coordinates energy and comfort loads instead of letting each subsystem optimize in isolation.

Loads in scope:

- heating
- AC
- VMC
- DHW / ACS
- flexible electrical loads, where available

Required capabilities:

- priority arbitration
- PV surplus allocation
- grid import guardrails
- tariff-aware scheduling
- comfort protection
- anti-conflict rules
- single-writer authority

Success condition:

AEB can choose the best active load at any time and explain why.

---

### 3. Predictive planner from dry-run to real control

Goal:

Promote the existing predictive/planner layer from advisory or dry-run into controlled actuation.

Required phases:

1. dry-run
2. shadow mode
3. limited live control
4. full governed live control

Required safeguards:

- runtime evidence gate before promotion
- rollback path
- per-action reason
- maximum action frequency
- bounded setpoint changes
- manual override

Success condition:

The planner can schedule and execute controlled actions without breaking comfort or increasing risk.

---

### 4. Real window / opening sensor closure

Goal:

Close the ventilation-natural loop with reliable real opening states.

Required capabilities:

- window/opening sensor integration
- room-level or zone-level aggregation
- open/close recommendation validation
- interaction with VMC freecooling and AC lockout

Success condition:

AEB knows whether passive ventilation is possible, active, or conflicting with mechanical systems.

---

### 5. Runtime truth and drift closure

Goal:

Maintain strict alignment between repo, runtime, and actual device behavior.

Required capabilities:

- source/runtime drift checks
- MIRAI / plant RUN-state confirmation where still relevant
- deployment guardrails
- evidence-backed status docs
- no broad deploy while drift is unresolved

Success condition:

AEB never relies on assumptions when making runtime decisions.

---

## Autonomy architecture target

```text
DATA SOURCES
  sensors, PV, grid, tariffs, weather, occupancy, device states
      ↓
DATA LAYER
  canonical entities, history, KPIs, diagnostics, runtime evidence
      ↓
PREDICTIVE LAYER
  forecast, thermal inertia, PV availability, comfort risk, scenario planning
      ↓
POLICY + DISPATCH LAYER
  priorities, constraints, comfort, safety, energy cost, anti-conflict rules
      ↓
ACTUATION LAYER
  VMC, heating, AC, DHW, flexible loads
      ↓
VERIFICATION LAYER
  did the action work, did comfort improve, did cost/risk decrease
      ↓
GOVERNANCE LAYER
  audit, gates, rollback, documentation, manual override
```

---

## Operating principles

AEB 100% autonomy must respect these rules:

1. Single-writer authority for every critical actuator.
2. No duplicated KPIs or parallel aliases.
3. Runtime evidence before real actuation.
4. Dry-run before live mode.
5. Manual override always available.
6. Every action must have a reason sensor or traceable explanation.
7. Fail-safe before optimization.
8. Comfort and safety before energy saving.
9. Repo remains the source of truth.
10. Documentation must evolve with runtime changes.

---

## Promotion gates

No module may move to full autonomous control unless all gates pass:

- YAML validation passes
- entity map aligned
- no duplicate entities
- source/runtime drift checked
- runtime evidence collected
- fallback defined
- rollback tested or documented
- manual override exposed
- dashboard observability available
- no conflict with existing single-writer authority

---

## Roadmap

### Phase 1 — Stabilize residual risk

Focus:

- security / secrets hygiene
- source/runtime drift cleanup
- current status documentation alignment

Expected outcome:

AEB is safe to evolve without hidden runtime risk.

---

### Phase 2 — DHW / ACS autonomy MVP

Focus:

- define ACS production policy
- bind it to EHW writer path
- run in dry-run / shadow mode
- perform one bounded live rollout

Expected outcome:

DHW becomes the first fully governed flexible load.

---

### Phase 3 — Multi-load dispatch MVP

Focus:

- define central dispatcher
- rank heating, AC, VMC, DHW and flexible loads
- apply PV/tariff/grid constraints
- expose dispatch reason and selected load

Expected outcome:

AEB starts acting as one coordinated system, not separate automations.

---

### Phase 4 — Predictive planner live promotion

Focus:

- convert planner from advisory/dry-run to limited live control
- apply bounded actions only
- verify comfort and energy impact

Expected outcome:

AEB can plan ahead instead of reacting only to thresholds.

---

### Phase 5 — Sensor closure and digital twin lite

Focus:

- window/opening sensors
- CO2 / air quality where useful
- thermal inertia model
- solar gain calibration

Expected outcome:

AEB gains enough physical awareness to support higher autonomy.

---

## KPI targets

Minimum KPIs for declaring progress toward 100% autonomy:

- percentage of autonomous decisions executed without manual intervention
- number of prevented conflicts between loads
- PV self-consumption improvement
- grid import reduction during controllable windows
- comfort hours inside band
- number of fallback activations
- number of manual overrides
- failed action rate
- runtime drift incidents
- daily/weekly autonomy score

---

## Definition of done for 100% autonomy

AEB can be considered functionally autonomous when:

- all critical actuators are governed by single-writer authority
- DHW, VMC, heating and AC are coordinated by a central dispatch layer
- planner decisions can become live actions through gates
- runtime evidence confirms actions and outcomes
- failures trigger fallback or rollback automatically
- dashboards show state, reason, action and confidence
- user intervention is optional, not required for normal operation

---

## Non-goals

This objective does not require:

- adding dashboards for the sake of dashboards
- duplicating existing KPIs
- introducing uncontrolled AI agents
- bypassing Home Assistant governance
- replacing deterministic rules with opaque automation
- enabling live actuation without evidence gates

---

## Current priority

The next highest-ROI sequence is:

```text
1. security / secrets hygiene
2. DHW / ACS autonomous policy
3. multi-load dispatch
4. predictive planner live promotion
5. real sensor closure
6. digital twin lite
```

This roadmap should be treated as the strategic north star for future AEB work.
