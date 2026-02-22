# Step 2 — Runtime Evidence Closure
Date: 2026-02-21
Scope: Runtime evidence from HA SSH outputs (entity registry and restore state), read-only analysis

## Objective
Close Step 1 runtime UNKNOWNs where evidence is now available.

## Evidence received
- `/homeassistant/.storage/core.entity_registry` extracts for climate actuators
- `/homeassistant/.storage/core.restore_state` extract for `switch.heating_master`
- Prior Step 2 runtime list (`entities_focus.txt`) showing ClimateOps entities at runtime

## A) ClimateOps load status

### FACT
- `automation.climateops_system_actuate` exists at runtime.
- Multiple `climateops_*` entities exist at runtime (`input_*`, `sensor.*`, `binary_sensor.*`).
- `cm_*` bridge entities exist at runtime (`binary_sensor.cm_contract_*`, `sensor.cm_system_mode_suggested`).

### Conclusion
- Step 1 UNKNOWN "is `packages/climateops/**` loaded?" is now CLOSED -> FACT: loaded.

## B) Actuator provenance (runtime entity registry)

### FACT
- `switch.vmc_vel_0` -> platform `sonoff`
- `switch.vmc_vel_1` -> platform `sonoff`
- `switch.vmc_vel_2` -> platform `sonoff`
- `switch.vmc_vel_3` -> platform `sonoff`
- `switch.ac_giorno` -> platform `switchbot_cloud`
- `switch.ac_notte` -> platform `switchbot_cloud`
- `switch.heating_master` -> platform `template` (`original_name`: "Riscaldamento comando")

### Interpretation (FACT-based)
- VMC and AC actuators are integration-backed hardware entities.
- Heating master is a template-layer actuator abstraction, consistent with repository model.

## C) Runtime state sample

### FACT
- `switch.heating_master` appears in `core.restore_state` with state `on` and no user context (`user_id: null`) in the provided sample.

### UNKNOWN
- This sample alone does not identify which automation/script caused the transition.

## D) Authority closure status

### CLOSED as FACT
1. ClimateOps package family is loaded in runtime.
2. `automation.climateops_system_actuate` is present in runtime entity graph.
3. Actuator origin/platform mapping is known (Sonoff / SwitchBot Cloud / Template).

### STILL UNKNOWN
1. Event-level writer attribution per transition (which specific automation/script wrote each actuator change over time).
2. Presence of additional external writers not visible in current extracts (requires automation trace/logbook/history evidence).

## E) Updated risk note

- The highest architecture UNKNOWN from Step 1 (ClimateOps runtime presence) is resolved.
- Residual runtime risk is now narrowed to writer-attribution conflicts, not loading ambiguity.

## Step 2 status
- PARTIALLY COMPLETE (major runtime UNKNOWN closed; writer attribution remains open pending traces/logbook history)
