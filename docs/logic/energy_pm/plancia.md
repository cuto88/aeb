###############################################################################
# Energy PM — Documentazione layout plancia consumi
# Copre lovelace/5_pm_plancia.yaml per monitorare prese smart PM1/2/3.
###############################################################################

SEZIONE 0 — STATO & CHIP
- Blocco iniziale "Quote oggi sui misurati" con:
  - `sensor.local_meters_energy_daily_total`
  - `sensor.mirai_daily_share_pct`
  - `sensor.ehw_daily_share_pct`
  - `sensor.ds01_daily_share_pct`
  - `sensor.pm1_daily_share_pct`
  - `sensor.pm2_daily_share_pct`
  - `sensor.pm3_daily_share_pct`
  - denominatore ancorato alla somma giornaliera dei carichi locali misurati
- Blocco potenze istantanee unificato per:
  - `Mirai`
  - `EHW`
  - `ds-01`
  - `PM1 / VMC`
  - `PM2 / Lavatrice`
  - `PM3 / Asciugatrice`

SEZIONE 1 — KPI OGGI
- Blocco unico `kWh/giorno` per:
  - `sensor.mirai_energy_daily`
  - `sensor.ehw_energy_daily`
  - `sensor.ds01_energy_daily`
  - `sensor.pm1_energy_daily`
  - `sensor.pm2_energy_daily`
  - `sensor.pm3_energy_daily`

SEZIONE 2 — CONSUMI OGGI PER ORA
- Non usata nella plancia unificata corrente.

SEZIONE 3 — POTENZA 24H
- History-graph 24h delle potenze istantanee (W) per tutti i carichi locali piu` il totale di riferimento:
  - `sensor.grid_power_w` come traccia SDM120 totale
  - `sensor.mirai_power_w`
  - `sensor.ehw_power_w`
  - `sensor.ds_01_power_w`
  - `sensor.pm1_mss310_power_w_main_channel`
  - `sensor.pm2_mss310_power_w_main_channel`
  - `sensor.pm3_mss310_power_w_main_channel`

SEZIONE 4 — CONSUMI GIORNALIERI 30GG
- Statistics-graph giornaliero a barre sui sei rami locali, finestra attuale 7 giorni.

SEZIONE 5 — MEDIE & PICCHI
- Non esposti nella plancia consumi unificata corrente.

SEZIONE 6 — KPI ULTIMO CICLO
- Non esposti nella plancia consumi unificata corrente.

NOTE
- Tutte le entità fanno capo al pacchetto energia/power monitoring.
- `sensor.mirai_energy_daily` e `sensor.ehw_energy_daily` derivano da:
  - `sensor.mirai_energy_total`
  - `sensor.ehw_energy_total`
  template canonici `total_increasing` che stabilizzano i `utility_meter` rispetto ai forward Modbus grezzi.
- Nessun comando: dashboard puramente analitica.
- Layout allineato al pattern base delle altre plance sezionali:
  - `1` colonna su mobile
  - `3` colonne su desktop (`max_columns: 3`)

## Riferimenti logici
- [Modulo Energy PM](README.md)
- [Regole plancia](../core/regole_plancia.md)
- [Regole core logiche](../core/regole_core_logiche.md)
