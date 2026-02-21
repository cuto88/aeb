# Climate system — ENTITY MAP (canonical)

Single source of truth per tutte le entità climate (VMC / Heating / AC / Windows).
Tutti i package clima **devono** usare **esattamente** questi `entity_id`.

> NOTA: descrizioni in italiano, ma `entity_id` sempre in inglese.

---

## 1. Physical ambient sensors (T / RH)

| Ruolo                         | Entity ID canonico       |
|-------------------------------|--------------------------|
| T indoor — living area        | `sensor.t_in_giorno`     |
| T indoor — night 1            | `sensor.t_in_notte1`     |
| T indoor — night 2            | `sensor.t_in_notte2`     |
| T indoor — bathroom           | `sensor.t_in_bagno`      |
| T outdoor                     | `sensor.t_out`           |
| RH indoor — living area       | `sensor.ur_in_giorno`    |
| RH indoor — night 1           | `sensor.ur_in_notte1`    |
| RH indoor — night 2           | `sensor.ur_in_notte2`    |
| RH indoor — bathroom          | `sensor.ur_in_bagno`     |
| RH outdoor                    | `sensor.ur_out`          |

---

## 2. KPI sensors (derived)

| KPI                                      | Entity ID canonico       |
|------------------------------------------|--------------------------|
| T indoor average                         | `sensor.t_in_med`        |
| RH indoor average                        | `sensor.ur_in_media`     |
| RH indoor minimum                        | `sensor.ur_in_min`       |
| Absolute humidity indoor                 | `sensor.ah_in`           |
| Absolute humidity outdoor                | `sensor.ah_out`          |
| ΔT indoor–outdoor                        | `sensor.delta_t_in_out`  |
| ΔAH indoor–outdoor                       | `sensor.delta_ah_in_out` |

### 2.1 KPI zona notte

- `sensor.t_notte_med` — temperatura media zona notte; **template sensor** che calcola la media delle temperature indoor di bagno, notte1, notte2, notte3 e lavanderia. Unità: °C.
- `sensor.ur_notte_med` — umidità relativa media zona notte; **template sensor** che calcola la media delle UR indoor di bagno, notte1, notte2, notte3 e lavanderia. Unità: %.

---

## 3. Ventilazione / VMC

### 3.1 Helpers (input_* / timer / text)

| Ruolo                                      | Entity ID canonico                   |
|-------------------------------------------|--------------------------------------|
| VMC mode (auto / manual / off…)           | `input_select.vmc_mode`              |
| VMC manual speed selection                | `input_select.vmc_manual_speed`      |
| Manual enable toggle                      | `input_boolean.vmc_manual`           |
| Bathroom boost enable                     | `input_boolean.vmc_boost_bagno`      |
| Freecooling ΔT threshold                  | `input_number.vmc_freecooling_delta` |
| Freecooling ΔAH threshold                 | `input_number.vmc_freecooling_delta_ah` |
| ΔT min for open windows advice            | `input_number.vent_deltat_min`       |
| ΔAH min for open windows advice           | `input_number.vent_deltaah_min`      |
| Anti-dry RH min                           | `input_number.vmc_anti_secco_ur_min` |
| Bathroom boost ON threshold               | `input_number.vmc_bagno_on`          |
| Bathroom boost OFF threshold              | `input_number.vmc_bagno_off`         |
| Backup T indoor                           | `input_number.vent_backup_t_in`      |
| Backup RH indoor                          | `input_number.vent_backup_ur_in`     |
| Summer override flag                      | `input_boolean.vent_override_estate` |
| Debug climate notifications flag          | `input_boolean.climate_debug_telegram` |
| Night-flush start time                    | `input_datetime.vent_night_flush_start` |
| Night-flush end time                      | `input_datetime.vent_night_flush_end`   |
| VMC message text (dashboard)              | `input_text.vent_messaggio_consiglio`   |
| Manual mode timeout                       | `timer.vmc_manual_timeout`           |

### 3.2 Diagnostic sensors / flags

| Ruolo                                      | Entity ID canonico                         |
|-------------------------------------------|--------------------------------------------|
| Critical sensors availability OK          | `binary_sensor.vmc_sensors_ok`             |
| Anti-dry active                           | `binary_sensor.vmc_anti_secco`             |
| VMC dry mode active                       | `binary_sensor.vmc_dry_active`             |
| Bathroom boost auto active                | `binary_sensor.vmc_bagno_boost_auto`       |
| Freecooling candidate                     | `binary_sensor.vmc_freecooling_candidate`  |
| Freecooling active                        | `binary_sensor.vmc_freecooling_active`     |
| AC night block (logic flag)               | `binary_sensor.ac_blocco_notte`            |
| AC need cool (logic flag)                 | `binary_sensor.ac_need_cool`               |
| AC need dry (logic flag)                  | `binary_sensor.ac_need_dry`                |
| AC should run (final decision)            | `binary_sensor.ac_should_run`              |
| VMC target speed (0–3)                    | `sensor.vmc_vel_target`                    |
| VMC speed index (debug)                   | `sensor.vmc_vel_index`                     |
| Ventilation priority (P0–P4)              | `sensor.ventilation_priority`              |
| Ventilation reason (human-readable)       | `sensor.ventilation_reason`                |
| Ventilation state change reason           | `sensor.ventilation_state_reason`          |
| Freecooling textual status                | `sensor.vmc_freecooling_status`            |
| Open windows recommended                  | `sensor.clima_open_windows_recommended`    |
| Season flag for ventilation (optional)    | `sensor.vent_stagione`                     |

Note operative VMC:

- `binary_sensor.vmc_bagno_boost_auto` → ON se UR bagno ≥ `input_number.vmc_bagno_on` **oppure**
  ΔUR bagno–out ≥10%. Resta ON finché non si verificano le condizioni di spegnimento: UR bagno
  ≤`input_number.vmc_bagno_off` **e** ΔUR bagno–out ≤6%. Fail-safe: auto-OFF dopo 45 minuti
  continuativi di boost, con `delay_off` di 3 minuti per evitare oscillazioni.
- Priorità `P1_boost_bagno` imposta `sensor.vmc_vel_target`=3 e blocca le richieste automatiche AC
  dal controller clima durante il boost bagno.

---

## 4. Heating

### 4.1 Helpers

| Ruolo                                      | Entity ID canonico                            |
|-------------------------------------------|-----------------------------------------------|
| Use heating — living                      | `input_boolean.heating_use_giorno`            |
| Use heating — night 1                     | `input_boolean.heating_use_notte1`            |
| Use heating — night 2                     | `input_boolean.heating_use_notte2`            |
| Use heating — bathroom                    | `input_boolean.heating_use_bagno`             |
| Heating global enable                     | `input_boolean.heating_enable`                |
| Heating manual active                     | `input_boolean.heating_manual_active`         |
| Manual mode selection                     | `input_select.heating_manual_mode`            |
| Manual timeout                            | `timer.heating_manual_timeout`                |
| Daytime comfort setpoint                  | `input_number.temp_target_risc`               |
| Night setpoint                            | `input_number.heating_setpoint_night`         |
| Hysteresis                                | `input_number.heating_hysteresis`             |
| Antifreeze threshold                      | `input_number.heating_antifreeze_threshold`   |
| External cold threshold                   | `input_number.heating_ext_cold_threshold`     |
| Boost ΔT above target                     | `input_number.heating_boost_delta`            |
| Min ON time (minutes)                     | `input_number.heating_min_on_minutes`         |
| Min OFF time (minutes)                    | `input_number.heating_min_off_minutes`        |
| Max daily ON hours (limit)                | `input_number.heating_hours_on_daily`         |
| Heating window start (PV-friendly)        | `input_datetime.heating_window_start`         |
| Heating window end (PV-friendly)          | `input_datetime.heating_window_end`           |

### 4.2 Diagnostic (core)

| Ruolo                                      | Entity ID canonico                         |
|-------------------------------------------|--------------------------------------------|
| Heating reason (text)                     | `sensor.heating_reason`                    |
| Heating priority (P0–P4)                  | `sensor.heating_priority`                  |
| Heating state change reason               | `sensor.heating_state_reason`              |
| Min indoor T (all rooms)                  | `sensor.heating_t_in_min`                  |
| Rooms below target                        | `sensor.heating_rooms_below_target`        |
| Failsafe bad sensors                      | `binary_sensor.heating_failsafe_sensors_bad`|
| Min-ON lock ok                            | `binary_sensor.heating_lock_min_on_ok`     |
| Min-OFF lock ok                           | `binary_sensor.heating_lock_min_off_ok`    |
| Time-window active                        | `binary_sensor.heating_finestra_oraria`    |
| External cold flag                        | `binary_sensor.heating_esterna_fredda`     |
| At least one room below target            | `binary_sensor.heating_almeno_una_stanza_sotto_target` |
| Minutes since last change (ON/OFF)        | `sensor.heating_minutes_since_change`      |
| Hours ON today                            | `sensor.heating_hours_on_today`            |
| Hours ON yesterday                        | `sensor.heating_hours_on_yesterday`        |

### 4.3 Diagnostic (optional / advanced)

| Ruolo                                      | Entity ID canonico                         |
|-------------------------------------------|--------------------------------------------|
| Number of active rooms                    | `sensor.heating_rooms_active`              |
| Error / issues — living                   | `sensor.heating_error_zona_giorno`         |
| Error / issues — night                    | `sensor.heating_error_zona_notte`          |
| Window PV-block flag                      | `binary_sensor.heating_window_pv`          |
| Window night-block flag                   | `binary_sensor.heating_window_night`       |
| Final “should run” decision               | `binary_sensor.heating_should_run`         |

---

## 5. Air Conditioning (AC)

Nota AC:
switch.ac_* = attuatore/abilitazione (domain switch); climate.ac_* = interfaccia docs/logic/termostato (domain climate).
Non è un rename: la coesistenza è intenzionale. Warning alias possibile: `climate.ac_giorno` ↔ `switch.ac_giorno`, `climate.ac_notte` ↔ `switch.ac_notte`.

### 5.0 AC / Climatizzazione (entity climate)

| Ruolo                                      | Entity ID canonico                         |
|-------------------------------------------|--------------------------------------------|
| AC day split (thermostat interface)       | `climate.ac_giorno`                        |
| AC night split (thermostat interface)     | `climate.ac_notte`                         |

### 5.1 Helpers

| Ruolo                                      | Entity ID canonico                         |
|-------------------------------------------|--------------------------------------------|
| AC manual enable                          | `input_boolean.ac_manual`                  |
| AC manual mode selection                  | `input_select.ac_manual_mode`              |
| AC manual timeout                         | `timer.ac_manual_timeout`                  |
| AC block-by-VMC flag                      | `input_boolean.ac_block_vmc`               |
| AC block-by-VMC timeout                   | `timer.ac_block_vmc_timeout`               |
| Cooling setpoint                          | `input_number.ac_cool_setpoint`            |
| AC day setpoint                           | `input_number.ac_giorno_setpoint`          |
| AC night setpoint                         | `input_number.ac_notte_setpoint`           |
| Dry mode RH ON threshold                  | `input_number.ac_dry_ur_on`                |
| Dry mode RH OFF threshold                 | `input_number.ac_dry_ur_off`               |
| Min ON time (minutes)                     | `input_number.ac_min_on_minutes`           |
| Min OFF time (minutes)                    | `input_number.ac_min_off_minutes`          |

### 5.2 Diagnostic

| Ruolo                                      | Entity ID canonico                         |
|-------------------------------------------|--------------------------------------------|
| Failsafe bad sensors                      | `binary_sensor.ac_failsafe_sensors_bad`   |
| Blocked by VMC                            | `binary_sensor.ac_block_by_vmc`           |
| AC richiesta automaticamente dal clima    | `binary_sensor.clima_ac_from_vmc_request` |
| Min-ON lock ok                            | `binary_sensor.ac_lock_min_on_ok`         |
| Min-OFF lock ok                           | `binary_sensor.ac_lock_min_off_ok`        |
| AC priority (P0–P4)                       | `sensor.ac_priority`                      |
| AC state change reason                    | `sensor.ac_state_reason`                  |
| AC reason (text)                          | `sensor.ac_reason`                        |
| Season hot/cold flag                      | `binary_sensor.stagione_calda`            |

### 5.3 Runtime diagnostics (optional)

| Ruolo                                      | Entity ID canonico                         |
|-------------------------------------------|--------------------------------------------|
| AC day — ON time today                    | `sensor.ac_giorno_tempo_on_oggi`          |
| AC day — ON cycles today                  | `sensor.ac_giorno_cicli_on_oggi`          |
| AC night — ON time today                  | `sensor.ac_notte_tempo_on_oggi`           |
| AC night — ON cycles today                | `sensor.ac_notte_cicli_on_oggi`           |
| AC day — last ON                          | `sensor.ac_giorno_ultimo_on`              |
| AC day — last OFF                         | `sensor.ac_giorno_ultimo_off`             |
| AC night — last ON                        | `sensor.ac_notte_ultimo_on`               |
| AC night — last OFF                       | `sensor.ac_notte_ultimo_off`              |

---

## 6. Windows & actuators

### 6.1 Windows (aggregated state)

| Ruolo                                      | Entity ID canonico                         |
|-------------------------------------------|--------------------------------------------|
| All windows closed (global)               | `binary_sensor.windows_all_closed`        |
| Any window open — living area             | `binary_sensor.windows_giorno_any`        |
| Any window open — night area              | `binary_sensor.windows_notte_any`         |
| Any window open — bathroom                | `binary_sensor.windows_bagno_any`         |
| Total open windows count                  | `sensor.windows_open_count`               |
| Windows state text (for dashboard)        | `sensor.vent_finestre_state`              |

### 6.2 Actuators — VMC

| Ruolo                                      | Entity ID canonico                         |
|-------------------------------------------|--------------------------------------------|
| VMC speed 0 relay                         | `switch.vmc_vel_0`                        |
| VMC speed 1 relay                         | `switch.vmc_vel_1`                        |
| VMC speed 2 relay                         | `switch.vmc_vel_2`                        |
| VMC speed 3 relay                         | `switch.vmc_vel_3`                        |

### 6.3 Actuators — Heating

| Ruolo                                      | Entity ID canonico                         |
|-------------------------------------------|--------------------------------------------|
| Heating master (logical)                  | `switch.heating_master`                   |
| Heating night block                       | `switch.heating_night_block`              |
| Heating hardware relay                    | `switch.4_ch_interrutore_3`               |

### 6.4 Actuators — AC

| Ruolo                                      | Entity ID canonico                         |
|-------------------------------------------|--------------------------------------------|
| AC day split                              | `switch.ac_giorno`                        |
| AC night split                            | `switch.ac_notte`                         |

---

## 7. External dependencies (non-climate packages)

Le dipendenze esterne sono entità richieste dalla logica clima ma definite in altri
package o integrazioni (energia, meteo, dispositivi hardware). Includono sia
sensori (surplus, meteo) sia attuatori (relè VMC/AC) quando derivano da
configurazioni ESPHome/Modbus/IR-bridge e non dai package `climate_*`.

Queste entità NON sono definite nel modulo climate ma sono richieste dalla logica.

| Ruolo                                      | Entity ID canonico                         | Note |
|-------------------------------------------|--------------------------------------------|------|
| PV surplus available                      | `binary_sensor.surplus_ok`                | Usato per boost heating con FV |
| Weather conditions OK for open windows    | `binary_sensor.vent_condizioni_meteo_ok`  | Hook per `clima_open_windows_recommended` (TODO) |

- I relè VMC `switch.vmc_vel_0/1/2/3` possono essere definiti in ESPHome o in
  package hardware separati, non in `climate_1_ventilation`.
- I relè AC `switch.ac_giorno` e `switch.ac_notte` possono essere definiti in
  altri package (es. bridge IR, SwitchBot) e non in `climate_ac_logic`.

---

## 8. Rules for Codex

1. **Use only these entity_id values** quando si creano o modificano package e dashboard clima.
2. Se trovi un nome diverso (italiano, legacy, typo), **rimpiazzalo** con quello canonico riportato qui.
3. Non creare nuove entità clima senza aggiungerle prima in questa tabella.
4. Qualsiasi failsafe basato su “sensors OK” deve usare `binary_sensor.vmc_sensors_ok` e i sensori fisici/KPI sopra elencati.

### Checklist verifica (strict_clima)

- Esegui `ops/gate_entity_map.ps1 -Mode strict_clima` e verifica “Missing in map (clima only): 0”.
- Controlla che resti solo il warning di alias `climate.ac_*` vs `switch.ac_*`, senza nuove discrepanze.
- Conferma che nessun altro file oltre a questo README è stato modificato.
---

## 9. Step 4 naming bridge (cm_*)

Per la migrazione naming funzionale Step 4, le dashboard e la documentazione devono usare
le entità canoniche `cm_*` (bridge verso legacy).

Riferimento SOT completo: `docs/SOT_ENTITIES.md`.

Entità principali:
- `sensor.cm_contract_missing_entities`
- `binary_sensor.cm_policy_allow_vmc_boost`
- `binary_sensor.cm_policy_surplus_ok`
- `sensor.cm_system_mode_suggested`
- `sensor.cm_system_reason`

Nota: le entità legacy restano attive per un ciclo, ma non sono più naming target.

