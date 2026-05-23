# STEP29 Runtime Host/Unit Realignment (2026-03-07)
Date: 2026-03-07
Scope: chiudere il disallineamento MIRAI/EHW su host/unit Modbus e aggiornare `secrets.yaml` runtime.

## Esito sintetico
- Mapping runtime valido (con evidenza probe):
  - **MIRAI** -> `192.168.178.191`, `slave/unit=1`, `FC3`
  - **EHW** -> `192.168.178.190`, `slave/unit=3`, `FC3`
- Le indicazioni precedenti (STEP23, 2026-03-01) sono **supersedute** da validazione runtime del 2026-03-07.

## Evidenza tecnica (probe diretto)
- `192.168.178.190 / unit3 / fc3`:
  - MIRAI: `1003=0`, `1208=0`, `1209=0`
  - EHW temp: `2019=97`, `2020=144`, `2021=152`, `2022=88`, `2023=110`, `2024=90`
  - EHW param: `1082=70`, `1088=216`, `1089=200`, `1104=150`, `1106=70`
- `192.168.178.191 / unit1 / fc3`:
  - MIRAI: `1003=1`, `1208=128`, `1209=32768`
  - EHW: blocchi principali temperatura a `0`

## Correzioni applicate
1. Runtime `secrets.yaml` (`/homeassistant/secrets.yaml`):
   - `mirai_modbus_host: 192.168.178.191`
   - `ehw_modbus_host: 192.168.178.190`
   - `ehw_modbus_slave: 3`
2. `packages/mirai_modbus.yaml`:
   - sensori `mirai_*_raw` allineati a `slave: 1` (stesso profilo runtime valido),
   - rimosso polling operativo su profilo non rispondente.
3. `packages/ehw_modbus.yaml`:
   - mantenuto profilo utile su `190/unit3`,
   - ridotto polling dei registri legacy `56/57/60` (non affidabili su questo profilo) per ridurre rumore.
4. UI:
   - `lovelace/08_mirai_plant.yaml` allineata al profilo MIRAI runtime, con rimozione duplicati diagnostici non piu` utili.

## Verifica post-restart
- `ha core check`: OK
- `ha core restart`: OK
- Snapshot stati (post-fix):
  - MIRAI:
    - `sensor.mirai_u1_status_word_raw = 1`
    - `sensor.mirai_u1_status_code_raw = 128`
    - `sensor.mirai_u1_fault_code_raw = 32768`
    - `binary_sensor.mirai_manual_unit_profile_ok = on`
  - EHW:
    - `sensor.ehw_tank_top = 29.1`
    - `sensor.ehw_tank_bottom = 42.9`
    - `sensor.ehw_t04_finned_coil = 45.6`
    - `sensor.ehw_t05_suction = 26.7`
    - `sensor.ehw_t06_outlet_solar = 32.4`

## Decisione
- Riallineamento runtime host/unit: **OK**
- Chiusura operativa MIRAI+EHW su mappa aggiornata: **OK**
