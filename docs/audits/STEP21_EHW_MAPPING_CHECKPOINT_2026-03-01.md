# STEP21 EHW Mapping Checkpoint + MIRAI Prep (2026-03-01)
Date: 2026-03-01
Scope: consolidare modifiche locali EHW/MIRAI, documentare baseline e preparare analisi runtime successiva.

## Changes consolidated
- EHW package (`packages/ehw_modbus.yaml`):
  - Polling diagnostico T01..T06 + setpoint raw portato a `180s` (riduzione churn Modbus).
  - `sensor.ehw_reg56_status` a `20s`.
  - Nuovi alias semantici temperatura:
    - `sensor.ehw_t01_inlet`
    - `sensor.ehw_t04_finned_coil`
    - `sensor.ehw_t05_suction`
    - `sensor.ehw_t06_outlet_solar`
  - Diagnostica mapping:
    - `sensor.ehw_mapping_health` (`ok` / `suspect_all_zero`)
    - `binary_sensor.ehw_mapping_suspect`

- Dashboard/documentazione EHW:
  - `lovelace/07_dhw_acs.yaml` aggiornata con diagnostica mapping + sonde semantiche.
  - `lovelace/06_power_runtime.yaml` aggiornata con card "EHW diagnostica mapping".
  - `docs/logic/core/README_sensori_ehw.md` e `docs/logic/energy_pm/plancia_mirai_ehw.md` allineati.

- MIRAI prep (`packages/mirai_modbus.yaml`, `packages/mirai_templates.yaml`):
  - Profilo runtime orientato a slave `3`, FC `3`, registri principali `1003/1208/1209`.
  - Introduzione `sensor.mirai_status_word_effective` per stabilizzare template bitwise e readiness.
  - Harden template numerici con fallback `none` (evita warning su stringhe non numeriche).

- Operations support:
  - `ops/mirai_scan_runtime.py`: scanner rapido registri runtime (quick/full) con unit/fc configurabili.
  - `ops/mirai_autowatch.py`: trigger automatico scansione su superamento soglia `sensor.mirai_power_w`.
  - Evidenza e razionale in `docs/audits/STEP20_MIRAI_VALUE_RECOVERY_2026-02-28.md`.

## Runtime status at checkpoint
- Stato EHW: mapping strutturato e diagnostica pronta per validazione evento-level.
- Stato MIRAI: base software consolidata; resta da chiudere validazione dinamica in finestra RUN reale.

## Next analysis (planned after this checkpoint)
1. Verifica runtime EHW su host HA (`/homeassistant`) con check post-restart:
   - `sensor.ehw_mapping_health`
   - `binary_sensor.ehw_mapping_suspect`
   - coerenza top/bottom/setpoint.
2. Correlazione eventi/tracce se emergono stati sospetti.
3. Verifica MIRAI durante finestra operativa reale e chiusura GO/NO-GO su registri definitivi.
