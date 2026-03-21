# STEP34 Runtime Refresh Audit (2026-03-13)
Date: 2026-03-13
Scope: refresh audit runtime live su Home Assistant per verificare stato host, validita' config, coerenza package deployati e posizione corrente EHW/MIRAI dopo Step33.

## Contesto
- Host runtime verificato via SSH: `core-ssh`, utente `root`.
- Data host al momento del check: `Fri Mar 13 20:27:56 CET 2026`.
- Questo step include introspezione live read-only sul nodo Home Assistant.

## Verifiche eseguite (FACT)
1. Core runtime raggiungibile e configurazione valida
   - `ha core info`:
     - `version: 2026.3.1`
     - `boot: true`
     - `update_available: false`
   - `ha core check` -> `Command completed successfully.`

2. Package runtime deployati coerenti con asset repo
   - ` /homeassistant/packages/ehw_modbus.yaml` presente e leggibile.
   - I registri legacy EHW `56/57/60` risultano ancora configurati a polling raro `21600`.
   - `/homeassistant/packages/climateops/actuators/system_actuator.yaml` presente e leggibile.
   - `automation.climateops_system_actuate` risulta deployata con `stored_traces: 30`.

3. Snapshot runtime EHW live
   - `binary_sensor.cm_modbus_ehw_ready = on`
   - `sensor.ehw_mapping_health = ok`
   - `binary_sensor.ehw_mapping_suspect = off`
   - `sensor.ehw_tank_top = 29.4` (`last_changed: 2026-03-13T19:01:48Z`)
   - `sensor.ehw_tank_bottom = 42.6` (`last_changed: 2026-03-13T18:58:48Z`)
   - `sensor.ehw_t01_raw_b = 98` (`2026-03-13T19:01:48Z`)
   - `sensor.ehw_t06_raw_b = 94` (`2026-03-13T19:07:50Z`)
   - `sensor.ehw_reg56_status = unavailable`
   - `sensor.ehw_reg57_runtime = unavailable`
   - `sensor.ehw_reg60_value = unavailable`

4. Snapshot runtime MIRAI live
   - `binary_sensor.cm_modbus_mirai_ready = on`
   - `sensor.mirai_power_w = 4.1` (`last_changed: 2026-03-13T19:16:28Z`)
   - `sensor.mirai_snapshot.state = 2026-03-13 20:16:00`
   - Attributi principali `sensor.mirai_snapshot`:
     - `machine_source = MODBUS`
     - `machine_running_power = off`
     - `status_word_effective = 1`
     - `status_bits_on = bit 00`
     - `status_code_effective = 128`
     - `fault_code_effective = 32768`
     - `machine_state = OFF`
   - Raw MIRAI aggiornati oggi:
     - `sensor.mirai_status_word_raw = 1` (`2026-03-13T12:45:56Z`)
     - `sensor.mirai_status_code_raw = 128` (`2026-03-13T12:45:56Z`)
     - `sensor.mirai_fault_code_raw = 32768` (`2026-03-13T12:45:56Z`)

5. Log runtime recenti
   - Errori EHW legacy ancora presenti sui registri noti:
     - `2026-03-13 19:46:20` -> `device: 3 address: 56`
     - `2026-03-13 19:46:33` -> `device: 3 address: 57`
     - `2026-03-13 19:46:46` -> `device: 3 address: 60`
   - Presente anche un errore applicativo:
     - `2026-03-13 15:25:00.527 ERROR ... automation.climateops_system_actuate`
     - il traceback visibile parte da stack `urllib3/http.client`, quindi il failure sembra legato a una chiamata HTTP/socket durante l'esecuzione dell'automation.

6. Tracce ClimateOps presenti
   - In `/homeassistant/.storage/trace.saved_traces` risultano entry recenti per `climateops_system_actuate`.
   - Questo conferma che il writer chain e' ancora tracciato lato runtime.

## Valutazione
### Core runtime
- Stato: **PASS**
- Nodo raggiungibile, core avviato e configurazione valida al `2026-03-13`.

### EHW
- Stato: **PASS**
- La catena utile EHW resta viva:
  - readiness `on`
  - mapping `ok`
  - temperature aggiornate oggi
- I fault su `56/57/60` restano coerenti con il comportamento legacy gia' noto e non cambiano la valutazione operativa.

### MIRAI
- Stato: **PARZIALE**
- Rispetto a Step32 c'e' un miglioramento di freshness:
  - raw/status risultano aggiornati oggi, non piu' fermi al `2026-03-07`
- Tuttavia non emerge ancora evidenza di `RUN` reale:
  - `mirai_power_w` resta idle (`4.1 W`)
  - `machine_state = OFF`
  - `machine_running_power = off`
- Quindi il gap forense principale non e' ancora chiuso.

### ClimateOps automation health
- Stato: **ATTENZIONE**
- L'automation principale ha tracciamento attivo e tracce presenti, ma nei log compare almeno un errore il `2026-03-13`.
- Senza analisi completa del traceback non e' ancora classificabile come regressione sistemica, ma va messo in follow-up.

## Decisione
- Runtime host/config al `2026-03-13`: **GO**
- EHW runtime current state: **GO**
- MIRAI closure completa: **HOLD**
- ClimateOps automation reliability: **WATCH**

## Next step operativo
1. Eseguire una finestra osservata MIRAI di `45-60 min` in domanda reale per cercare transizione `OFF -> RUN`.
2. Durante la finestra acquisire:
   - `sensor.mirai_power_w`
   - `sensor.mirai_status_word_effective`
   - `sensor.mirai_machine_state`
   - `sensor.mirai_snapshot`
3. Aprire un follow-up dedicato sul log error di `automation.climateops_system_actuate` del `2026-03-13 15:25:00`.
4. Se la finestra MIRAI conferma `RUN`, chiudere con uno step finale di runtime closure marzo.

## Esito finale
- Stato runtime corrente: **validato**
- Stato EHW: **stabile**
- Stato MIRAI: **ancora non chiuso in RUN reale**
- Nuovo punto da monitorare: **errore sporadico su `automation.climateops_system_actuate`**
