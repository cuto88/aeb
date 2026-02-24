# Heating — Plancia

Riferimento: `lovelace/climate_heating_plancia.yaml`.

Sezioni principali:
- "Stato generale": `binary_sensor.heating_should_run`, priorità/motivo e failsafe.
- "Termostati reali (TEMP)": area osservativa con binding dinamico via `input_text.climateops_temp_thermostat_*`.
- "Setpoint e comandi": target comfort/notte, antigelo e delta boost FV.
- "Zone incluse": toggle zona giorno/notte/bagno.
- "KPI e diagnostica": errori setpoint, stanze sotto target, finestre logiche (comfort/PV/notte), esterna fredda.
- "Grafici 24h / 7gg": trend temperature e statistiche errori.
- "Runtime e cicli": ore ON e minuti da ultimo cambio.
- "Debug": segnali diagnostici con sezione collapsible.
- "Timeline decisioni": priorità/motivo e stato comando riscaldamento.

Allineamento attuatori:
- La timeline usa `switch.heating_master` (comando logico canonico).
- Il relay fisico `switch.4_ch_interruttore_3` resta visibile in debug come evidenza hardware.

Tuning UI/performance applicato:
- `history-graph` principali ridotti a 12h con `refresh_interval: 120`.

## Riferimenti logici
- [Modulo Heating](README.md)
- [Regole plancia](../core/regole_plancia.md)
- [Regole core logiche](../core/regole_core_logiche.md)
