# STEP24 PM1 Reallocation Robot -> VMC (2026-03-01)
Date: 2026-03-01
Scope: documentare baseline consumi robot e integrare in Home Assistant la transizione della presa PM1 verso monitoraggio VMC.

## Baseline robot (Romeo) confermata
- Entita` analizzate:
  - `sensor.pm1_mss310_energy_kwh_main_channel`
  - `sensor.pm1_mss310_power_w_main_channel`
- Metriche:
  - Febbraio 2026: `2.675 kWh`
  - Ultimi 30 giorni: `2.881 kWh`
  - Media giornaliera ultimi 30 giorni: `0.0960 kWh/g`
  - Picco potenza ultimi 30 giorni: `32.824 W`
- Evidenze runtime locali:
  - `docs/runtime_evidence/2026-03-01/robot_romeo_energy_summary_2026-03-01.txt`
  - `docs/runtime_evidence/2026-03-01/robot_romeo_energy_daily_45d.csv`
  - `docs/runtime_evidence/2026-03-01/REPORT_robot_romeo_baseline_for_vmc_reallocation_2026-03-01.md`

## Integrazione applicata
- Nuovo package:
  - `packages/energy_vmc_reallocation.yaml`
- Contenuto principale:
  - KPI VMC potenza (`sensor.vmc_power_mean_15m`, `sensor.vmc_power_max_24h`) basati su PM1.
  - Baseline robot post-reallocation:
    - `input_number.robot_romeo_baseline_kwh_daily` (default `0.096`)
    - `input_number.robot_romeo_baseline_kwh_monthly` (default `2.675`)
  - La plancia consumi usa direttamente:
    - `sensor.pm1_mss310_power_w_main_channel` come **VMC W**
    - `sensor.pm1_energy_daily` come **VMC kWh/giorno**
    - `input_number.robot_romeo_baseline_kwh_*` come stima robot

## Documentazione aggiornata
- `docs/logic/energy_pm/README.md` aggiornato con riferimento al package di transizione.

## Validazione
- `ha core check`: **OK** (Command completed successfully).

## Nota operativa
- `docs/runtime_evidence/` e` escluso da git (`.gitignore`), quindi le evidenze restano in workspace operativo locale/host.
