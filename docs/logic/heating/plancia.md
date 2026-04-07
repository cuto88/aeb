# Heating — Plancia

Riferimento: `lovelace/climate_heating_plancia.yaml`.

Stato sidebar:
- `2-heating` resta registrata ma non visibile (`show_in_sidebar: false`).
- L'accesso utente operativo per il dominio clima e` `1-clima-casa`.

Sezioni principali:
- "Stato generale": `binary_sensor.heating_should_run`, priorità/motivo e failsafe.
- "Termostati reali (TEMP)": area osservativa con ESP32 `camera1/camera2` esposti direttamente, sensori LDR raw per calibrazione e binding dinamico via `input_text.climateops_temp_thermostat_*`.
  Decisione `binary_sensor.thermostat_*_temp` calcolata da `ldr_raw` con soglia in Volt e isteresi:
  `input_number.climateops_temp_thermostat_*_threshold_v` + `input_number.climateops_temp_thermostat_hysteresis_v`.
  Logica attuale: ON sopra soglia (con isteresi), OFF sotto soglia.
- "Setpoint e comandi": target comfort/notte, antigelo e delta boost FV.
- "Zone incluse": toggle zona giorno/notte/bagno.
- "KPI e diagnostica": errori setpoint, stanze sotto target, finestre logiche (comfort/PV/notte), esterna fredda.
- "Grafici 24h / 7gg": trend temperature e statistiche errori.
- "Runtime e cicli": ore ON e minuti da ultimo cambio.
- "Debug": segnali diagnostici in card entities standard (compatibilità UI estesa).
- "Timeline decisioni": priorità/motivo e stato comando riscaldamento.

Allineamento attuatori:
- La timeline usa `switch.heating_master` (comando logico canonico).
- Il relay fisico `switch.4_ch_interruttore_3` resta visibile in debug come evidenza hardware.

Tuning UI/performance applicato:
- `history-graph` principali ridotti a 12h con `refresh_interval: 120`.
- Layout sezioni allineato a `type: grid` per compatibilità con view `sections`.
- Esposti in plancia i controlli di tuning LDR:
  `input_text.climateops_temp_thermostat_*_raw_entity`,
  `input_number.climateops_temp_thermostat_*_threshold_v`,
  `input_number.climateops_temp_thermostat_hysteresis_v`.

## Riferimenti logici
- [Modulo Heating](README.md)
- [Regole plancia](../core/regole_plancia.md)
- [Regole core logiche](../core/regole_core_logiche.md)
