# STEP81 - MIRAI Modbus-first runtime truth closure

Date: 2026-04-24
Scope: close MIRAI runtime truth using machine-state evidence from a real observed run, with Modbus-first semantics and power only as corroboration.

## FACT

- A real observed MIRAI run was captured after the post-fix threshold deploy.
- During the confirmed live run, the runtime exposed:
  - `sensor.mirai_machine_state = RUN`
  - `binary_sensor.mirai_machine_running = on`
  - `sensor.mirai_machine_running_source = MODBUS_ACTIVITY_BIT00`
  - `sensor.mirai_power_w_effective = 239.2 W`
  - `binary_sensor.mirai_status_word_bit_00 = on`
  - `binary_sensor.mirai_status_word_bit_01 = off`
  - `sensor.mirai_status_word_effective = 1`
  - `sensor.mirai_status_code_effective = 128`
  - `binary_sensor.mirai_pump_do4_running = on`
  - `binary_sensor.mirai_pump_candidate_running = on`
- An earlier live read in the same window also showed stronger power:
  - `sensor.mirai_power_w = 411.4 W`
  - `sensor.mirai_discovery_pump_do4_9007_raw = 1`
  - `sensor.mirai_discovery_target_9051_raw = 244`
  - `sensor.mirai_discovery_reference_9052_raw = 340`
  - `sensor.mirai_probe_temp_a_raw = 340`
  - `sensor.mirai_probe_temp_b_raw = 229`
  - `sensor.mirai_discovery_outlet_8987_raw = 221`
- The machine was also confirmed in run by human field observation.

## IPOTESI

- Confidenza alta: the correct machine-state truth for the current MIRAI profile is not `bit 01`, but the combination:
  - `status_word bit 00`
  - live machine run
  - corroborating power
  - corroborating pump output `9007`
- Confidenza alta: power should remain corroboration, not primary authority.
- Confidenza alta: the advisory layer was lagging only because of conservative `delay_on` timers, not because the machine state was ambiguous.

## DECISIONE

- MIRAI runtime truth is now `CLOSED`.
- Runtime truth semantics are closed as:
  - `Modbus-first`
  - `bit 00 activity + live run + pump corroboration`
  - power as physical corroboration
- `bit 01` is definitively not the primary RUN truth for this installation.

## Advisory alignment

FACT
- During the confirmed live run, the advisory layer still reported:
  - `sensor.mirai_runtime_truth_reason = no_run_window`
  - `sensor.mirai_runtime_truth_level = idle`
  - `binary_sensor.mirai_runtime_truth_run_window_candidate = off`
  - `binary_sensor.mirai_runtime_truth_coherent_run = off`
- The missing promotion was caused by long `delay_on` settings.

DECISIONE
- Shorten advisory delays:
  - `run_window_candidate`: `5m -> 1m`
  - `pump_corroborated`: `2m -> 1m`
  - `coherent_run`: `3m -> 1m`
- This does not change physical truth semantics; it only removes avoidable observer lag.

## Resulting architecture rule

DECISIONE
- Treat MIRAI truth in this order:
  1. machine-state Modbus semantics actually validated on this installation
  2. pump/circulator corroboration (`9007`)
  3. power corroboration
- Do not use power as the primary source of truth.

## Final decision

DECISIONE
- `MIRAI runtime truth`: `CLOSED`
- The project can now remove MIRAI truth from the top blocker list and move to the next MVP gap.
