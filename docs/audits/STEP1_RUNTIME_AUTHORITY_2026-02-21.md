# Step 1 — Runtime Authority Audit (Legacy vs ClimateOps)
Date: 2026-02-21
Scope: Repository static audit (read-only), no live HA runtime introspection

## Goal
Identify who currently controls climate actuators and whether authority is unambiguous.

## Evidence Basis
- `configuration.yaml`
- `packages/climate_heating.yaml`
- `packages/climate_ventilation.yaml`
- `packages/climate_ac_mapping.yaml`
- `packages/climate_ac_logic.yaml`
- `packages/climateops/actuators/system_actuator.yaml`
- `packages/climate_contracts.yaml`
- `packages/cm_naming_bridge.yaml`
- `packages/migration_boundary.yaml`
- `docs/climateops/ENTRYPOINTS.md`

---

## 1) Loading model

### FACT
- Home Assistant package entrypoint is `homeassistant: packages: !include_dir_named packages` (`configuration.yaml:8`).
- `packages/climateops.yaml` is comment-only and does not include subfiles itself.
- Docs state all YAML under `packages/` are automatically loaded, including `packages/climateops/` (`docs/climateops/ENTRYPOINTS.md:4`).

### UNKNOWN
- In this environment, without runtime state/API inspection, we cannot prove whether HA is effectively loading subfolder YAML (`packages/climateops/**/*.yaml`) at runtime.

---

## 2) Authority truth table by actuator

| Actuator | Potential writers found | Gate/condition path | Current authority status |
|---|---|---|---|
| `switch.heating_master` | `automation.climateops_system_actuate` (`switch.turn_on/off`) | Requires `cm_contract_actuators_defined=on`, `cm_contract_actuators_ready=on`, `cm_contract_missing_entities=OK` | FACT: ClimateOps automation can command it; UNKNOWN: whether that automation is loaded/executing live |
| `switch.4_ch_interrutore_3` | Template switch driver in `climate_heating.yaml` (`switch.heating_master` turn_on/off maps to inverted relay) | No standalone scheduler in file; acts as downstream physical relay | FACT: Driven through `switch.heating_master`; UNKNOWN: upstream runtime writer |
| `switch.vmc_vel_0..3` | `automation.climateops_system_actuate` writes `vel_1/vel_3` and clears others | Same contract gate as above | FACT: ClimateOps can command VMC relays; FACT: no legacy automation in `climate_ventilation.yaml` directly switches VMC relays |
| `switch.ac_giorno` | `script.ac_giorno_apply` in `climate_ac_mapping.yaml` (turn_on + hw press) and calls from ClimateOps actuator automation | ClimateOps contract gate + policy condition for COOL_DAY | FACT: direct switching path exists through script; UNKNOWN: who triggers it live outside observed calls |
| `switch.ac_notte` | `script.ac_notte_apply` in `climate_ac_mapping.yaml` and calls from ClimateOps actuator automation | ClimateOps contract gate + policy condition for COOL_NIGHT | FACT: direct switching path exists through script; UNKNOWN: who triggers it live outside observed calls |

---

## 3) Legacy package authority check

### Heating (`packages/climate_heating.yaml`)
### FACT
- Contains reasoning/priority/locks and a template actuator abstraction (`switch.heating_master`).
- Only active automation in file is manual-timeout helper (`id: heating_manual_timeout`).
- No active automation in this file that toggles `switch.heating_master` based on `binary_sensor.heating_should_run`.

### UNKNOWN
- Whether external automations (outside this repo/runtime UI) use `binary_sensor.heating_should_run` to actuate.

### Ventilation (`packages/climate_ventilation.yaml`)
### FACT
- Contains priority/reason computation and KPIs.
- Active automations only update dashboard message and sync backup inputs.
- No active relay actuation (`switch.vmc_vel_*`) found in this legacy file.

### AC (`packages/climate_ac_logic.yaml` + `climate_ac_mapping.yaml`)
### FACT
- Active automations handle VMC block hook timeout and notifications.
- Legacy DRY/COOL control automations are commented out under “LEGACY AUTOMATIONS – disattivate”.
- Actuation scripts `ac_giorno_apply` / `ac_notte_apply` are active and callable.

### UNKNOWN
- Whether any external actor triggers `script.ac_send_command`, `script.ac_apply_targets`, or leaf apply scripts live.

---

## 4) ClimateOps authority check

### FACT
- `automation.climateops_system_actuate` is a single centralized writer for heating/VMC/AC script calls.
- It is now guarded by three contract conditions:
  - `binary_sensor.cm_contract_actuators_defined`
  - `binary_sensor.cm_contract_actuators_ready`
  - `sensor.cm_contract_missing_entities == OK`
- Contract reason visibility exists (`sensor.contract_actuators_reason`, bridged as `sensor.cm_contract_actuators_reason`).

### FACT
- Bootstrap force-cutover automation exists but is disabled (`packages/climate_bootstrap_cutover_temp.yaml:7`).

### UNKNOWN
- Whether ClimateOps automation is loaded and active in deployed runtime.
- Whether runtime mode source (`sensor.cm_system_mode_suggested`) is receiving expected values continuously.

---

## 5) Conflict and overlap assessment

### FACT
- No second active automation writer was found in legacy climate files for:
  - `switch.heating_master`
  - `switch.vmc_vel_*`
  - direct AC switch toggling by periodic control loops
- AC leaf scripts are shared actuation endpoints and can be invoked by multiple callers if present.

### UNKNOWN
- Hidden/external writers (UI automations, Node-RED, AppDaemon, external integrations) are not inspectable from repository-only audit.

---

## 6) STEP 1 outcome

### FACT
- Static authority model is currently **centralized around `climateops_system_actuate`** for direct cross-system actuation, with legacy modules mostly providing decision telemetry and helper abstractions.
- Contract gate is now strict enough to prevent obvious false-green activation when required actuators are missing/unavailable.

### UNKNOWN
- Final runtime authority cannot be closed to 100% FACT without live HA runtime evidence (automation trace/logbook/state history).

## Runtime authority status
- **PARTIALLY RESOLVED (static FACT, runtime UNKNOWN)**
