# SOT Entities — canonical map (cm_*)

## Purpose
`cm_*` è il layer canonicale per le entità ClimateOps. Il naming legacy resta attivo per compatibilità fino a cutover completo.

## Canonical naming rules
- `cm_contract_*` (integrità/health)
- `cm_policy_*` (arbiter/policy)
- `cm_driver_*` (proxy hw)
- `cm_system_*` (strategy/system)

| ROLE | CANONICAL (cm_*) | LEGACY SOURCE | NOTES |
| --- | --- | --- | --- |
| CONTRACT | `sensor.cm_contract_missing_entities` | `sensor.contract_missing_entities` | Mirror testo `OK`/lista missing |
| CONTRACT | `binary_sensor.cm_contract_actuators_defined` | `binary_sensor.contract_actuators_defined` | Alias 1:1 |
| CONTRACT | `binary_sensor.cm_contract_surplus_ready` | `binary_sensor.contract_surplus_ok_ready` | Bridge naming |
| POLICY | `binary_sensor.cm_policy_allow_ac` | `binary_sensor.policy_allow_ac` | Alias 1:1 |
| POLICY | `binary_sensor.cm_policy_allow_vmc_boost` | `binary_sensor.policy_allow_vmc_boost` | Alias 1:1 |
| POLICY | `binary_sensor.cm_policy_surplus_ok` | `binary_sensor.policy_surplus_ok` | Alias 1:1 |
| POLICY | `sensor.cm_policy_reason` | `sensor.policy_arbiter_reason` | Reason policy principale (arbiter) |
| DRIVER | `binary_sensor.cm_driver_heating_is_on` | `binary_sensor.climateops_heating_master_is_on` | Proxy hardware già presente |
| DRIVER | `binary_sensor.cm_driver_vmc_is_running` | `binary_sensor.climateops_vmc_is_running` | Proxy hardware già presente |
| DRIVER | `binary_sensor.cm_driver_ac_giorno_is_on` | `binary_sensor.climateops_ac_giorno_is_on` | Proxy hardware già presente |
| DRIVER | `binary_sensor.cm_driver_ac_notte_is_on` | `binary_sensor.climateops_ac_notte_is_on` | Proxy hardware già presente |
| SYSTEM | `sensor.cm_system_mode_suggested` | `sensor.arbiter_suggested_mode` | Suggested mode ClimateOps |
| SYSTEM | `sensor.cm_system_reason` | `sensor.arbiter_suggested_reason` | Suggested reason ClimateOps |

## System Actuation
- Automazione attuativa unica: `automation.climateops_system_actuate`.
- Fonte mode VMC: `sensor.vmc_vel_target` -> `sensor.cm_system_mode_suggested`.

## EHW
- Package unico EHW Modbus: `packages/ehw_modbus.yaml` (flattened, non cartella).
