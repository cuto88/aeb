# Plancia Consumi Mirai+EHW+PM

File dashboard: `lovelace/consumi_mirai_ehw_plancia.yaml`

## Entita usate (runtime LocalTuya `01K0AE579DTMM0ZED250CYNCT8`)

- Pinza Mirai (A)
  - `sensor.mirai_power_w` (potenza istantanea W, alias canonico)
  - `sensor.a_energia_prelevata_forward` (kWh cumulati)
  - `sensor.a_energia_immessa_reverse` (kWh cumulati)
- Pinza EHW (B)
  - `sensor.ehw_power_w` (potenza istantanea W, alias canonico)
  - `sensor.b_energia_prelevata_forward` (kWh cumulati)
  - `sensor.b_energia_immessa_reverse` (kWh cumulati)
- Direzione:
  - `sensor.sensor_grid_direction`

## Entita aggiunte (modulo Smart Plug `packages/energy_pm.yaml`)

- Potenza istantanea PM
  - `sensor.pm1_mss310_power_w_main_channel` (Romeo)
  - `sensor.pm2_mss310_power_w_main_channel` (Lavatrice)
  - `sensor.pm3_mss310_power_w_main_channel` (Asciugatrice)
- Energia PM
  - `sensor.pm1_energy_daily`, `sensor.pm2_energy_daily`, `sensor.pm3_energy_daily`
  - `sensor.pm1_mss310_energy_kwh_main_channel`
  - `sensor.pm2_mss310_energy_kwh_main_channel`
  - `sensor.pm3_mss310_energy_kwh_main_channel`

## Layout

- Stato attuale: potenze istantanee e direzione flusso.
- Contatori cumulati: blocchi separati Mirai/EHW.
- Andamento 24h: history potenze.
- Consumi giornalieri 7 giorni: `statistics-graph` (stat `change`) su kWh prelevati.
- Smart Plug PM: sezione dedicata con potenze live, kWh giornalieri e grafici PM 24h/7gg.

## Note operative

- Mapping verificato su runtime il `2026-02-23` via `core.entity_registry`.
- Hardening naming il `2026-02-23`: alias template in `packages/cm_naming_bridge.yaml`
  (`sensor.mirai_power_w`, `sensor.ehw_power_w`) sopra i raw LocalTuya.
- Se in campo le pinze risultano invertite, scambiare solo le 2 entita di potenza
  (`sensor.mirai_power_w` <-> `sensor.ehw_power_w`) e i blocchi A/B.
