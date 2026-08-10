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


