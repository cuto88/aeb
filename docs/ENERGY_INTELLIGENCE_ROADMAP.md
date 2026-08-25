# Mercurio — Energy Intelligence Roadmap

**Status:** active roadmap from verified monitoring baseline  
**Scope:** Home Assistant + SSOT Mercurio + n8n  
**Implementation status:** whole-house monitoring baseline verified in M51; subsequent Energy layers may proceed incrementally  
**Companion document:** `docs/ENERGY_STATE_RECONCILIATION.md`  
**Resilience follow-up:** `M52[SYSTEM] SolarEdge locale — Verificare Modbus TCP/SunSpec e rendere resiliente il dato PV`

## 1. Executive decision

AEB Energy is not a greenfield subsystem. The existing monitoring stack has now been reconciled against the Home Assistant runtime and the whole-house Energy contract is operationally verified.

M51 established a stable baseline for:

- PV cumulative production;
- grid import;
- grid export;
- whole-house balance;
- AC branch sub-metering;
- Home Assistant Energy Dashboard long-term statistics.

The roadmap can therefore move beyond the previous reconciliation-only phase. New work must reuse the verified contract and avoid reintroducing legacy/raw entities.

## 2. Verified Energy contract

Canonical cumulative sources:

```text
PV:          sensor.pv_energy_total
GRID IMPORT: sensor.grid_energy_import_kwh
GRID EXPORT: sensor.grid_energy_export_kwh
AC:          sensor.ac_energy_total_kwh
```

Canonical instantaneous sources relevant to the baseline:

```text
GRID POWER: sensor.grid_power_w
AC POWER:   sensor.ac_power_w
PV POWER:   sensor.pv_power_now
```

Whole-house balance:

`house consumption = PV production + grid import - grid export`

This balance has been verified in real import and export intervals after SolarEdge recovery.

## 3. Current physical ownership

### Grid

SDM120 slave 2 is the authoritative bidirectional grid source.

- active power is signed;
- positive = import;
- negative = export;
- cumulative import and export are independent monotonic counters.

### AC

SDM120 slave 3 measures the domestic AC branch and is an individual/sub-consumption source, not an additional term in the house balance.

### PV

Current canonical cumulative PV source remains the SolarEdge cloud lifetime counter through `sensor.pv_energy_total`.

A SolarEdge cloud-stale incident occurred during M51 and later recovered with backfill. Current monitoring is healthy, but local-source resilience remains a separate improvement tracked by M52.

## 4. System objective

ClimateOps and AEB Energy keep distinct roles.

- **ClimateOps:** comfort, IAQ and safe climate operation.
- **AEB Energy:** minimize energy consumption and cost subject to ClimateOps comfort/IAQ/equipment constraints.

Target statement:

`minimize kWh / EUR while comfort, IAQ and equipment guardrails remain satisfied`

ClimateOps is an input/constraint layer for Energy, not a competing system.

## 5. Energy integrity rules

All subsequent phases must preserve these rules:

- canonical Energy consumers use stable wrapper entities rather than raw Modbus/API entities;
- cumulative energy templates must become unavailable when their raw source is unavailable instead of emitting false zero;
- `state_class: total_increasing` is used only for genuine cumulative counters;
- Dual Meter A/B channels remain local-load measurements and are not grid truth;
- AC branch energy is a sub-consumption and is never added to whole-house consumption;
- no offset-based source migration is allowed without proving semantic equivalence, scale and reset behavior;
- long-term statistics are not destructively rewritten merely to make historical charts look cleaner.

## 6. Current reconciliation status

The former R0–R2 reconciliation phases are complete for the core whole-house monitoring contract.

| Capability | State |
| --- | --- |
| Grid power | `DONE_VERIFIED` |
| Grid import cumulative | `DONE_VERIFIED` |
| Grid export cumulative | `DONE_VERIFIED` |
| PV cumulative | `DONE_VERIFIED` |
| Whole-house balance | `DONE_VERIFIED` |
| Energy Dashboard | `DONE_VERIFIED` |
| AC branch power/energy | `DONE_VERIFIED` |
| SolarEdge local resilience | `DESIGNED_NOT_IMPLEMENTED` / tracked by M52 |

See `ENERGY_STATE_RECONCILIATION.md` for evidence and historical incident details.

## 7. L0 — Whole-house truth

**Status: DONE_VERIFIED for monitoring.**

Required concepts now exist and are usable:

- grid import energy;
- grid export energy;
- PV production energy;
- house consumption derived from the balance;
- signed grid instantaneous power.

Verified balance examples are documented in `ENERGY_STATE_RECONCILIATION.md`.

Remaining L0 improvement is resilience, not correctness: M52 will determine whether the SolarEdge inverter can provide local SunSpec/Modbus power and lifetime energy as a future source or backup.

## 8. L1 — Load allocation

Next logical Energy layer.

Target hierarchy:

1. HVAC / Mirai
2. ACS / EHW
3. VMC
4. AC branch
5. washing machine
6. dryer
7. IT/server/workstations
8. other measured loads
9. unattributed residual

Target KPI:

`unattributed_energy_pct = residual_kWh / house_kWh * 100`

Initial target: >=80% attributed; mature target >=90%, only when extra metering has decision value.

Before adding meters, map existing measurements and overlap/double-count risks.

## 9. L2 — Context normalization

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

The Energy layer should consume canonical ClimateOps context rather than duplicate climate logic.

## 10. L3 — Energy KPIs

### House

- kWh/day and month;
- kWh/m²;
- nighttime base load;
- peak kW;
- YoY raw;
- YoY normalized;
- real EUR/month;
- unattributed residual %.

### HVAC / AC

- kWh/day/month;
- kWh/HDD heating;
- kWh/CDD cooling;
- kWh per comfort-hour;
- cycles and average cycle duration;
- standby consumption.

### ACS

- kWh/day;
- kWh/person-day when occupancy quality permits;
- standby-loss estimate;
- PV-surplus share.

### VMC

- kWh/day;
- kWh by speed/mode;
- boost energy cost;
- Wh/m3 only after airflow is validated;
- relationship between energy, IAQ and thermal benefit.

### PV

- production;
- self-consumption;
- self-sufficiency;
- export;
- flexible energy shifted to surplus;
- economic value of self-consumption.

## 11. Historical baseline

2025 may be used as an initial YoY reference where data is comparable, but must not automatically be treated as a normalized baseline.

MVP method:

1. same-period YoY;
2. HDD/CDD normalization for climate loads;
3. explicit correction for absence/occupancy where available;
4. separation of major measured loads;
5. residual analysis.

The SolarEdge stale/backfill incident in August 2026 is a known timestamp-quality artifact: cumulative state recovered, but some Home Assistant hourly statistics during the incident remain temporally distorted. Exclude or annotate that interval in analyses requiring hourly precision.

## 12. Automation ROI contract

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

## 13. Billing reconciliation

The Mercurio billing SSOT remains the independent external validation source.

Target monthly comparison:

- HA grid import over matching billing period;
- billed/distributor consumption;
- absolute kWh difference;
- percentage error.

Gate:

- <=3%: green;
- 3–5%: investigate;
- >5%: block ROI conclusions until explained.

This is now a valid next implementation/audit phase because the authoritative HA grid-import source has been verified.

## 14. SolarEdge local resilience — M52

M52 is a separate reliability task and does not block the current Energy Dashboard.

Known inverter:

`SE6000H-RW000BNN4`

Next action:

1. recover current LAN IP from active router/DHCP using the known historical MAC/hostname evidence;
2. test TCP 1502 / SunSpec read-only;
3. identify the SunSpec Common Model;
4. validate local AC Power and lifetime energy if exposed;
5. compare local lifetime against the canonical cloud cumulative before any migration decision.

Do not integrate local power into energy unless no native lifetime counter is available and the fallback architecture is explicitly approved.

## 15. Phased roadmap from current state

### Phase I1 — Billing reconciliation

Compare authoritative HA grid import with distributor/bill periods.

**Exit gate:** <=3% difference or explained variance.

### Phase I2 — Load allocation and residual

Map all existing sub-meters and calculate unattributed energy.

**Exit gate:** >=80% normal-day attribution or a documented decision that further metering has insufficient ROI.

### Phase I3 — Normalized baseline and scorecard

Normalize climate-sensitive loads and produce a monthly causal scorecard.

**Exit gate:** major monthly delta quantitatively explained.

### Phase I4 — Automation ROI

Measure real effects of Energy automations under ClimateOps guardrails.

**Exit gate:** at least three automations evaluated with measurable benefit/no-benefit.

### Phase I5 — Predictive optimization

Only after measurement quality remains stable:

- PV forecast;
- weather;
- price;
- pre-heating/pre-cooling;
- ACS surplus scheduling;
- peak shaving;
- load shifting.

## 16. Immediate next action

For the core Energy roadmap, proceed with **billing reconciliation and load-allocation mapping** using the verified M51 contract.

In parallel, M52 may improve SolarEdge local resilience without altering the current canonical Energy Dashboard until the local source is fully proven.
