# STEP37 Runtime Refresh Follow-up (2026-03-21)
Date: 2026-03-21
Scope: follow-up runtime read-only su Home Assistant per aggiornare la freshness del checkpoint marzo e verificare la posizione corrente di MIRAI/ClimateOps dopo Step36.

## Contesto
- Host runtime verificato via SSH: `core-ssh`, utente `root`.
- Data host al momento del check: `Sat Mar 21 20:23:10 CET 2026`.
- Questo step usa solo introspezione read-only (`ha core info`, `ha core check`, log core, artefatti `.storage`).

## Verifiche eseguite (FACT)
1. Core runtime raggiungibile e configurazione valida
   - `ha core info`:
     - `version: 2026.3.2`
     - `version_latest: 2026.3.3`
     - `boot: true`
     - `update_available: true`
   - `ha core check` -> `Command completed successfully.`

2. Log runtime recenti
   - Nei log recenti filtrati non emergono errori `mirai`, `pymodbus: mirai`, `switchbot`, `tuya` o nuovi abort `automation.climateops_system_actuate`.
   - Restano presenti solo i fault legacy EHW gia' noti:
     - `2026-03-20 14:00:38` -> `device: 3 address: 56`
     - `2026-03-20 14:00:50` -> `device: 3 address: 57`
     - `2026-03-20 14:01:03` -> `device: 3 address: 60`
     - stesso pattern ricorrente anche il `2026-03-21 20:17:*`

3. Stato runtime MIRAI da `core.restore_state`
   - `sensor.mirai_power_w = 4.8`
     - `last_updated: 2026-03-21T19:31:50.906440+00:00`
   - `binary_sensor.cm_modbus_mirai_ready = on`
     - `last_updated: 2026-03-20T13:16:53.221389+00:00`
   - `sensor.mirai_machine_state = OFF`
     - `last_updated: 2026-03-20T13:16:53.173831+00:00`
   - `sensor.mirai_snapshot.state = 2026-03-21 20:31:00`
     - `last_updated: 2026-03-21T19:31:50.907662+00:00`

4. Attributi principali `sensor.mirai_snapshot`
   - `manual_unit_profile_ok = on`
   - `machine_source = MODBUS`
   - `machine_running_power = off`
   - `mirai_power_w = 4.8`
   - `status_word_raw = 1`
   - `status_word_effective = 1`
   - `status_bits_on = bit 00`
   - `status_code_effective = 128`
   - `fault_code_effective = 32768`
   - `machine_state = OFF`

5. ClimateOps traces/log health
   - Nei log recenti interrogati non compare un nuovo errore `automation.climateops_system_actuate`.
   - Questo non chiude ancora forensicamente il fix Step35-36, ma e' coerente con una fase di osservazione senza nuovi abort visibili nel campione controllato.

## Valutazione
### Core runtime
- Stato: **PASS**
- Nodo raggiungibile, configurazione valida e core operativo al `2026-03-21`.

### MIRAI
- Stato: **PARZIALE / HOLD**
- Il ramo MIRAI e' vivo:
  - `cm_modbus_mirai_ready = on`
  - `sensor.mirai_power_w` e `sensor.mirai_snapshot` aggiornati oggi
  - profilo runtime coerente (`unit 1`, sorgente `MODBUS`)
- Tuttavia non c'e' ancora evidenza di `RUN` reale:
  - `mirai_power_w` resta idle (`4.8 W`)
  - `machine_running_power = off`
  - `machine_state = OFF`
- Il gap forense principale resta quindi aperto.

### ClimateOps automation health
- Stato: **WATCH migliorato**
- Nel campione log letto oggi non emergono nuovi abort dell'automation principale.
- L'assenza di errore nel campione e' un segnale positivo, ma non equivale ancora a closure definitiva del problema cloud-dependent.

### EHW legacy noise
- Stato: **NOTO / INVARIATO**
- Persistono i fault legacy sui registri `56/57/60`, gia' classificati come rumore non bloccante.

## Decisione
- Runtime host/config al `2026-03-21`: **GO**
- ClimateOps post-hardening: **WATCH / nessuna regressione evidente nel campione**
- MIRAI closure completa: **HOLD**
- Priorita' operativa invariata: raccogliere una finestra con MIRAI in domanda reale

## Next step operativo
1. Osservare una finestra reale MIRAI di `45-60 min` con richiesta termica attiva.
2. Durante la finestra acquisire:
   - `sensor.mirai_power_w`
   - `sensor.mirai_status_word_effective`
   - `sensor.mirai_machine_state`
   - `sensor.mirai_snapshot`
3. Se emerge transizione `OFF -> RUN`, chiudere con un nuovo step di closure runtime marzo.

## Esito finale
- Freshness runtime marzo: **aggiornata**
- ClimateOps: **nessuna nuova anomalia evidente nel campione letto**
- MIRAI: **ancora non chiuso in RUN reale**
