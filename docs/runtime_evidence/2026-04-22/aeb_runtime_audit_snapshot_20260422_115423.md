# AEB Runtime Audit Snapshot (2026-04-22)

- timestamp: 2026-04-22 11:54:23 +02:00
- scope: aeb runtime audit snapshot
- raw_json: `aeb_runtime_audit_snapshot_20260422_115423.json`

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
- `sensor.envelope_recommended_action`: keep_closed
- `sensor.envelope_worst_room_name`: bagno
- `sensor.envelope_house_night_flush_potential`: none
- `sensor.envelope_house_passive_gain_state`: idle
- `sensor.t_in_med`: 21.4
- `sensor.t_in_notte2`: 21.6
- `sensor.t_in_bagno`: 21.8
- `sensor.t_out_effective`: 21.9

## AEB / ClimateOps
- `sensor.climateops_hierarchy_reason`: PRIORITY_VENT_BASE
- `sensor.climateops_aeb_mvp_reason`: disabled
- `sensor.climateops_aeb_mvp_mode`: disabled
- `binary_sensor.climateops_aeb_mvp_permitted`: off
- `switch.heating_master`: off
- `switch.ac_giorno`: unknown
- `switch.ac_notte`: unknown

## Recorder health
### DB files
```text
-rw-r--r--    1 root     root       35.5M Apr 22 11:52 /homeassistant/home-assistant_v2.db
-rw-r--r--    1 root     root       32.0K Apr 22 11:54 /homeassistant/home-assistant_v2.db-shm
-rw-r--r--    1 root     root        4.3M Apr 22 11:54 /homeassistant/home-assistant_v2.db-wal
-rw-r--r--    1 root     root        1.4G Apr 21 22:44 /homeassistant/home-assistant_v2.db.corrupt.2026-04-21T20:44:59.837397+00:00
```

### Recent recorder log matches
```text
none
```
