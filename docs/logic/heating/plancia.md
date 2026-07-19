# Heating — Plancia

Riferimento: `lovelace/03_heating_loop.yaml`.

Stato sidebar:
- `03-riscaldamento` registra `lovelace/03_heating_loop.yaml` come `3 Heating Loop`, visibile in sidebar.
- L'overview cross-modulo resta `01-clima-casa`; la plancia Heating e` il drill-down ufficiale del dominio.

Sezioni principali:
- "Stato generale": `binary_sensor.heating_should_run`, priorità/motivo e failsafe.
- "Setpoint e comandi": target comfort/notte, antigelo e delta boost FV.
- "Zone incluse": toggle zona giorno/notte/bagno.
- "Grafici 24h / 7gg": trend temperature e statistiche errori.
- "Runtime e cicli": ore ON e minuti da ultimo cambio.
- "Timeline decisioni": priorità/motivo e stato comando riscaldamento.

Diagnostica tecnica in Observability:
- `Climate diagnostics`: errori, finestre logiche, failsafe e segnali debug Heating.
- `Legacy mappings`: stato TEMP dismesso, binding dinamici e soglie LDR via `input_text.climateops_temp_thermostat_*` e `input_number.climateops_temp_thermostat_*`.

Allineamento attuatori:
- La timeline usa `switch.heating_master` (comando logico canonico).
- Il relay fisico `switch.4_ch_interruttore_3` resta visibile in Observability / `Climate diagnostics` come evidenza hardware.

Tuning UI/performance applicato:
- `history-graph` principali ridotti a 12h con `refresh_interval: 120`.
- Layout sezioni allineato a `type: grid` per compatibilità con view `sections`.
- Esposti in Observability / `Legacy mappings` i controlli di tuning LDR:
  `input_text.climateops_temp_thermostat_*_raw_entity`,
  `input_number.climateops_temp_thermostat_*_threshold_v`,
  `input_number.climateops_temp_thermostat_hysteresis_v`.

## Riferimenti logici
- [Modulo Heating](README.md)
- [Regole plancia](../core/regole_plancia.md)
- [Regole core logiche](../core/regole_core_logiche.md)
