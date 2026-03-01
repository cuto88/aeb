# Energy PM — Monitor consumi

## Titolo
Energy PM — monitor consumi / power monitoring (dashboard-oriented).

## Obiettivo
- Monitorare in dashboard i consumi delle prese smart PM1/PM2/PM3.
- Evidenziare KPI giornalieri, trend e ultimo ciclo senza logiche decisionali.

## Entrypoints
- YAML: `packages/energy_pm.yaml`.
- YAML transizione PM1->VMC: `packages/energy_vmc_reallocation.yaml`.
- Lovelace: `lovelace/5_pm_plancia.yaml`.

## KPI / Entità principali
- Stato & chip: `binary_sensor.lavatrice_in_ciclo`, `binary_sensor.asciugatrice_in_ciclo`, `binary_sensor.pm1_in_ciclo`.
- Potenza istantanea: `sensor.pm*_mss310_power_w_main_channel` (PM1/PM2/PM3).
- KPI oggi: `sensor.pm*_energy_daily`.
- Consumi per ora: `sensor.pm*_mss310_energy_kwh_main_channel`.
- Medie & picchi: `sensor.pm*_power_mean_15m`, `sensor.pm*_power_max_24h`.
- Ultimo ciclo: `input_number.pm*_last_cycle_kwh`, `input_datetime.pm*_last_*`.

## Hook / Dipendenze
- Nessun hook esplicito: dashboard di monitoraggio senza comandi.

## Riferimenti
- [docs/logic/core/regole_core_logiche.md](../core/regole_core_logiche.md)
- [docs/logic/core/README_sensori_clima.md](../core/README_sensori_clima.md)
- [docs/logic/core/regole_plancia.md](../core/regole_plancia.md)
- [README_ClimaSystem.md](../../../README_ClimaSystem.md)
- [docs/runtime_evidence/2026-03-01/REPORT_robot_romeo_baseline_for_vmc_reallocation_2026-03-01.md](../../runtime_evidence/2026-03-01/REPORT_robot_romeo_baseline_for_vmc_reallocation_2026-03-01.md)
