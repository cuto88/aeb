# MIRAI Modbus Mapping

Documento canonico per il mapping Modbus MIRAI usato nel runtime Home Assistant.

Scopo:
- elencare i registri attivi del profilo stabile;
- esplicitare la semantica oggi assunta dal runtime;
- distinguere cio' che e' `confermato`, `candidato`, `smentito`;
- separare il mapping fisico dei registri dalla diagnostica di run.

## Sorgenti autoritative

- Transport Modbus: [mirai_modbus.yaml](C:\2_OPS\aeb\packages\mirai_modbus.yaml)
- Template runtime: [mirai_templates.yaml](C:\2_OPS\aeb\packages\mirai_templates.yaml)
- Advisory runtime truth: [mirai_runtime_truth_advisory.yaml](C:\2_OPS\aeb\packages\mirai_runtime_truth_advisory.yaml)
- Overview sensori: [README_sensori_mirai.md](C:\2_OPS\aeb\docs\logic\core\README_sensori_mirai.md)

## Profilo stabile attuale

- Hub: `mirai`
- Protocollo: Modbus TCP
- Slave runtime valido: `1`
- Profilo operativo: `status-only unit1`
- Polling stabile: registri minimi e probe selezionati, senza riaprire il profilo storico rumoroso

## Mapping registri attivi

| Registro | Entity runtime | Tipo | Semantica corrente | Stato |
|---|---|---|---|---|
| `1003` | `sensor.mirai_u1_status_word_raw`, `sensor.mirai_status_word_raw`, `sensor.mirai_status_word_effective` | `uint16` | status word principale macchina | confermato |
| `1208` | `sensor.mirai_u1_status_code_raw`, `sensor.mirai_status_code_raw`, `sensor.mirai_status_code_effective` | `uint16` | status code macchina | confermato |
| `1209` | `sensor.mirai_u1_fault_code_raw`, `sensor.mirai_fault_code_raw`, `sensor.mirai_fault_code_effective` | `uint16` | fault code macchina | confermato |
| `4000` | `sensor.mirai_probe_temp_a_raw`, `sensor.mirai_probe_temp_a_c` | `uint16` | probe temperatura A scalata `x10` | candidato forte |
| `9050` | `sensor.mirai_probe_temp_a_dup_9050_raw` | `uint16` | duplicato coerente di `4000` | candidato forte |
| `9086` | `sensor.mirai_probe_temp_a_dup_9086_raw` | `uint16` | duplicato coerente di `4000` | candidato forte |
| `3548` | `sensor.mirai_probe_temp_b_raw`, `sensor.mirai_probe_temp_b_c` | `uint16` | probe temperatura B scalata `x10` | candidato forte |
| `9087` | `sensor.mirai_probe_temp_b_dup_9087_raw` | `uint16` | duplicato coerente di `3548` | candidato forte |
| `3515` | `sensor.mirai_probe_temp_outdoor_raw`, `sensor.mirai_probe_temp_outdoor_c` | `uint16` | candidato outdoor | smentito come vera esterna |
| `1015` | `sensor.mirai_probe_counter_1015_raw` | `uint16` | contatore/probe diagnostico | candidato debole |
| `3547` | `sensor.mirai_probe_state_3547_raw`, `binary_sensor.mirai_pump_candidate_running` | `uint16` | probe di stato legato alla pompa/runtime | candidato medio |

## Status word 1003

### Bit osservati

| Bit | Entity | Semantica storica | Evidenza corrente | Stato |
|---|---|---|---|---|
| `bit 00` | `binary_sensor.mirai_status_word_bit_00` | non formalizzata storicamente | durante il run reale resta `on`; a macchina ferma puo' restare `on` con basso assorbimento | attivita' Modbus macchina, non run autonomo |
| `bit 01` | `binary_sensor.mirai_status_word_bit_01` | usato storicamente come run flag principale | nel run reale osservato il `bit 01` e' rimasto `off` | non affidabile come unico flag RUN |

### Conclusione operativa

- `bit 01` non deve piu' essere trattato come unica verita' di `RUN`.
- `bit 00` e' un segnale utile di attivita' Modbus macchina.
- `bit 00` da solo non basta a dichiarare `RUN`, perche' puo' restare alto anche a macchina quasi ferma.
- Il runtime attuale considera `bit 00` valido solo insieme a potenza reale.

## Run detection attuale

### Entita' base

- `binary_sensor.mirai_machine_running_by_power`
  - base potenza;
  - soglia helper: `input_number.mirai_running_power_on_w`;
  - oggi serve come conferma fisica primaria del run.

- `binary_sensor.mirai_machine_running`
  - vero se:
    - `bit 01 = on`, oppure
    - `bit 00 = on` e c'e' potenza reale, oppure
    - il fallback a potenza e' `on`.

- `sensor.mirai_machine_running_source`
  - `MODBUS_STATUS`: `bit 01` attivo;
  - `MODBUS_ACTIVITY_BIT00`: `bit 00` attivo con potenza reale;
  - `POWER_OVERRIDE`: run visto solo da potenza;
  - `MODBUS_IDLE`: link Modbus vivo ma nessun segnale run valido;
  - `POWER_FALLBACK`: fallback senza Modbus affidabile.

### Runtime truth multi-livello

| Livello | Significato |
|---|---|
| `idle` | nessuna finestra run valida |
| `power_only_run` | run visto solo dai consumi |
| `power_plus_modbus` | run visto da consumi + attivita' Modbus coerente |
| `fully_corroborated_run` | run confermato da consumi + Modbus + pompa |

## Evidenza runtime del 2026-04-08

Finestra manuale controllata con setpoint alzato per forzare un run reale:

- richiesta heating coerente;
- ramo MIRAI coerente;
- macchina realmente partita con potenza oltre soglia;
- `status_word_effective = 1`;
- `status_bits_on = bit 00`;
- `bit 01 = off`;
- livello runtime truth corretto: `power_plus_modbus`;
- corroborazione pompa rimasta `off`.

Conclusione:
- il remap semantico su `bit 00` e' giustificato;
- la corroborazione pompa resta ancora aperta;
- il mapping `bit 01 == RUN` e' da considerare superato come assunzione unica.

## Elementi ancora non chiusi

| Oggetto | Stato | Nota |
|---|---|---|
| vera sonda outdoor MIRAI | aperto | `3515` non valida come esterna reale |
| semantica piena `3547` | aperto | utile come pump candidate, non ancora chiusa |
| significato vendor ufficiale di `bit 00` e `bit 01` | aperto | manca conferma documentale vendor numerica |

## Regole operative

- Non promuovere nuovi registri nel profilo stabile senza evidenza runtime.
- Non usare `bit 01` come unico criterio di `RUN`.
- Non usare `bit 00` come `RUN` puro senza potenza reale.
- Trattare `3515` come probe non validato, non come verita' meteo.

## Riferimenti

- [GOVERNANCE_MIRAI.md](C:\2_OPS\aeb\docs\GOVERNANCE_MIRAI.md)
- [STEP50_MIRAI_RUNTIME_TRUTH_ADVISORY_2026-04-07.md](C:\2_OPS\aeb\docs\audits\STEP50_MIRAI_RUNTIME_TRUTH_ADVISORY_2026-04-07.md)
- [STEP51_MIRAI_MANUAL_RUN_WINDOW_PLAN_2026-04-07.md](C:\2_OPS\aeb\docs\audits\STEP51_MIRAI_MANUAL_RUN_WINDOW_PLAN_2026-04-07.md)
- [STEP53_MIRAI_BRANCH_POWER_AND_SOLAR_GAIN_CLOSURE_2026-04-07.md](C:\2_OPS\aeb\docs\audits\STEP53_MIRAI_BRANCH_POWER_AND_SOLAR_GAIN_CLOSURE_2026-04-07.md)
