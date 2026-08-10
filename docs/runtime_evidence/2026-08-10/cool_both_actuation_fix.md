Exit code: 0
Wall time: 0.8 seconds
Output:
# COOL_BOTH actuation fix — 2026-08-10

## Incident

The cooling dashboard requested `COOL_BOTH`, but neither split was started by
the automatic writer. A later manual attempt resulted in only one split being
active.

## Root cause

The loaded `automation.climateops_system_actuate` configuration required the
aggregate `binary_sensor.cm_contract_actuators_ready` contract to be `on`.
That contract was `off` because an unrelated actuator branch was not ready, so
the complete automation stopped before evaluating the available AC actuators.

Thirty consecutive saved traces between 17:48 and 18:46 CEST ended at
`condition/1/entity_id/0` with `script_execution: failed_conditions`.

## Correction

The aggregate readiness condition was replaced by a mode-aware condition:

- retain the aggregate readiness contract when it is healthy;
- permit `COOL_DAY` when the day command entity is available;
- permit `COOL_NIGHT` when the night command entity is available;
- permit `COOL_BOTH` only when both command entities are available.

This prevents a VMC, heating, or other unrelated actuator fault from blocking
a valid cooling request while preserving fail-closed behavior for the AC zones
actually requested.

## Validation and deployment

- Operating machine: Codex workspace `C:\2_OPS\aeb`.
- Verified target: `mercurio-edge`, `192.168.178.110`, Home Assistant Core
  container `homeassistant`.
- Runtime configuration: `/config`, bind-mounted from
  `/opt/data/homeassistant`.
- Access mode: LAN and SSH to `dscomparin@192.168.178.110:22`.
- Legacy machine `192.168.178.84:2222`: not accessed or modified.
- Home Assistant native config check:
  `python -m homeassistant --script check_config -c /config` — passed.
- Deployment: container `homeassistant` restarted successfully to load the
  already-present surgical runtime correction.
- Post-deploy evidence: the 19:16 periodic trace loaded the template condition
  and completed with `script_execution: finished` and `last_step: action/8`.
- Post-deploy requested mode at that trace: `COOL_DAY`; therefore the night
  split was not forced outside the automatic request.
- Repository CI gate: functional gates passed; the wrapper stopped because
  `yamllint` was not installed on the operating machine. The runtime-native
  Home Assistant configuration validation passed.

## Runtime changes

No broad package deployment was performed. The runtime file already contained
the surgical condition change; the container restart made it active. The
repository copy was aligned to the same condition.

## Controlled COOL_BOTH test and follow-up

A controlled observation was run after publication of the initial readiness
fix. No policy, setpoint, or minimum-cycle lock was bypassed.

- At 19:33 CEST both comfort requests were active and
  `sensor.climateops_hierarchy_mode` was `COOL_BOTH`.
- `sensor.cm_system_mode_suggested` nevertheless remained `COOL_DAY`.
- Both AC switches were `off` and their 20-minute minimum-OFF locks were still
  active after the bootstrap established an OFF baseline.
- At 19:59 the same hierarchy/facade mismatch recurred after restart; the AC
  entities passed through `unknown` and the bootstrap restored them to `off`.
- At 20:04 the comfort request naturally returned to `IDLE`, so the test did
  not force both units outside the active policy request.

This exposed a second, independent race in the facade propagation. The final
actuator correction therefore reads `sensor.climateops_hierarchy_mode`
directly whenever `binary_sensor.contract_hierarchy_mode_ready` is `on`, with
`sensor.cm_system_mode_suggested` retained only as fallback. The same canonical
mode selection is used by the AC writer-authority enforcer and by the
mode-aware readiness gate.

The temporary probe package was removed. The final runtime configuration
passed the native Home Assistant config check and the `homeassistant` container
was restarted to load the definitive actuator configuration. A physical
both-units-ON result was not claimed because the request returned to `IDLE`
before the minimum-OFF/bootstrap window allowed a policy-compliant actuation.

