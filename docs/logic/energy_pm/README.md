# Energy PM — Monitor consumi

## Titolo
Energy PM — monitor consumi / power monitoring (dashboard-oriented).

## Obiettivo
- Monitorare in dashboard i consumi locali rilevanti su un unico quadro:
  - Mirai
  - EHW
  - ds-01
  - PM1 / VMC
  - PM2 / Lavatrice
  - PM3 / Asciugatrice
- Evidenziare quote giornaliere dei carichi misurati, kWh giornalieri e trend senza logiche decisionali.

## Entrypoints
- YAML: `packages/energy_pm.yaml`.
- YAML transizione PM1->VMC: `packages/energy_vmc_reallocation.yaml`.
- Lovelace: `lovelace/5_pm_plancia.yaml`.

## KPI / Entità principali
- Stato & chip: `binary_sensor.lavatrice_in_ciclo`, `binary_sensor.asciugatrice_in_ciclo`, `binary_sensor.pm1_in_ciclo`.
- Potenza istantanea: `sensor.pm*_mss310_power_w_main_channel` (PM1/PM2/PM3).
- Potenza istantanea carichi locali:
  - `sensor.mirai_power_w`
  - `sensor.ehw_power_w`
  - `sensor.ds_01_power_w`
  - `sensor.pm*_mss310_power_w_main_channel`
- KPI oggi: `sensor.pm*_energy_daily`.
- KPI oggi ramo locale:
  - `sensor.mirai_energy_daily`
  - `sensor.ehw_energy_daily`
  - `sensor.ds01_energy_daily`
  - `sensor.pm*_energy_daily`
- Consumi per ora: `sensor.pm*_mss310_energy_kwh_main_channel`.
- Medie & picchi: `sensor.pm*_power_mean_15m`, `sensor.pm*_power_max_24h`.
- Ultimo ciclo: `input_number.pm*_last_cycle_kwh`, `input_datetime.pm*_last_*`.
- Quote giornaliere carichi misurati:
  - `sensor.local_meters_energy_daily_total`
  - `sensor.mirai_daily_share_pct`
  - `sensor.ehw_daily_share_pct`
  - `sensor.ds01_daily_share_pct`
  - `sensor.pm1_daily_share_pct`
  - `sensor.pm2_daily_share_pct`
  - `sensor.pm3_daily_share_pct`

## Formula quote giornaliere
- Numeratore: `kWh/giorno` del singolo carico misurato.
- Denominatore: somma dei `kWh/giorno` dei sei carichi locali misurati.
- Motivo: il “consumo totale casa” non ha oggi una SSOT runtime abbastanza solida per una percentuale globale affidabile.
- Obiettivo: dare una lettura chiara di chi sta pesando di piu` nel giorno tra i carichi realmente misurati, evitando KPI instabili in forte export.

## Correzioni applicate alla plancia consumi
- Rimosse le entita` legacy di `energia immessa` delle pinze locali.
- Corretti i `kWh/giorno` di `Mirai` e `EHW` con `utility_meter` dedicati su:
  - `sensor.mirai_energy_total`
  - `sensor.ehw_energy_total`
- `sensor.mirai_energy_total` e `sensor.ehw_energy_total` sono copie template canoniche dei forward Modbus con `state_class: total_increasing`, introdotte per evitare `utility_meter` in stato `paused`.
- Rimossa la frammentazione tra blocco `Mirai/EHW/ds-01` e blocco `PM`.
- Unificati i grafici giornalieri e i trend di potenza nello stesso quadro.
- Rimossa dalla UI la pseudo-incidenza globale istantanea, sostituita da quote storiche giornaliere sui carichi misurati.

## Hook / Dipendenze
- Nessun hook esplicito: dashboard di monitoraggio senza comandi.

## Riferimenti
- [docs/logic/core/regole_core_logiche.md](../core/regole_core_logiche.md)
- [docs/logic/core/README_sensori_clima.md](../core/README_sensori_clima.md)
- [docs/logic/core/regole_plancia.md](../core/regole_plancia.md)
- [README_ClimaSystem.md](../../../README_ClimaSystem.md)
- Local runtime evidence: `docs/runtime_evidence/2026-03-01/REPORT_robot_romeo_baseline_for_vmc_reallocation_2026-03-01.md`
