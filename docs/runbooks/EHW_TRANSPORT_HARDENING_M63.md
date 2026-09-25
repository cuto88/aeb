# M63 EHW transport hardening runbook

Status: prepared, not executed  
AEB ID: `AEB-DHW-001`

## Scope

Deploy only:

- `packages/ehw_modbus_transport.yaml`
- `packages/ehw_modbus.yaml`

Do not deploy or enable `packages/ehw_shadow_policy.yaml`. Do not modify
`packages/climateops_dhw_writer.yaml`, secrets, HVAC, VMC, MIRAI or SDM120.

## Preconditions

1. Explicit runtime deployment authorization.
2. Clean reviewed source commit containing only the approved M63 changes.
3. `input_boolean.climateops_dhw_write_enable = off`.
4. `input_boolean.climateops_dhw_dry_run = on`.
5. Backup directory outside the two target files, timestamped and verified.
6. Baseline REST snapshot for raw 2020, 2021, 1104 and writer gates.

## Deployment procedure

1. Copy the two current runtime files into the timestamped backup directory.
2. Verify backup hashes and record source commit/hash.
3. Copy only the two approved package files.
4. Run the Home Assistant configuration check.
5. On any check failure, restore both backup files and stop.
6. Perform one controlled Home Assistant restart only if separately authorized.
7. Confirm API recovery and verify writer gates remain dry-run/off.

## Post-deploy observation

After a restart, wait for the Home Assistant container and API to recover
before evaluating entity state. Allow a stabilization grace period of at
least 300 seconds, then observe for a total of at least 15 minutes. During
grace, readiness off and derived entities unavailable are expected startup
states; after grace they are failures if the required raw sources are fresh.

Observe live REST `last_reported` for at least 15 minutes:

- `sensor.ehw_t02_raw_b` — address 2020;
- `sensor.ehw_t03_raw_b` — address 2021;
- `sensor.ehw_setpoint_1104_raw_b` — address 1104;
- `binary_sensor.cm_modbus_ehw_ready`;
- `binary_sensor.ehw_tank_top_raw_fresh`;
- `binary_sensor.ehw_tank_bottom_raw_fresh`;
- `binary_sensor.ehw_setpoint_raw_fresh`;
- `sensor.ehw_tank_top`;
- `sensor.ehw_tank_bottom`;
- `sensor.ehw_setpoint`;
- `sensor.sdm120_ch2_active_power_w_raw` as external control.

PASS requires all three EHW raw sources to advance at least twice after
stabilization, no interval greater than 240 seconds, readiness equal to the
AND of the three age-aware freshness entities, derived values available, zero
new Modbus errors and zero EHW writes. This transport PASS does not authorize
shadow deployment.

If any freshness or derived entity remains `unknown`/`unavailable` after the
stabilization grace period, or a required raw source does not advance, fail the
gate and roll back. Do not roll back on the first post-restart sample alone.

## Rollback triggers

Rollback immediately if any required raw source:

- is missing or unavailable;
- does not advance within 240 seconds;
- produces an implausible value;
- causes entity-id/registry regression;
- is accompanied by new Modbus errors;
- changes writer gates or produces any EHW write.

## Rollback

1. Restore both package files from the verified backup.
2. Run the Home Assistant configuration check.
3. Perform one controlled restart only if authorized and required.
4. Verify API recovery, writer dry-run/off and restoration of prior entities.
5. Record the failed gate and retain `SHADOW DEPLOYMENT: BLOCKED`.
