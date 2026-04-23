# STEP74 - Field and sensor ROI cleanup

Date: 2026-04-23
Scope: non-purchase cleanup pass for field sensors, physical feedback and BMS signal quality after scheduler closure.

This step does not change runtime logic, does not deploy Home Assistant packages and does not authorize purchases.

## FACT

- Scheduler/observability continuity is now closed as `CLOSED / ACTIVE` in `STEP73_SCHEDULER_CLOSURE_2026-04-23.md`.
- MIRAI manual runtime truth remains open and requires a human-observable run window.
- Existing sensor/field baseline is documented in:
  - `BMS_ARCHITECTURE_SENSOR_AUDIT_2026-04-22.md`
  - `BMS_PHYSICAL_SENSOR_ACTUATOR_INVENTORY_2026-04-22.md`
  - `BMS_FIELD_LAYER_RS485_TOPOLOGY_PLAN_2026-04-22.md`
  - `BMS_FIELD_INSPECTION_CHECKLIST_2026-04-22.md`
- Current high-impact sensor gaps are already known:
  - room and outdoor T/RH depend on battery/cloud/radio devices;
  - CO2 is absent as an operational BMS signal;
  - window states are virtual/manual, not physical contacts;
  - AC/VMC feedback is mostly logical/proxy, not electrical;
  - MIRAI runtime truth is not closed for governed dispatch.

## IPOTESI

- Confidenza alta: the highest ROI now is not buying sensors, but removing ambiguity in which signals are allowed to influence control.
- Confidenza alta: a signal can remain useful even if it is not control-grade; it just must be labelled correctly.
- Confidenza alta: replacing every wireless sensor would create cost and churn before the physical cable paths and I/O grouping are known.
- Confidenza media: first physical work should favor feedback/measurement over new actuation.

## DECISIONE

- Keep current sensors in service unless they are stale, unavailable or actively misleading.
- Reclassify every relevant field signal by BMS authority:
  - `control-grade`: allowed to influence actuation or block conditions.
  - `diagnostic-grade`: allowed to validate, alarm, reconcile or trend.
  - `advisory-grade`: allowed to inform UI/recommendations only.
  - `legacy/fallback`: retained only until canonical source is stable.
- Do not add new writer paths.
- Do not add new RS485 slaves before physical topology is inspected.
- Do not purchase extra wireless/battery sensors as a default response to missing data.

## Signal Authority Matrix

| family | current source | current authority | target authority | immediate action | purchase status |
|---|---|---:|---:|---|---|
| Indoor T/RH giorno | SwitchBot battery/cloud | control-grade in practice | control-grade after health/stale guard | keep, monitor battery/stale, document cable options | hold |
| Indoor T/RH notte1 | SwitchBot battery/cloud | control-grade in practice | control-grade after health/stale guard | keep, monitor battery/stale, document cable options | hold |
| Indoor T/RH notte2 | Tuya battery/cloud | control-grade in practice | control-grade after health/stale guard | keep, monitor battery/stale, document cable options | hold |
| Bathroom T/RH | Tuya battery/cloud | control-grade for VMC boost | high-priority powered/cabled candidate | keep now; mark as first T/RH upgrade candidate | hold until route known |
| Outdoor T/RH | SwitchBot battery/cloud | control-grade for delta/freecooling | high-priority powered/cabled candidate | keep now; mark as first external upgrade candidate | hold until route known |
| CO2 giorno/notte | absent | none | control-grade input for VMC policy | define placement and protocol target only | hold |
| Window state | `input_boolean` + templates | advisory/manual | physical contact aggregation | keep as manual label; do not treat as hard physical truth | hold |
| VMC state | switch/proxy | control + diagnostic proxy | command plus physical/electrical feedback | keep command path; identify meter/feedback point | hold |
| AC state | SwitchBot/IR/proxy | control + diagnostic proxy | command plus electrical feedback | keep canonical bridge; identify meter/feedback point | hold |
| Heating master | Tuya relay behind `switch.heating_master` | control-grade command | control-grade command plus feedback | keep single authority; plan feedback separately | hold |
| SDM120 grid | Modbus RS485 | control-grade | canonical grid source | keep as primary; protect bus | no purchase |
| Tuya/Dual Meter grid fallback | LocalTuya/Tuya | legacy/fallback | fallback only | do not remove yet; declassify mentally | no purchase |
| EHW/ACS | Modbus | control-grade | governed Modbus path | keep; continue reconciliation in snapshots | no purchase |
| MIRAI/PDC | Modbus partial | diagnostic now | control only after runtime truth | keep read-only posture; no promotion | no purchase |
| Meross/Tuya plugs | cloud/local consumer | diagnostic/advisory | non-critical metering only | keep for temporary insight; do not use as BMS backbone | no purchase |

## Keep / Change / Hold

### Keep

- Existing T/RH sensors remain valid as operational baseline.
- SDM120 remains the canonical grid source.
- EHW Modbus remains the mature ACS field path.
- AC canonical driver bridge remains the correct software abstraction.
- Window `input_boolean` states remain useful as manual/advisory state.

### Change Now Without Purchases

- Treat manual window state explicitly as manual/advisory unless a real contact backs it.
- Treat `task_state=Running` in executive status as in-progress semantics, already addressed in STEP73.
- Use existing daily snapshots to watch:
  - T/RH availability/staleness;
  - EHW running-vs-power reconciliation;
  - AC/VMC proxy behavior;
  - MIRAI branch readiness and idle/run posture.
- Use the physical inspection checklist before choosing any sensor family.

### Hold

- CO2 device selection.
- Window contact hardware selection.
- DIN meter selection for AC/VMC.
- RS485 digital input modules.
- Any MIRAI dispatch promotion.

## Physical Inspection Checklist Before Purchases

| area | question | why it matters | outcome needed |
|---|---|---|---|
| Living area CO2 | Is Ethernet/PoE available or easily reachable? | determines PoE vs powered local node | placement/protocol decision |
| Night area CO2 | Is there a stable powered point near breathing zone? | avoids battery/cloud IAQ | placement/protocol decision |
| Bathroom T/RH | Can a powered sensor be placed without condensation risk? | VMC boost depends on this signal | sensor position decision |
| Outdoor T/RH | Is there shaded, rain-protected, powered/cabled placement? | freecooling/heating depends on outdoor truth | mounting decision |
| Windows giorno | Can contacts be grouped by zone with cable path? | aggregate contact may be enough | DI grouping decision |
| Windows notte | Can contacts be grouped without visible retrofit damage? | avoids overfitting every sash | DI grouping decision |
| VMC electrical line | Can VMC power be measured in panel or near supply? | physical feedback for VMC run state | meter point decision |
| AC giorno/notte lines | Are the split supply lines separable for metering? | feedback for IR/cloud actuation | meter point decision |
| RS485 gateway | What model serves `192.168.178.191:502`? | bus capacity and bias/termination | gateway record |
| MIRAI/SDM120 bus | What is physical device order and termination? | prevents bus instability | topology record |
| EHW bus | Is EHW on separate gateway or shared field segment? | future expansion boundary | segment record |

## ROI Priority Order

1. FACT: manual/virtual window states can be useful but are not physical truth.  
   DECISIONE: keep them, but do not build hard control assumptions on them.

2. FACT: bathroom and outdoor T/RH are high-impact and battery/cloud.  
   DECISIONE: mark them as first powered/cabled T/RH candidates, not immediate purchases.

3. FACT: CO2 is absent.  
   DECISIONE: define only target zones now: giorno and notte.

4. FACT: AC and VMC have proxy feedback.  
   DECISIONE: prioritize feedback/metering design over any new actuation logic.

5. FACT: RS485 already carries useful technical data.  
   DECISIONE: protect existing bus; expand only after topology is physically recorded.

## No-Purchase Exit Criteria

This cleanup step is complete when:

- critical signals are classified by authority;
- non-control-grade signals are not treated as physical truth;
- candidate physical inspection questions are documented;
- next physical data collection can happen without choosing hardware;
- gates pass without broken links or artifact policy failures.

## Next Action

DECISIONE
- Next non-MIRAI work should be a field inspection fill-in, not a purchase list:
  - fill `BMS_FIELD_INSPECTION_CHECKLIST_2026-04-22.md`;
  - capture photos/notes of gateway, bus, panel lines and candidate sensor routes;
  - then choose the smallest hardware wave by ROI.

DECISIONE
- If no physical inspection is possible immediately, continue with read-only runtime drift checks from the daily scheduler evidence.
