# STEP60 ROI closure backlog (2026-04-22)

## Scope

Riallineare il progetto AEB/BMS dopo gli audit del 2026-04-15, 2026-04-21 e
2026-04-22, scegliendo il prossimo lavoro in base al massimo ROI tecnico.

Questo step non introduce acquisti e non cambia il runtime.

## Evidence used

- `docs/audits/CURRENT_RUNTIME_STATUS_2026-04-15.md`
- `docs/audits/STEP49_OPEN_ITEMS_AND_CLOSURE_SEQUENCE_2026-04-07.md`
- `docs/audits/STEP58_VACATION_RETURN_RUNTIME_AUDIT_2026-04-21.md`
- `docs/audits/STEP59_HA_RECORDER_DB_INCIDENT_2026-04-21.md`
- `docs/audits/BMS_ARCHITECTURE_SENSOR_AUDIT_2026-04-22.md`
- `docs/audits/BMS_PHYSICAL_SENSOR_ACTUATOR_INVENTORY_2026-04-22.md`
- `docs/runtime_evidence/2026-04-22/aeb_runtime_audit_snapshot_20260422_115423.md`

## Runtime snapshot, 2026-04-22 11:54

FACT
- Home Assistant runtime is reachable.
- Home Assistant version is `2026.4.3`.
- Recorder DB is active and growing after the 2026-04-21 incident:
  - `/homeassistant/home-assistant_v2.db`: `35.5M`
  - WAL active: `4.3M`
  - historical corrupt DB retained: `1.4G`
- Recent recorder log matches in the snapshot: `none`.
- `sensor.t_out_effective = 21.9`
- `binary_sensor.t_out_stale = off`
- `sensor.t_in_med = 21.4`
- `sensor.cm_system_mode_suggested = VENT_BASE`
- `switch.heating_master = off`
- `binary_sensor.vmc_is_running_proxy = on`
- `sensor.vmc_active_speed_proxy = 1`
- `switch.ac_giorno = unknown`
- `switch.ac_notte = unknown`
- `climate.ac_giorno = cool`
- `climate.ac_notte = fan_only`
- `input_boolean.cm_ac_branch_powered = off`
- `sensor.cm_ac_branch_advice = off_in_seasonal_rest`
- `input_boolean.cm_mirai_branch_powered = on`
- `sensor.cm_mirai_branch_advice = season_ready`
- `binary_sensor.cm_modbus_mirai_ready = on`
- `binary_sensor.cm_modbus_ehw_ready = on`
- `sensor.mirai_machine_state = OFF`
- `binary_sensor.mirai_machine_running = off`
- `sensor.mirai_power_w = 5.1`
- `sensor.ehw_tank_top = 42.6`
- `sensor.ehw_tank_bottom = 45.6`
- `binary_sensor.ehw_running = on`
- `sensor.ehw_power_w = 0.0`
- `input_boolean.policy_vacation_mode = off`

## What is no longer the bottleneck

FACT
- Core ClimateOps authority baseline is closed.
- DHW/EHW writer path is closed for the conservative MVP live pass.
- `t_out_effective` fallback exists and is currently healthy.
- Recorder immediate recovery appears stable in the sampled window.
- Branch power semantics for AC/MIRAI exist and reduce false alarms when a branch is intentionally off.

DECISION
- Do not spend engineering time on broad refactors or dashboard cosmetics now.
- Do not start sensor purchases before closing the remaining high-ROI evidence gaps.

## What remains behind

### 1. Recorder-independent audit continuity

FACT
- The 2026-04-21 recorder incident made the five-day vacation window non decision-grade.
- A file-based AEB runtime snapshot now exists and worked on 2026-04-22.

IPOTESI (confidenza alta)
- The project needs a small daily evidence export for critical states, otherwise future audits remain over-dependent on recorder history.

DECISION
- Treat file-based snapshots as the immediate observability recovery path.
- Keep the corrupt DB until an explicit recovery/delete decision is made.

### 2. MIRAI runtime truth

FACT
- MIRAI branch is powered and Modbus readiness is `on`.
- Current runtime state is idle/OFF, with idle power around `5.1 W`.
- Step51 already defines the manual observed run window.

IPOTESI (confidenza alta)
- MIRAI runtime truth is still the highest-ROI blocker before any safe MIRAI AEB promotion.

DECISION
- Next operational closure item: run the Step51 observed MIRAI window when a human can force/observe the machine.
- Do not promote MIRAI as AEB-dispatchable until that evidence pack exists.

### 3. AC feedback and authority

FACT
- AC branch is intentionally powered off now.
- `switch.ac_giorno` and `switch.ac_notte` are `unknown`.
- `climate.ac_giorno` and `climate.ac_notte` still expose states.
- Several runtime consumers still depend on `switch.ac_*` for availability, counters, contracts or advisory decisions.

IPOTESI (confidenza alta)
- This is acceptable in seasonal rest, but it will become a high-impact issue before cooling season.

DECISION
- AC is not the immediate winter blocker, but it is the next warm-season blocker.
- Before enabling stronger AC orchestration, define an AC feedback model that survives `switch.ac_* = unknown`, ideally with energy feedback.

### 4. EHW state/power reconciliation

FACT
- `binary_sensor.ehw_running = on`
- `sensor.ehw_power_w = 0.0`
- EHW Modbus readiness is `on`.

IPOTESI (confidenza media)
- This may be a semantic mismatch between status bit and actual electrical activity, or a stale/derived status issue.

DECISION
- Add EHW running-vs-power reconciliation to the next runtime audit, but do not block MIRAI truth on it.

### 5. Sensor/field layer hardening

FACT
- T/RH, windows, CO2 and metering gaps are documented in the BMS audit and physical inventory.

IPOTESI (confidenza alta)
- Hardware ROI is real, but premature hardware choice before field topology would create churn.

DECISION
- Next design deliverable after MIRAI/observability work: RS485/field topology plan.

## ROI-ranked backlog

| rank | item | status | ROI reason | next action |
|---|---|---|---|---|
| 1 | Recorder-safe evidence snapshots | started | prevents future audit loss after DB incident | schedule or run daily/manual snapshot |
| 2 | MIRAI runtime truth closure | open | unlocks governed MIRAI/AEB path | execute Step51 observed run window |
| 3 | AC feedback/authority cleanup | open | prevents summer control ambiguity | design feedback model; do not rely only on `switch.ac_*` |
| 4 | EHW status/power reconciliation | open | protects DHW writer trust | compare status bits, power source and tank trend |
| 5 | RS485/field topology plan | open | prevents bad hardware purchases | document bus, gateway, slaves, cabling, termination |
| 6 | CO2 + window physical contacts | planned | highest sensor ROI after topology | choose after topology constraints are known |
| 7 | Solar gain calibration | open | useful, but not blocker for AEB load closure | wait for clean sunny-day evidence |

## Immediate sequence

1. FACT: recorder recovery is stable in the sample.
   DECISION: keep generating file-based snapshots while the new DB accumulates history.

2. FACT: Step51 MIRAI manual run plan is already defined.
   DECISION: execute that plan at the first controlled human-observable window.

3. FACT: AC switch entities are unknown but branch is powered off.
   DECISION: record this as acceptable seasonal-rest posture, not a current emergency.

4. FACT: EHW running/power is inconsistent in the sampled state.
   DECISION: add this to runtime audit checks, below MIRAI truth priority.

5. FACT: sensor purchases are not the current blocker.
   DECISION: produce `BMS_FIELD_LAYER_RS485_TOPOLOGY_PLAN_2026-04-22.md` before hardware selection.

## Go / No-Go

FACT
- Repo local write/push through normal Git is currently blocked by `.git-local/index.lock` and sandbox restrictions.
- Remote GitHub commits can be made through the connector when needed.

DECISION
- Runtime deploy: `NO-GO` for this step.
- Documentation/audit publication: `GO`.
- Next runtime operation: `GO only for read-only audit` until a human-controlled MIRAI run window is available.

## Final decision

DECISION
- Continue the project with this ROI order:
  1. file-based observability continuity
  2. MIRAI runtime truth evidence
  3. AC feedback/authority cleanup
  4. EHW state/power reconciliation
  5. RS485/field topology plan
  6. sensor replacement planning

DECISION
- Do not buy hardware yet.
- Do not expand automations yet.
- Do not promote MIRAI, AC, or multi-load dispatch until their feedback paths are trustworthy.
