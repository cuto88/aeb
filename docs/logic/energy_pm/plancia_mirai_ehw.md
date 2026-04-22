# Plancia Consumi Mirai+EHW+PM+ds-01

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
- ds-01 / host Home Assistant (presa Tuya T34)
  - `switch.t34_smart_plug_interruttore_1`
  - `sensor.ds_01_power_w`
  - `sensor.ds_01_current_a`
  - `sensor.ds_01_voltage_v`
  - `sensor.ds_01_energy_total`
  - `sensor.ds01_energy_daily`
  - `sensor.ds01_energy_monthly`

## Layout

- Stato attuale: potenze istantanee e direzione flusso.
- Stato attuale include anche diagnostica mapping EHW:
  - `sensor.ehw_mapping_health`
  - `binary_sensor.ehw_mapping_suspect`
  - `sensor.ehw_tank_top`
  - `sensor.ehw_tank_bottom`
  - `sensor.ehw_setpoint`
- Diagnostica domanda/potenza EHW:
  - `sensor.ehw_operation_state`
  - `binary_sensor.ehw_power_confirmed`
  - `binary_sensor.ehw_demand_power_mismatch`
- KPI AEB (runtime):
  - `binary_sensor.aeb_kpi_inputs_ready`
  - `sensor.aeb_kpi_reason`
  - `sensor.aeb_self_consumption_ratio_pct`
  - `sensor.aeb_shift_effectiveness_pct`
  - `sensor.aeb_comfort_energy_score_pct`
  - `sensor.aeb_policy_activation_rate_pct`
- Contatori cumulati: blocchi separati Mirai/EHW.
- Andamento 24h: history potenze.
- Consumi giornalieri 7 giorni: `statistics-graph` (stat `change`) su kWh prelevati,
  inclusa linea dedicata `ds-01`.
- Smart Plug PM: sezione dedicata con potenze live, kWh giornalieri e grafici PM 24h/7gg.
- Sezione dedicata `ds-01 / Home Assistant host` per carico IT always-on:
  utile come baseline domestica minima, verifica uptime/stato server e controllo ROI
  dei consumi permanenti.
- Per diagnosi completa EHW usare anche la plancia dedicata:
  - `lovelace/ehw_plancia.yaml`
- `binary_sensor.ehw_running` indica domanda termica legacy, non assorbimento elettrico.
  Per conferma attivita` usare `binary_sensor.ehw_power_confirmed`.

## Note operative

- Mapping verificato su runtime il `2026-02-23` via `core.entity_registry`.
- Hardening naming il `2026-02-23`: alias template in `packages/cm_naming_bridge.yaml`
  (`sensor.mirai_power_w`, `sensor.ehw_power_w`) sopra i raw LocalTuya.
- Se in campo le pinze risultano invertite, scambiare solo le 2 entita di potenza
  (`sensor.mirai_power_w` <-> `sensor.ehw_power_w`) e i blocchi A/B.
- KPI AEB derivano da `packages/climateops/core/kpi.yaml` e usano fallback su segnali
  `policy_*`/`pv_power_now`; non dipendono da `history_stats`.
