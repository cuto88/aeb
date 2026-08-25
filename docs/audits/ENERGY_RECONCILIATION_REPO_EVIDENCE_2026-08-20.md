# AEB Energy — Repository and Historical Runtime Reconciliation (2026-08-20)

**Scope:** documentation-only audit  
**Runtime writes:** none  
**Purpose:** reconcile the intended AEB Energy architecture with repository implementation and already-recorded runtime evidence before any new development.

## 1. Executive finding

The Energy domain is materially more advanced than a first-pass repository inventory suggested.

AEB Energy is **not** merely a dashboard/sub-metering project waiting for a new optimizer. Historical audit evidence proves that a conservative AEB control path was already taken live for DHW/EHW, measured, reconciled after live operation, deployed, and subsequently closed as a working MVP path. Later runtime status also records the AEB supervisor bridge, MIRAI runtime truth, ClimateOps baseline authority, and AC authority cleanup as closed or sufficiently closed for the then-current MVP.

The present problem is therefore not "design Energy from zero" and not even simply "add decision logic". The actual unresolved problem is:

> reconnect the existing AEB control architecture to a whole-house energy-performance objective and a trustworthy long-horizon measurement/baseline layer, so that AEB can prove avoided kWh/EUR rather than only prove safe dispatch and local runtime behavior.

## 2. Evidence chronology

### 2025 design intent

`README_ClimaSystem.md` documented an Energy extension with:
- shared energy helpers/preferences;
- network/load power metering;
- PV surplus management and load diversion;
- global energy KPI summary.

This establishes that global Energy was part of the intended architecture.

### 2026-03-30 — grid SSOT cutover

Commit `a59c11b` promoted the SDM120 as canonical grid SSOT and introduced/preferred:
- `sensor.grid_power_w`
- `sensor.grid_direction`
- `sensor.grid_energy_import_kwh`
- `sensor.grid_voltage_v`
- `sensor.grid_current_a`

The legacy dual-meter branch was retained only as transitional fallback.

**Classification:** `IMPLEMENTED_NOT_CURRENT_RUNTIME_VERIFIED` for the 2026-08-20 audit. Historical implementation is proven; current live state still needs a fresh read-only verification.

### 2026-03-31 — first AEB live control pass

`STEP45_AEB_MVP_FIRST_LIVE_PASS_AND_MEASUREMENT_LAYER_2026-03-31.md` records a successful conservative AEB MVP live pass on DHW/EHW under favorable grid-export conditions.

Observed chain included:
- favorable grid/export readiness;
- `dhw_boost_live` AEB mode;
- a real live request;
- Modbus write to EHW;
- actual setpoint feedback;
- safe restoration of cutover/write-enable posture.

A measurement layer was then added for live requests, holds, last outcome and target/actual delta.

**Classification:** historical `DONE_VERIFIED` for first conservative DHW live path.

### 2026-04-03 / 2026-04-06 — post-live reconciliation and deploy verification

The post-live audit found the measurement layer structurally valid but identified a semantic mismatch between remembered requested/expected DHW state and the remaining actual setpoint. The following deploy audit records that the reconciliation rule closed this mismatch and that the AEB MVP package was present and coherent at runtime.

**Classification:** historical `DONE_VERIFIED` for DHW writer semantic reconciliation and deployed AEB MVP path.

### 2026-04-08 — runtime status

The then-current runtime status classified:
- ClimateOps baseline authority: CLOSED;
- DHW/EHW writer path: CLOSED;
- AEB MVP observability and first conservative live pass: CLOSED;
- MIRAI runtime truth: PARTIAL;
- MIRAI as governed AEB-dispatchable load: OPEN;
- AC authority cleanup: OPEN;
- Solar Gain: advisory-only.

This shows the project was explicitly progressing from a single-load AEB MVP toward broader governed loads.

### 2026-04-28 — Energy runtime UI role

`STEP105_POWER_RUNTIME_DASHBOARD_REFACTOR_2026-04-28.md` explicitly keeps `6 Power Runtime` as an energy summary dashboard with:
- grid/SDM120 power and direction;
- local load power;
- daily shares;
- consumption/trend KPIs.

It is intentionally a summary UI, not the full AEB control architecture.

This is important: the limited role documented in `docs/logic/energy_pm/README.md` must not be interpreted as the maturity of the whole AEB Energy domain. It describes the Energy PM monitoring module only.

### 2026-05-23 — later runtime closure state

`CURRENT_RUNTIME_STATUS_2026-05-23.md` records:
- daily observability burn-in: CLOSED;
- AEB supervisor bridge: CLOSED;
- ClimateOps baseline authority: CLOSED;
- DHW/EHW writer path: CLOSED;
- AEB MVP observability and first conservative live pass: CLOSED;
- MIRAI runtime truth: CLOSED;
- AC single-writer cleanup: CLOSED enough for current MVP;
- VMC delta-UR policy tuning: CLOSED;
- Solar Gain calibration: OPEN.

Therefore, by late May 2026, the control/governance foundation was substantially more mature than the initial August reconciliation assumed.

## 3. Corrected reconciliation matrix

| Capability | Repository / historical evidence | Classification at 2026-08-20 | Note |
| --- | --- | --- | --- |
| Canonical grid power/direction | SDM120 promoted 2026-03-30 | `IMPLEMENTED_NOT_CURRENT_RUNTIME_VERIFIED` | fresh live check required |
| Canonical grid imported energy | `sensor.grid_energy_import_kwh` implemented | `IMPLEMENTED_NOT_CURRENT_RUNTIME_VERIFIED` | historical source known |
| PV production normalization | existing Energy PV package/docs | `IMPLEMENTED_NOT_CURRENT_RUNTIME_VERIFIED` | current live/data quality to verify |
| Local load sub-metering | Energy PM + runtime audits | `IMPLEMENTED_NOT_CURRENT_RUNTIME_VERIFIED` | historically live |
| Power Runtime summary UI | Step105 | `DONE_REPO_VERIFIED` | UI role is intentionally summary-only |
| DHW/EHW governed writer | runtime audits | `HISTORICAL_DONE_VERIFIED` | closed in May status |
| AEB conservative DHW dispatch | Step45/47 | `HISTORICAL_DONE_VERIFIED` | real live pass proven |
| AEB measurement/observability layer | Step45 onward | `HISTORICAL_DONE_VERIFIED` | counters valid only after deployment point |
| AEB supervisor bridge | May runtime status | `HISTORICAL_DONE_VERIFIED` | current live verification pending |
| ClimateOps baseline authority | May runtime status | `HISTORICAL_DONE_VERIFIED` | acts as comfort/safety authority |
| MIRAI runtime truth | May runtime status | `HISTORICAL_DONE_VERIFIED` | later than April partial status |
| MIRAI governed AEB dispatch | not proven closed by evidence reviewed here | `STATUS_TO_RECONCILE` | do not mark missing |
| AC single-writer authority | May status: closed enough for MVP | `HISTORICAL_DONE_VERIFIED` | broader AEB dispatch status still to reconcile |
| VMC energy monitoring | Energy PM/reallocation | `IMPLEMENTED_NOT_CURRENT_RUNTIME_VERIFIED` | optimization attribution not yet proven |
| Solar Gain advisory | May status | `IMPLEMENTED_NOT_DECISION_GRADE` | calibration open |
| Whole-house energy balance | grid/PV components exist | `IMPLEMENTED_NOT_END_TO_END_VERIFIED` | must verify formula, export energy source and history |
| Whole-house bill reconciliation | no closed evidence found in reviewed trail | `DESIGNED_NOT_VERIFIED_IMPLEMENTED` | key measurement gap |
| Weather/occupancy normalized baseline | no closed evidence found in reviewed trail | `DESIGNED_NOT_VERIFIED_IMPLEMENTED` | needed for savings attribution |
| Avoided kWh / avoided EUR per automation | local action metrics exist, outcome attribution not proven | `DESIGNED_NOT_VERIFIED_IMPLEMENTED` | primary strategic gap |
| Automated monthly Energy scorecard | no closed evidence found in reviewed trail | `DESIGNED_NOT_VERIFIED_IMPLEMENTED` | reporting layer |

## 4. Corrected architecture interpretation

The existing system should be understood as four layers:

1. **ClimateOps authority** — comfort, IAQ, safety, equipment constraints and climate demand.
2. **AEB supervisor / dispatch** — governed decisions and safe actuation of eligible flexible loads.
3. **Energy measurement** — grid SDM120, PV, local meters, machine feedback, Energy PM UI.
4. **Energy performance accounting** — whole-house reconciliation, baseline normalization, avoided kWh/EUR and long-horizon scorecard.

Layers 1-3 have substantial historical implementation evidence.

**Layer 4 is the principal unclosed strategic layer found by this audit.**

This explains the current concern: AEB has evidence that it can make safe energy-aware decisions, but the project does not yet have equivalent evidence that those decisions reduce total purchased/consumed energy over comparable periods.

## 5. Consequence for the 2026 consumption increase

The Feb-Jul 2026 billing increase versus 2025 must not be interpreted as proof that AEB or ClimateOps failed.

The existing evidence demonstrates safe/local AEB behavior, but not a closed whole-house savings attribution chain. Without weather/occupancy normalization and bill-to-HA reconciliation, the system cannot yet distinguish among:
- higher comfort demand;
- different weather;
- occupancy/behavior changes;
- new or changed loads;
- HVAC/ACS/VMC effects;
- genuine AEB savings that are smaller than other increases.

Therefore the correct project question is now:

> How much energy would Mercurio have consumed without each AEB action, and can that counterfactual be estimated with enough confidence to report avoided kWh and EUR?

## 6. No-development gate

No new Energy YAML, automation, helper, Lovelace view or n8n workflow is authorized by this document.

Before development, complete a **fresh read-only runtime verification** of the existing architecture, focusing only on evidence that can have drifted since the May 2026 runtime status:

1. SDM120 canonical grid entities and direction/sign;
2. import/export cumulative energy sources;
3. PV canonical power/energy sources;
4. local meter entities and current load assignment;
5. AEB supervisor state and currently eligible loads;
6. DHW/MIRAI/AC/VMC current control authority;
7. Energy Dashboard source configuration;
8. long-term-statistics continuity and earliest trustworthy date;
9. whole-house balance feasibility;
10. evidence, if any, of existing bill reconciliation/baseline/ROI logic not yet found in this review.

## 7. Documentation decision

`docs/ENERGY_STATE_RECONCILIATION.md` remains the audit gate, but its interpretation must use this evidence note: the historical control architecture is not to be rediscovered or rebuilt.

`docs/ENERGY_INTELLIGENCE_ROADMAP.md` remains the target direction, with emphasis shifted toward **Energy performance accounting and verified savings**, not creation of a new Energy controller.

## 8. Next action

Perform the fresh runtime read-only verification above. Then update the reconciliation matrix with `CURRENT_RUNTIME_VERIFIED` / `DATA_QUALITY_VERIFIED` evidence and identify the smallest true gap between the existing AEB system and verified whole-house energy savings.
