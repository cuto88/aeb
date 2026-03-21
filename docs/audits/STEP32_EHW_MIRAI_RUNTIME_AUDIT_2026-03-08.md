# STEP32 EHW + MIRAI Runtime Audit (2026-03-08)
Date: 2026-03-08
Scope: audit runtime read-only post-Step28/29 per verificare tenuta EHW e stato corrente MIRAI sul nodo Home Assistant.

## Contesto
- Host runtime verificato via SSH: `core-ssh`, utente `root`.
- Data host al momento del check: `Sun Mar 8 18:53:56 CET 2026`.
- Core info:
  - `version: 2026.3.1`
  - `boot: true`

## Verifiche eseguite (FACT)
1. EHW runtime host/config
   - path config confermato: `/homeassistant`
   - file runtime letto: `/homeassistant/packages/ehw_modbus.yaml`
   - profilo deployato coerente con Step29:
     - registri legacy `56/57/60` mantenuti ma con polling molto raro (`21600s`)
     - blocco temperature `T01..T06` su polling `180s`

2. EHW log runtime recenti
   - nei log recenti sono presenti errori su registri legacy:
     - `2026-03-08 15:44:28` -> `device: 3 address: 56`
     - `2026-03-08 15:44:40` -> `device: 3 address: 57`
     - `2026-03-08 15:44:52` -> `device: 3 address: 60`
   - questi errori sono coerenti con il vincolo gia' documentato: su profilo utile `192.168.178.190 / unit 3 / FC3` i registri `56/57/60` non sono affidabili.

3. EHW snapshot stati runtime (`/homeassistant/.storage/core.restore_state`)
   - `binary_sensor.cm_modbus_ehw_ready = on`
   - `sensor.ehw_mapping_health = ok`
   - `binary_sensor.ehw_mapping_suspect = off`
   - `sensor.ehw_tank_top = 30.6` (`last_changed: 2026-03-08T17:29:57.986411+00:00`)
   - `sensor.ehw_tank_bottom = 43.8` (`last_changed: 2026-03-08T17:05:57.453182+00:00`)
   - `sensor.ehw_t01_raw_b = 102` (`2026-03-08T17:29:57.849899+00:00`)
   - `sensor.ehw_t03_raw_b = 152` (`2026-03-08T17:23:58.009974+00:00`)
   - `sensor.ehw_t04_raw_b = 91` (`2026-03-08T17:32:58.474900+00:00`)
   - `sensor.ehw_t05_raw_b = 118` (`2026-03-08T17:14:58.119850+00:00`)
   - `sensor.ehw_t06_raw_b = 92` (`2026-03-08T17:38:59.251997+00:00`)
   - `sensor.ehw_reg56_status = unavailable`
   - `sensor.ehw_reg57_runtime = unavailable`
   - `sensor.ehw_reg60_value = unavailable`

4. MIRAI log runtime recenti
   - nessun errore `mirai` o `pymodbus: mirai` emerso nell'estratto log piu' recente interrogato (`ha core logs --lines 400` filtrato).

5. MIRAI snapshot stati runtime (`/homeassistant/.storage/core.restore_state`)
   - `sensor.mirai_power_w = 4.0` (`last_changed: 2026-03-08T17:43:55.824462+00:00`)
   - `sensor.mirai_snapshot.state = 2026-03-08 18:44:00`
   - attributi `sensor.mirai_snapshot`:
     - `machine_source = MODBUS`
     - `machine_running_power = off`
     - `status_word_effective = 1`
     - `status_bits_on = bit 00`
     - `status_code_effective = 128`
     - `fault_code_effective = 32768`
     - `machine_state = OFF`
   - segnali raw/foundation risultano pero' non aggiornati oggi:
     - `sensor.mirai_u1_status_word_raw = 1` (`last_changed: 2026-03-07T14:43:27.754686+00:00`)
     - `sensor.mirai_status_word_raw = 1` (`last_changed: 2026-03-07T14:43:27.755281+00:00`)
     - `sensor.mirai_status_code_raw = 128` (`last_changed: 2026-03-07T14:43:27.755832+00:00`)
     - `sensor.mirai_fault_code_raw = 32768` (`last_changed: 2026-03-07T14:43:27.755451+00:00`)
     - `binary_sensor.cm_modbus_mirai_ready = on` (`last_changed: 2026-03-07T14:44:05.955147+00:00`)

## Valutazione
### EHW
- Stato: **PASS**
- Il mapping utile EHW risulta vivo e coerente con Step28/29.
- `mapping_health=ok` e `mapping_suspect=off` restano validi.
- I fault su `56/57/60` non sono un regressivo nuovo: confermano che quei registri legacy non vanno usati come segnale operativo primario.

### MIRAI
- Stato: **PARZIALE**
- Il ramo power/snapshot e' vivo oggi (`sensor.mirai_power_w`, `sensor.mirai_snapshot` aggiornati il 2026-03-08).
- Non emerge pero' una nuova evidenza di transizione reale `RUN` nella finestra audit corrente.
- I raw Modbus chiave (`status_word/status_code/fault_code`) risultano ancora fermi al `2026-03-07`, quindi oggi non c'e' chiusura forense addizionale sul piano "RUN reale" richiesto da Step20.

## Decisione
- EHW runtime closure: **confermata**
- MIRAI runtime closure completa: **non ancora estesa**
- Esito audit complessivo: **GO per EHW / HOLD per validazione MIRAI in RUN reale**

## Next step operativo
1. Eseguire una finestra osservata MIRAI di `45-60 min` in richiesta reale.
2. Durante la finestra, acquisire:
   - `sensor.mirai_power_w`
   - `sensor.mirai_status_word_effective`
   - `sensor.mirai_machine_state`
   - `sensor.mirai_snapshot`
3. Correlare la finestra con scansione on-demand:
   - `python ops/mirai_scan_runtime.py --rounds 6 --interval 20 --profile quick`
4. Criterio di chiusura:
   - almeno una transizione reale `OFF -> RUN` oppure variazione coerente dei registri raw/status durante assorbimento non idle.
