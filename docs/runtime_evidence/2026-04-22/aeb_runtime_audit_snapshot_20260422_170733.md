# AEB Runtime Audit Snapshot (2026-04-22)

- timestamp: 2026-04-22 17:07:33 +02:00
- scope: aeb runtime audit snapshot
- raw_json: `aeb_runtime_audit_snapshot_20260422_170733.json`

## Vacation / presence policy
- `input_boolean.policy_vacation_mode`: off
- `binary_sensor.cm_policy_vacation_mode`: off
- `binary_sensor.policy_allow_ac`: on
- `binary_sensor.policy_allow_vmc_boost`: on
- `binary_sensor.policy_allow_shift_load`: on
- `binary_sensor.climateops_noncritical_loads_allowed`: on

## Shading feedback
- `input_boolean.envelope_giorno_shade_applied`: off
- `input_boolean.envelope_notte1_shade_applied`: off
- `input_boolean.envelope_notte2_shade_applied`: off
- `binary_sensor.envelope_any_shade_applied`: off
- `sensor.envelope_shade_applied_rooms`: none

## Envelope
- `sensor.envelope_recommended_action`: prepare_night_flush
- `sensor.envelope_worst_room_name`: giorno
- `sensor.envelope_house_night_flush_potential`: low
- `sensor.envelope_house_passive_gain_state`: idle
- `sensor.t_in_med`: 22.02
- `sensor.t_in_notte2`: 22.2
- `sensor.t_in_bagno`: 21.8
- `sensor.t_out_effective`: 18.8

## AEB / ClimateOps
- `sensor.climateops_hierarchy_reason`: PRIORITY_HEAT
- `sensor.climateops_aeb_mvp_reason`: disabled
- `sensor.climateops_aeb_mvp_mode`: disabled
- `binary_sensor.climateops_aeb_mvp_permitted`: off
- `switch.heating_master`: on
- `binary_sensor.vmc_is_running_proxy`: on
- `sensor.vmc_active_speed_proxy`: 1
- `switch.ac_giorno`: unknown
- `switch.ac_notte`: unknown
- `climate.ac_giorno`: cool
- `climate.ac_notte`: fan_only

## Branch feedback
- `input_boolean.cm_ac_branch_powered`: off
- `sensor.cm_ac_branch_advice`: off_in_seasonal_rest
- `input_boolean.cm_mirai_branch_powered`: on
- `sensor.cm_mirai_branch_advice`: ready_now
- `binary_sensor.cm_modbus_mirai_ready`: on
- `binary_sensor.cm_modbus_ehw_ready`: on

## MIRAI / EHW truth
- `sensor.mirai_machine_state`: OFF
- `binary_sensor.mirai_machine_running`: off
- `sensor.mirai_power_w`: 5.1
- `sensor.ehw_tank_top`: 43.2
- `sensor.ehw_tank_bottom`: 45.6
- `binary_sensor.ehw_running`: on
- `sensor.ehw_power_w`: 0.0

## Recorder health
### DB files
```text
-rw-r--r--    1 root     root       49.1M Apr 22 17:07 /homeassistant/home-assistant_v2.db
-rw-r--r--    1 root     root       32.0K Apr 22 17:07 /homeassistant/home-assistant_v2.db-shm
-rw-r--r--    1 root     root        4.6M Apr 22 17:07 /homeassistant/home-assistant_v2.db-wal
-rw-r--r--    1 root     root        1.4G Apr 21 22:44 /homeassistant/home-assistant_v2.db.corrupt.2026-04-21T20:44:59.837397+00:00
```

### Recent recorder log matches
```text
none
```
