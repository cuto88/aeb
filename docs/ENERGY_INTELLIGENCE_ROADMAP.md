# Mercurio — Energy Intelligence Roadmap

**Status:** target architecture / direction document  
**Scope:** Home Assistant + SSOT Mercurio + n8n  
**Implementation status:** BLOCKED pending Energy State Reconciliation  
**Companion document:** `docs/ENERGY_STATE_RECONCILIATION.md`

## 1. Executive decision

AEB Energy is **not a new greenfield subsystem**. Historical AEB documentation already defined an Energy extension with power metering, surplus management and global energy KPIs, and the current repository contains substantial energy monitoring and policy components.

The purpose of this roadmap is therefore not to redesign Energy from zero. It defines the **target end state and exit gates** against which the existing design, code and runtime must be reconciled.

Before any implementation, complete `ENERGY_STATE_RECONCILIATION.md` and classify existing capabilities as:

- `DONE_VERIFIED`
- `IMPLEMENTED_NOT_RUNTIME_VERIFIED`
- `RUNTIME_ACTIVE_DATA_UNVERIFIED`
- `DESIGNED_NOT_IMPLEMENTED`
- `IMPLEMENTED_NOT_INTEGRATED`
- `LEGACY_OR_OBSOLETE`
- `MISSING`

No new YAML, Lovelace, n8n workflow, helper, sensor or automation should be created during the reconciliation phase.

## 2. System objective

ClimateOps and AEB Energy have different roles.

- **ClimateOps:** pursue comfort, IAQ and safe climate operation.
- **AEB Energy:** minimize energy consumption and cost subject to ClimateOps comfort/IAQ/equipment constraints.

Target statement:

`minimize kWh / EUR while comfort, IAQ and equipment guardrails remain satisfied`

ClimateOps is therefore an input/constraint layer for Energy, not a competing system.

## 3. Why this matters now

From the Mercurio billing SSOT, the homogeneous February-July comparison currently shows:

| Period | 2025 | 2026 | Delta |
| --- | ---: | ---: | ---: |
| Feb-Mar | 299 kWh | 514 kWh | +215 kWh |
| Apr-May | 167 kWh | 299 kWh | +132 kWh |
| Jun-Jul | 184 kWh | 247 kWh | +63 kWh |
| **Total Feb-Jul** | **650 kWh** | **1,060 kWh** | **+410 kWh / +63%** |

This does **not** prove ClimateOps is ineffective: ClimateOps has primarily pursued comfort. It does prove that AEB currently lacks a verified end-to-end method for attributing changes in total energy use to weather, occupancy, loads and automations.

## 4. Existing documented base

Repository evidence already identifies:

- local load sub-metering and utility meters;
- PV production normalization and daily/monthly/yearly aggregation;
- VMC energy monitoring;
- ClimateOps comfort/cycle/VMC-boost KPIs;
- energy policy concepts for PV surplus, forecasts, grid price and grid flow;
- envelope efficiency advisory metrics.

Historical documentation also described an Energy extension including shared energy helpers, power metering, surplus management and a global KPI layer.

The reconciliation audit must determine what survived, what evolved, what is runtime-active and what remains incomplete.

## 5. Known documented boundary

`docs/logic/energy_pm/README.md` explicitly describes Energy PM as dashboard-oriented monitoring without decision logic and states that daily load shares currently use only locally measured loads because the whole-house consumption does not have a sufficiently solid runtime SSOT for reliable global percentages.

This is the current known bottleneck until runtime evidence proves otherwise.

## 6. Target end-to-end architecture

The completed Energy chain must be:

`physical meter -> canonical HA entity -> long-term statistics -> whole-house balance -> load allocation -> context -> normalized baseline -> control action -> measured avoided kWh -> avoided EUR -> automatic report`

### L0 — Whole-house truth

Required concepts, reusing existing entities where valid:

- grid import energy;
- grid export energy;
- PV production energy;
- house consumption energy;
- house instantaneous power.

Balance check:

`house consumption ~= grid import + PV production - grid export`

Do not create new canonical entities until the reconciliation audit determines whether suitable existing entities already exist.

### L1 — Load allocation

Target hierarchy:

1. HVAC / Mirai
2. ACS / EHW
3. VMC
4. washing machine
5. dryer
6. IT/server/workstations
7. other measured loads
8. unattributed residual

Target KPI:

`unattributed_energy_pct = residual_kWh / house_kWh * 100`

Initial target: >=80% attributed; mature target >=90%, only if additional metering has decision value.

### L2 — Context normalization

Relevant context:

- outdoor temperature;
- HDD/CDD or degree-hours;
- occupancy/absence;
- indoor comfort;
- significant window opening;
- HVAC state;
- VMC state;
- PV/solar conditions;
- exceptional events.

### L3 — Energy KPIs

#### House

- kWh/day and month;
- kWh/m²;
- nighttime base load;
- peak kW;
- YoY raw;
- YoY normalized;
- real EUR/month;
- unattributed residual %.

#### HVAC

- kWh/day/month;
- kWh/HDD heating;
- kWh/CDD cooling;
- kWh per comfort-hour;
- cycles and average cycle duration;
- standby consumption.

#### ACS

- kWh/day;
- kWh/person-day when occupancy data quality permits;
- standby losses estimate;
- PV-surplus share.

#### VMC

- kWh/day;
- kWh by speed/mode;
- boost energy cost;
- Wh/m3 only after airflow is validated;
- relationship between energy, IAQ and thermal benefit.

#### PV

- production;
- self-consumption;
- self-sufficiency;
- export;
- flexible energy shifted to surplus;
- economic value of self-consumption.

## 7. Baseline

2025 can be used as the initial YoY reference where data is comparable, but must not automatically be treated as a normalized baseline.

MVP method:

1. same-period YoY;
2. HDD/CDD normalization for climate loads;
3. explicit correction for absence/occupancy where available;
4. separation of major measured loads;
5. residual analysis.

Only after sufficient clean history should more sophisticated regression be considered.

## 8. Automation ROI contract

Every future energy automation must declare:

- hypothesis;
- affected load;
- primary KPI;
- ClimateOps comfort/IAQ/safety guardrails;
- baseline;
- activation date;
- observation period;
- estimated avoided kWh;
- avoided EUR;
- confidence LOW/MEDIUM/HIGH.

Success is not `automation triggered`.

Success is:

`avoided kWh / EUR with guardrails satisfied`.

## 9. Billing reconciliation

The Mercurio billing SSOT is an independent external validation source.

Target monthly comparison:

- HA consumption over matching billing period;
- billed/distributor consumption;
- absolute kWh difference;
- percentage error.

Proposed gate:

- <=3%: green;
- 3-5%: investigate;
- >5%: block ROI conclusions until explained.

Automation of this comparison with n8n is a **future implementation**, not part of the current documentation phase.

## 10. Target reporting

Future reporting should converge on one Energy Intelligence view and one monthly scorecard rather than proliferating dashboards.

Executive outputs should eventually include:

- house kWh;
- YoY raw/normalized;
- cost;
- PV/self-consumption;
- attributed vs residual energy;
- top consumption causes;
- ClimateOps guardrail status;
- best/worst energy automation result;
- reconciliation quality.

No dashboard implementation is authorized by this document.

## 11. Reconciliation-first roadmap

### Phase R0 — Documentation reconciliation

Read and reconcile historical Energy design, current module documentation and current repository implementation.

Deliverable: `ENERGY_STATE_RECONCILIATION.md` populated with evidence and capability states.

**Exit gate:** no known competing Energy SSOT and exact audit scope defined.

### Phase R1 — Runtime truth audit, read-only

Inspect actual Home Assistant runtime without modifications.

Verify:

- entities;
- entity IDs;
- physical sources;
- Energy Dashboard sources;
- utility meters;
- long-term statistics;
- history start dates;
- resets/gaps;
- double-count risks.

**Exit gate:** authoritative whole-house meter candidate and trustworthy history window identified.

### Phase R2 — Gap classification

Update documentation only and classify every required capability.

**Exit gate:** exact list of work that is truly missing vs merely unintegrated.

### Phase I1 — Whole-house truth and reconciliation

Future implementation phase. Reuse existing components wherever possible.

**Exit gate:** HA vs bill <=3% or difference explained.

### Phase I2 — Allocation and residual

Future implementation phase.

**Exit gate:** >=80% of normal-day energy attributed.

### Phase I3 — Normalized baseline and scorecard

Future implementation phase.

**Exit gate:** monthly delta quantitatively explained.

### Phase I4 — Automation ROI

Future implementation phase.

**Exit gate:** at least three energy automations evaluated with measurable benefit/no-benefit and guardrails.

### Phase I5 — Predictive optimization

Only after measurement quality is proven:

- PV forecast;
- weather;
- price;
- pre-heating/pre-cooling;
- ACS surplus scheduling;
- peak shaving;
- load shifting.

## 12. Current project state

At the date of this document:

- ClimateOps is the mature comfort-oriented control layer;
- Energy has substantial monitoring/policy foundations;
- historical Energy architecture existed;
- whole-house runtime truth is documented as a known weakness unless runtime audit proves it has since been resolved;
- robust automation energy ROI is not yet demonstrated;
- **development is intentionally paused until reconciliation is complete**.

## 13. Next action

Perform the read-only Energy Runtime Reconciliation Audit defined in `ENERGY_STATE_RECONCILIATION.md`.

During that audit:

- do not modify HA;
- do not create new entities;
- do not create dashboards;
- do not create n8n workflows;
- update documentation with evidence first.

Only after the documentation accurately describes the existing system should an implementation lot be approved.
