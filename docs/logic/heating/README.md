# Heating — Pavimento radiante
> Questo file descrive la logica di `packages/climate_heating.yaml`.

## Titolo
Heating — pavimento radiante (zone giorno/notte/bagno).

## Obiettivo
- Mantenere le zone al target comfort sfruttando l’inerzia del pavimento radiante con finestra 10:00–18:00 e surplus FV.
- Applicare lock anti-ciclo, antifreeze e night_setback garantendo sicurezza sensori e override manuale controllato.

## Entrypoints
- YAML: `packages/climate_heating.yaml`.
- Lovelace: `lovelace/climate_heating_plancia.yaml`.
- Thermostat TEMP override: `packages/climateops/overrides/thermostat_indicators_temp.yaml`.

## KPI / Entità principali
### Mappa priorità
| Priorità | KPI principali | Azione / logica |
| --- | --- | --- |
| **P0_failsafe** | Sensori temperatura zona/esterna invalidi o fuori range | Disabilita richiesta calore e segnala errore stanza (`sensor.heating_error_zona_*`). |
| **P1_anti_frost** | `sensor.t_out` molto bassa o zone < soglia minima | Accende impianto bypassando finestra oraria per evitare gelo nei circuiti. |
| **P2_comfort** | Zone abilitate sotto `input_number.temp_target_risc` con isteresi | Attiva riscaldamento rispettando `binary_sensor.heating_lock_min_on_ok` e min_off; segue finestra 10–18 quando non critico. |
| **P3_pv_boost** | Surplus FV + zona prossima al target | Estende runtime dentro finestra 10–18 per pre-caricare il pavimento senza violare lock. |
| **P4_night_setback** | Fascia notturna + target setback attivo | Mantiene temperatura ridotta limitando richieste, salvo comfort critico. |
| **manual** | `input_boolean.heating_manual_active` + `input_select.heating_manual_mode` | Forza ON/OFF rispettando lock min_on/min_off; scade col timer manuale se previsto. |
| **idle** | Nessuna priorità attiva | Impianto spento, monitora sensori e lock in attesa di nuova richiesta. |

### KPI e sensori chiave
- Temperature zona: `sensor.t_in_giorno`, `sensor.t_in_notte1`, `sensor.t_in_notte2`, `sensor.t_in_bagno`; esterna `sensor.t_out`.
- Target e tolleranza: `input_number.temp_target_risc`, `input_number.temp_tolleranza_risc`, fasce orarie (10:00–18:00).
- Lock: `binary_sensor.heating_lock_min_on_ok`, `binary_sensor.heating_lock_min_off_ok`, contatori runtime `sensor.heating_minuti_da_ultimo_cambio`.
- Stato logico: `sensor.heating_reason`, `sensor.heating_priority`, `binary_sensor.heating_should_run`, `sensor.heating_stanze_attive`.

### Casi particolari / failsafe / lock
- Ogni zona può essere esclusa con `input_boolean.heating_use_*`; errori sensori disabilitano solo la zona affetta.
- Antifreeze bypassa finestra oraria e lock min_off; comfort critico (>1 °C sotto target) può derogare la finestra 10–18.
- Lock min_on/min_off prevengono cicli brevi; max_run monitorato per audit ma non forza spegnimenti improvvisi.
- Manual override usa gli stessi lock hardware e restituisce il controllo al termine del timer o su toggle utente.

### Note operative
- Plancia `lovelace/climate_heating_plancia.yaml` mostra KPI comfort, lock e selezione zone; non duplicare logica nelle card.
- Mapping TEMP termostati ESP32:
  - stato corrente runtime 2026-03-29: sensori ESP32/LDR smontati, quindi i binding default sono lasciati vuoti;
  - inoltre le vecchie entry `ESPHome` `LDR Camera1` e `LDR Camera2` sono disabilitate nel runtime, cosi` il boot non tenta connessioni verso nodi assenti;
  - quando l'hardware tornera` disponibile, reimpostare manualmente gli `input_text.climateops_temp_thermostat_*`;
  - soglia default: `3.00 V` (per zona) con isteresi default `0.10 V`;
  - logica: `thermostat_*_temp` ON sopra soglia, OFF sotto soglia con isteresi per ridurre oscillazioni.
- Tutte le automazioni e helper risiedono in `packages/climate_heating.yaml`; non esistono più riferimenti a file 3_heating.yaml legacy.
- `sensor.heating_priority` offre descrizione leggibile (P0–P4/manual/idle) coerente con `README_ClimaSystem.md`.

## Hook / Dipendenze
- Riceve `hook_surplus_heating_precharge` dal modulo surplus per P3_pv_boost; nessun blocco diretto da VMC/AC.
- Output verso plancia: esposizione delle entità di motivo/priorità/lock per diagnosi manuale.

## Riferimenti
- [docs/logic/core/regole_core_logiche.md](../core/regole_core_logiche.md)
- [docs/logic/core/README_sensori_clima.md](../core/README_sensori_clima.md)
- [docs/logic/core/regole_plancia.md](../core/regole_plancia.md)
- [README_ClimaSystem.md](../../../README_ClimaSystem.md)
