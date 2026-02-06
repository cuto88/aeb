# SOT Entities — Step 4 naming (cm_*)

Tabella di riferimento per il ciclo di migrazione Step 4:
- **canonical** = nuovo naming funzionale `cm_*`
- **legacy source** = entità sorgente attuale (bridge/alias)
- legacy resta attivo in questo ciclo per evitare breaking hard

| Ruolo | Canonical (`cm_*`) | Legacy source | Note |
|---|---|---|---|
| CONTRACT | `binary_sensor.cm_contract_actuators_defined` | `binary_sensor.contract_actuators_defined` | Alias 1:1 |
| CONTRACT | `sensor.cm_contract_missing_entities` | `sensor.contract_missing_entities` | Mirror testo `OK`/lista missing |
| CONTRACT | `binary_sensor.cm_contract_surplus_ready` | `binary_sensor.contract_surplus_ok_ready` | Bridge naming |
| POLICY | `binary_sensor.cm_policy_allow_ac` | `binary_sensor.policy_allow_ac` | Alias 1:1 |
| POLICY | `binary_sensor.cm_policy_allow_vmc_boost` | `binary_sensor.policy_allow_vmc_boost` | Alias 1:1 |
| POLICY | `binary_sensor.cm_policy_surplus_ok` | `binary_sensor.policy_surplus_ok` | Alias 1:1 |
| POLICY | `sensor.cm_policy_reason` | `sensor.policy_arbiter_reason` | Reason policy principale (arbiter) |
| DRIVER | `binary_sensor.cm_driver_heating_is_on` | `binary_sensor.climateops_heating_master_is_on` | Proxy hardware già presente |
| DRIVER | `binary_sensor.cm_driver_vmc_is_running` | `binary_sensor.climateops_vmc_is_running` | Proxy hardware già presente |
| DRIVER | `binary_sensor.cm_driver_ac_giorno_is_on` | `binary_sensor.climateops_ac_giorno_is_on` | Proxy hardware già presente |
| DRIVER | `binary_sensor.cm_driver_ac_notte_is_on` | `binary_sensor.climateops_ac_notte_is_on` | Proxy hardware già presente |
| STRATEGY/SYSTEM | `sensor.cm_system_mode_suggested` | `sensor.arbiter_suggested_mode` | Suggested mode ClimateOps |
| STRATEGY/SYSTEM | `sensor.cm_system_reason` | `sensor.arbiter_suggested_reason` | Suggested reason ClimateOps |

## Gate di naming (Step 4)

Nuove regole introdotte:
1. Le nuove entità Step 4 devono usare prefisso `cm_` (nome e `unique_id`).
2. I `unique_id` non devono essere duplicati nel repository YAML.

Implementazione gate: `ops/gate_entity_naming.ps1`.
