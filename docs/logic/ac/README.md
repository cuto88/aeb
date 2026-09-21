# AC — Climatizzazione split (DRY/COOL)
> Logica AC suddivisa in **mapping/control** (`climate_ac_mapping.yaml`: helper, slider, script IR) e **logica** (`climate_ac_logic.yaml`: priorità, hook, automazioni).

## Titolo
AC — split (dry/cool) con lock anti-ciclo e coordinamento VMC.

## Obiettivo
- Garantire comfort estivo usando DRY per la sola domanda igrometrica e COOL quando esiste domanda termica, rispettando blocchi e lock anti-ciclo.
- Coordinare l’AC con la VMC per evitare condensa/contro-bilanciamento e applicare lock anti-ciclo sugli split giorno/notte.

## Entrypoints
- YAML: `packages/climate_ac_mapping.yaml`, `packages/climate_ac_logic.yaml`.
- Lovelace corrente: `lovelace/04_cooling_loop.yaml`; riferimento storico: `lovelace/_archive/legacy_dashboards/04_cooling_loop_legacy.yaml`.
- Entrypoint utente corrente: `lovelace/01_eclss_casa.yaml`.

## KPI / Entità principali
### Mappa priorità
| Priorità | KPI principali | Azione / logica |
| --- | --- | --- |
| **P0_failsafe** | Sensori T/UR interni o esterni invalidi | Spegne gli split e segnala motivo failsafe su `sensor.ac_reason`. |
| **P1_block_vmc** | `binary_sensor.ac_block_by_vmc` (freecooling o ΔAH favorevole esterno) | Impedisce COOL/DRY mentre la VMC richiede blocco; mantiene stato OFF salvo manuale. |
| **P2_dry** | UR e dew point sopra soglia, con temperatura sopra il minimo di protezione e senza domanda termica | Attiva DRY per la zona richiesta; conserva la modalità durante l'isteresi e usa COOL come fallback se DRY non è supportato. |
| **P3_cool** | `sensor.t_in_*` sopra `input_number.ac_t_cool_on` + isteresi | Attiva COOL (giorno/notte separati) se fascia oraria consentita e blocco VMC assente; lock min_on/min_off applicati. |
| **manual** | `input_boolean.ac_manual` + `input_select.ac_manual_mode` | Forza modalità selezionata ignorando fasce, ma rispetta lock e scade con `timer.ac_manual_timeout`. |
| **idle** | Nessuna priorità attiva | Split spenti, monitoraggio continuo di T/UR e blocchi. |

### KPI e sensori chiave
- Temperature/UR: `sensor.t_in_giorno`, `sensor.t_in_notte1`, `sensor.ur_in_giorno`, `sensor.ur_in_notte1`, `sensor.t_out`, `sensor.ur_out`.
- Stati logici: `binary_sensor.ac_need_dry`, `binary_sensor.ac_need_cool`, `binary_sensor.ac_fascia_ok`, `binary_sensor.ac_should_run`, `sensor.ac_priority`, `sensor.ac_reason`.
- Modalità HVAC per zona: `sensor.ac_giorno_requested_hvac_mode`, `sensor.ac_notte_requested_hvac_mode` (`off`, `dry`, `cool`).
- Rollback operativo: `input_boolean.ac_auto_dry_enabled`; se disattivato, ogni richiesta AC usa COOL senza rimuovere la nuova logica.
- Lock: `binary_sensor.ac_lock_min_on_ok`, `binary_sensor.ac_lock_min_off_ok`, contatori runtime e `input_number.ac_max_run`.

### Casi particolari / failsafe / lock
- Blocco fascia 23–07: `binary_sensor.ac_fascia_ok` evita avvii notturni salvo manual override.
- Lock min_on/min_off proteggono i compressori; max_run può spegnere dopo runtime prolungato se definito.
- Un cambio `COOL`/`DRY` a split già acceso viene applicato senza eseguire un ciclo OFF/ON; l'isteresi della causa evita commutazioni rapide.
- Se l'entità `climate` non dichiara `dry` in `hvac_modes`, lo script applica `cool` come fallback sicuro e pubblica `dry_supported: false` sul sensore di modalità richiesta.
- Manuale può scavalcare blocco fascia ma non il failsafe sensori; termina col timer o con lo stesso toggle.

### Note operative
- La plancia storica `lovelace/_archive/legacy_dashboards/04_cooling_loop_legacy.yaml` mostra motivi/priorita`, stato lock e timer; usare `sensor.ac_priority` come riferimento.
- Helper, slider e script IR stanno in `packages/climate_ac_mapping.yaml`; le automazioni restano in `packages/climate_ac_logic.yaml`.
- Coordinamento con VMC avviene solo tramite gli hook indicati, evitando duplicazioni di logica ΔT/ΔAH.

## Hook / Dipendenze
- `hook_vmc_request_ac_block`: ricevuto dalla VMC durante freecooling/ΔAH favorevole; imposta `binary_sensor.ac_block_by_vmc`.
- `hook_ac_request_vmc_low`: inviato quando DRY è attivo per chiedere VMC a vel_1 e ridurre condensa.
- Il planner upstream ora considera anche l'umidità interna per alzare la richiesta AC quando la temperatura da sola non basta.
- Il proxy shower resta un segnale di prudenza per il dominio VMC, ma non è più un blocco assoluto del `COOL_DAY` quando il planner AC chiede raffrescamento.

## Riferimenti
- [docs/logic/core/regole_core_logiche.md](../core/regole_core_logiche.md)
- [docs/logic/core/README_sensori_clima.md](../core/README_sensori_clima.md)
- [docs/logic/core/regole_plancia.md](../core/regole_plancia.md)
- [README_ClimaSystem.md](../../../README_ClimaSystem.md)
