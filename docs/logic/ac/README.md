# AC — Climatizzazione split (DRY/COOL)
> Logica AC suddivisa in **mapping/control** (`climate_ac_mapping.yaml`: helper, slider, script IR) e **logica** (`climate_ac_logic.yaml`: priorità, hook, automazioni).

## Titolo
AC — split (dry/cool) con lock anti-ciclo e coordinamento VMC.

## Obiettivo
- Garantire comfort estivo privilegiando la deumidifica (DRY) prima del raffrescamento (COOL) e rispettando blocchi notturni 23–07.
- Coordinare l’AC con la VMC per evitare condensa/contro-bilanciamento e applicare lock anti-ciclo sugli split giorno/notte.

## Entrypoints
- YAML: `packages/climate_ac_mapping.yaml`, `packages/climate_ac_logic.yaml`.
- Lovelace tecnica: `lovelace/climate_ac_plancia.yaml` (con fallback `lovelace/climate_ac_plancia_v2.yaml`).
- Entrypoint utente corrente: `lovelace/climate_casa_unified_plancia.yaml`.

## KPI / Entità principali
### Mappa priorità
| Priorità | KPI principali | Azione / logica |
| --- | --- | --- |
| **P0_failsafe** | Sensori T/UR interni o esterni invalidi | Spegne gli split e segnala motivo failsafe su `sensor.ac_reason`. |
| **P1_block_vmc** | `binary_sensor.ac_block_by_vmc` (freecooling o ΔAH favorevole esterno) | Impedisce COOL/DRY mentre la VMC richiede blocco; mantiene stato OFF salvo manuale. |
| **P2_dry** | UR stanza sopra `input_number.ac_ur_high` o ΔAH favorevole | Attiva DRY con richiesta `hook_ac_request_vmc_low`; rispetta min_on/min_off e fascia oraria. |
| **P3_cool** | `sensor.t_in_*` sopra `input_number.ac_t_cool_on` + isteresi | Attiva COOL (giorno/notte separati) se fascia oraria consentita e blocco VMC assente; lock min_on/min_off applicati. |
| **manual** | `input_boolean.ac_manual` + `input_select.ac_manual_mode` | Forza modalità selezionata ignorando fasce, ma rispetta lock e scade con `timer.ac_manual_timeout`. |
| **idle** | Nessuna priorità attiva | Split spenti, monitoraggio continuo di T/UR e blocchi. |

### KPI e sensori chiave
- Temperature/UR: `sensor.t_in_giorno`, `sensor.t_in_notte1`, `sensor.ur_in_giorno`, `sensor.ur_in_notte1`, `sensor.t_out`, `sensor.ur_out`.
- Stati logici: `binary_sensor.ac_need_dry`, `binary_sensor.ac_need_cool`, `binary_sensor.ac_fascia_ok`, `binary_sensor.ac_should_run`, `sensor.ac_priority`, `sensor.ac_reason`.
- Lock: `binary_sensor.ac_lock_min_on_ok`, `binary_sensor.ac_lock_min_off_ok`, contatori runtime e `input_number.ac_max_run`.

### Casi particolari / failsafe / lock
- Blocco fascia 23–07: `binary_sensor.ac_fascia_ok` evita avvii notturni salvo manual override.
- Lock min_on/min_off proteggono i compressori; max_run può spegnere dopo runtime prolungato se definito.
- Manuale può scavalcare blocco fascia ma non il failsafe sensori; termina col timer o con lo stesso toggle.

### Note operative
- Plancia `lovelace/climate_ac_plancia.yaml` mostra motivi/priorità, stato lock e timer; usare `sensor.ac_priority` come riferimento.
- Helper, slider e script IR stanno in `packages/climate_ac_mapping.yaml`; le automazioni restano in `packages/climate_ac_logic.yaml`.
- Coordinamento con VMC avviene solo tramite gli hook indicati, evitando duplicazioni di logica ΔT/ΔAH.

## Hook / Dipendenze
- `hook_vmc_request_ac_block`: ricevuto dalla VMC durante freecooling/ΔAH favorevole; imposta `binary_sensor.ac_block_by_vmc`.
- `hook_ac_request_vmc_low`: inviato quando DRY è attivo per chiedere VMC a vel_1 e ridurre condensa.

## Riferimenti
- [docs/logic/core/regole_core_logiche.md](../core/regole_core_logiche.md)
- [docs/logic/core/README_sensori_clima.md](../core/README_sensori_clima.md)
- [docs/logic/core/regole_plancia.md](../core/regole_plancia.md)
- [README_ClimaSystem.md](../../../README_ClimaSystem.md)
