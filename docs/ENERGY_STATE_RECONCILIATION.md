# Mercurio — Energy State Reconciliation

**Status:** documentation / audit plan only  
**Implementation:** explicitly blocked until reconciliation is completed  
**Scope:** existing AEB energy design, repository state, Home Assistant runtime, historical data and SSOT bollette

## 1. Decision

The energy domain is **not a greenfield project**. Historical documentation shows that AEB already contemplated an Energy module with power metering, PV surplus management and global energy KPIs. The current repository also contains substantial energy monitoring and policy components.

The problem to solve before any further development is therefore:

> determine exactly which parts of the original Energy design are implemented, integrated, active in runtime, historically reliable, obsolete, or still missing.

No new automation, dashboard, sensor, helper or optimization logic should be developed until this reconciliation is complete.

## 2. Functional split

AEB must keep two distinct but coordinated objectives.

### ClimateOps
Primary objective: **comfort / IAQ / safe climate operation**.

ClimateOps provides constraints and operational demand such as comfort band, HVAC/VMC state, locks, reasons and safety conditions.

### AEB Energy
Primary objective: **minimize kWh and EUR subject to ClimateOps constraints**.

Target optimization statement:

`minimize energy/cost while comfort, IAQ and equipment constraints remain satisfied`

ClimateOps is therefore not replaced by Energy. It becomes a guardrail and source of context for energy optimization.

## 3. Evidence already found

### Historical design

`README_ClimaSystem.md` documents an Energy extension composed of:

- shared energy helpers/preferences;
- network/load power metering;
- PV surplus management and load diversion;
- global energy KPI summary.

This confirms that the Energy direction existed before the current reconciliation.

### Current monitoring documentation

`docs/logic/energy_pm/README.md` defines Energy PM as dashboard-oriented monitoring and explicitly states that its daily load shares use only locally measured loads because a sufficiently solid runtime SSOT for whole-house consumption is not currently available.

This is the clearest known boundary between the intended architecture and the currently documented operational maturity.

### Current repository capabilities

Existing repository components include at least:

- local load metering and utility meters;
- PV production normalization and aggregation;
- VMC energy monitoring;
- ClimateOps comfort/cycle KPIs;
- energy policy inputs for PV surplus, forecast, grid price and grid flow;
- envelope efficiency advisory metrics.

These components must be reconciled, not duplicated.

## 4. Reconciliation matrix

Every Energy capability must be assigned exactly one state:

| State | Meaning |
| --- | --- |
| `DONE_VERIFIED` | documented, implemented, active in runtime and data quality verified |
| `IMPLEMENTED_NOT_RUNTIME_VERIFIED` | code exists but runtime state is not yet verified |
| `RUNTIME_ACTIVE_DATA_UNVERIFIED` | active entity exists but history/measurement quality is not yet proven |
| `DESIGNED_NOT_IMPLEMENTED` | canonical design exists but implementation is absent/incomplete |
| `IMPLEMENTED_NOT_INTEGRATED` | component works locally but is not part of the end-to-end Energy chain |
| `LEGACY_OR_OBSOLETE` | superseded component retained only for history/compatibility |
| `MISSING` | capability required by the target architecture and not previously designed/implemented |

Do not classify a capability as `MISSING` merely because it was not found in the first repository search.

## 5. Audit inventory to complete

### A. Whole-house truth

Verify:

- physical source of grid import/export;
- PV production source;
- whole-house instantaneous power;
- whole-house cumulative energy;
- Home Assistant Energy Dashboard sources;
- direction/sign conventions;
- reset behavior;
- long-term statistics continuity;
- comparison against distributor/bill periods.

### B. Load metering

For each physical/logical meter record:

- entity/source;
- physical device/channel;
- actual load;
- power W entity;
- cumulative kWh entity;
- daily/monthly utility meters;
- historical start date;
- overlap/double-count risk;
- current runtime status;
- confidence.

Minimum known domains to reconcile:

- Mirai / HVAC;
- EHW / ACS;
- VMC / PM1;
- washing machine / PM2;
- dryer / PM3;
- DS-01 / IT;
- other existing meters.

### C. Energy logic

Verify the current status and ownership of:

- PV surplus detection;
- self-consumption logic;
- flexible-load diversion;
- grid import/export policy;
- tariff/price policy;
- PV forecast;
- weather forecast;
- peak/grid-power thresholds;
- ACS energy scheduling;
- HVAC energy-aware operation;
- VMC energy-aware operation.

### D. ClimateOps interfaces

Map Energy inputs available from ClimateOps:

- comfort band;
- heating/AC runtime;
- VMC mode/boost;
- occupancy/house state where available;
- window state;
- indoor/outdoor temperature;
- IAQ/humidity constraints;
- reason/priority signals.

The Energy layer must consume canonical ClimateOps interfaces rather than duplicate climate logic.

### E. Historical baseline

Determine for each relevant series:

- earliest trustworthy timestamp;
- gaps;
- entity renames;
- meter replacements/resets;
- changes in load assignment;
- changes in household operation;
- whether 2025 is directly comparable with 2026.

The billing SSOT remains the independent external check for total purchased energy.

## 6. Required end-to-end chain

The Energy domain is considered complete only when this chain exists and is verified:

`physical meter -> canonical HA entity -> long-term statistics -> whole-house balance -> load allocation -> context normalization -> baseline -> control action -> measured delta kWh -> delta EUR -> automated report`

A component may be technically complete while the chain remains incomplete.

## 7. Documentation deliverables before development

The reconciliation phase must produce/update only documentation:

1. this state reconciliation document;
2. `ENERGY_INTELLIGENCE_ROADMAP.md` as the target direction and phased exit gates;
3. a runtime evidence matrix populated from read-only HA inspection when runtime access is performed;
4. references from existing Energy module documentation to the reconciled target, where appropriate.

No YAML/Lovelace/n8n changes are part of this phase.

## 8. Exit gate for documentation phase

Development may resume only when all of the following are known:

- authoritative whole-house meter candidate;
- actual HA runtime Energy sources;
- trustworthy historical period for each core meter;
- load-meter overlap map;
- status of the historical global-energy design;
- status of surplus/policy modules;
- exact list of `DESIGNED_NOT_IMPLEMENTED`, `IMPLEMENTED_NOT_INTEGRATED` and true `MISSING` items;
- canonical document ownership with no competing SSOTs.

## 9. Immediate next action

Perform a **read-only Energy Runtime Reconciliation Audit** against Home Assistant and populate the matrix above. Do not modify runtime during the audit.

After the audit, update documentation first. Only then decide the smallest implementation lot.
