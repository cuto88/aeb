# STEP28 EHW Runtime Closure (2026-03-07)
Date: 2026-03-07
Scope: chiudere EHW verificando stato runtime reale e risolvendo il blocco che impediva letture temperatura/setpoint scalate.

## Verifica runtime (host HA)
- `ha core check`: `Command completed successfully.`
- Stato EHW da `/homeassistant/.storage/core.restore_state`:
  - `binary_sensor.cm_modbus_ehw_ready = on`
  - `sensor.ehw_mapping_health = ok`
  - `binary_sensor.ehw_mapping_suspect = off`

## Problema emerso
- Le entita` scalate principali risultavano `unknown`:
  - `sensor.ehw_tank_top`
  - `sensor.ehw_tank_bottom`
  - `sensor.ehw_setpoint`
- Causa tecnica:
  - collisione entity_id storica su raw EHW (`sensor.ehw_tank_top_raw`, `sensor.ehw_tank_bottom_raw`, `sensor.ehw_setpoint_raw`);
  - nel registry erano presenti vecchie entita` orfane con gli stessi id, quindi i template nuovi erano finiti con suffisso `_2`;
  - i template di scala puntavano agli id senza suffisso, producendo `unknown`.

## Fix applicata nel repo
File aggiornato:
- `packages/ehw_modbus.yaml`

Modifica:
- introdotti id raw calcolati non conflittuali:
  - `sensor.ehw_tank_top_raw_calc`
  - `sensor.ehw_tank_bottom_raw_calc`
  - `sensor.ehw_setpoint_raw_calc`
- aggiornati tutti i riferimenti interni (scalati, running, mapping health, ready) ai nuovi id `*_calc`.

## Deploy runtime eseguito
- File deployato su host HA:
  - `/homeassistant/packages/ehw_modbus.yaml`
- Comandi eseguiti:
  - `ha core check` -> OK
  - `ha core restart` -> OK
  - `ha core check` post-restart -> OK

## Stato post-deploy (immediato)
- Le entita` `*_calc` sono presenti nel restore snapshot ma con stato iniziale `unknown` subito dopo restart.
- Nessun errore EHW esplicito rilevato nei log recenti filtrati.
- Nota: su questo host non e` disponibile `ha api`, quindi la verifica live puntuale degli stati correnti richiede UI o endpoint API alternativo.

## Root cause finale emersa
- La plancia risultava ancora poco utile per due motivi distinti:
1. collisione entity_id storica (`ehw_t01..t06_raw` con suffisso `_2`) risolta con fallback template;
2. endpoint runtime EHW (`ehw_modbus_host=192.168.178.191`, `ehw_modbus_slave=1`) rispondeva ma con molti registri temperatura a `0`.

Probe diretto Modbus ha mostrato valori EHW piu` utili su:
- `host 192.168.178.190`, `unit 3`, `fc3` (es. range 2019..2024 non zero).

Correzione applicata su runtime:
- `/homeassistant/secrets.yaml`
  - `ehw_modbus_host: 192.168.178.190`
  - `ehw_modbus_slave: 3`

Risultato verificato su recorder snapshot post-fix:
- `sensor.ehw_tank_top = 29.1`
- `sensor.ehw_tank_bottom = 43.5`
- `sensor.ehw_t04_finned_coil = 45.6`
- `sensor.ehw_t05_suction = 26.4`
- `sensor.ehw_t06_outlet_solar = 33.3`

UI:
- `lovelace/07_dhw_acs.yaml` allineata ai sensori utili (temperature/mapping), riducendo dipendenza da reg56/reg57 non informativi su questo profilo.

## Decisione
- Chiusura tecnica lato configurazione + deploy: **OK**.
- Chiusura funzionale EHW (plancia con valori utili): **OK**.

Riferimento successivo:
- riallineamento host/unit condiviso MIRAI+EHW consolidato in `STEP29_RUNTIME_HOST_UNIT_REALIGNMENT_2026-03-07.md`.

## Next step operativo
1. Verifica live post-restart (UI/Developer Tools -> States):
   - `sensor.ehw_tank_top`, `sensor.ehw_tank_bottom`, `sensor.ehw_setpoint` non piu` `unknown`;
   - `sensor.ehw_mapping_health = ok`;
   - `binary_sensor.ehw_mapping_suspect = off`.
