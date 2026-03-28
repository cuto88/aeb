# README sensori MIRAI (Modbus)

Single source of truth per la mappa registri MIRAI usata in Home Assistant.

## Hub Modbus

- Hub: `mirai`
- File: `packages/mirai_modbus.yaml`
- Protocollo: Modbus TCP
- Host: `!secret mirai_modbus_host`
- Porta: `502`
- Profilo attivo:
  - runtime su `slave/unit=1` (profilo valido)
  - sensori `*_raw` mantenuti per compatibilita` ma allineati a `slave/unit=1`

## Registri attivi (stato/fault)

| Entity ID | Slave | Registro | Tipo | Scan |
|---|---:|---:|---|---:|
| `sensor.mirai_u1_status_word_raw` | 1 | 1003 | `uint16` | 30s |
| `sensor.mirai_u1_status_code_raw` | 1 | 1208 | `uint16` | 30s |
| `sensor.mirai_u1_fault_code_raw` | 1 | 1209 | `uint16` | 30s |
| `sensor.mirai_status_word_raw` | 1 | 1003 | `uint16` | 30s |
| `sensor.mirai_status_code_raw` | 1 | 1208 | `uint16` | 30s |
| `sensor.mirai_fault_code_raw` | 1 | 1209 | `uint16` | 30s |
| `sensor.mirai_probe_temp_a_raw` | 1 | 4000 | `uint16` | 30s |
| `sensor.mirai_probe_temp_a_dup_9050_raw` | 1 | 9050 | `uint16` | 30s |
| `sensor.mirai_probe_temp_a_dup_9086_raw` | 1 | 9086 | `uint16` | 30s |
| `sensor.mirai_probe_temp_b_raw` | 1 | 3548 | `uint16` | 30s |
| `sensor.mirai_probe_temp_b_dup_9087_raw` | 1 | 9087 | `uint16` | 30s |
| `sensor.mirai_probe_temp_outdoor_raw` | 1 | 3515 | `uint16` | 30s |
| `sensor.mirai_probe_counter_1015_raw` | 1 | 1015 | `uint16` | 30s |
| `sensor.mirai_probe_state_3547_raw` | 1 | 3547 | `uint16` | 30s |

## Sensori template di riferimento

- File: `packages/mirai_templates.yaml`
- `binary_sensor.mirai_manual_unit_profile_ok`: `on` se il profilo manuale (`slave=1`) risponde con valore numerico.
- `sensor.mirai_status_word_effective`: priorita `u1`, fallback `raw` (allineato a slave 1).
- `sensor.mirai_status_code_effective`: priorita `u1`, fallback `raw` (allineato a slave 1).
- `sensor.mirai_fault_code_effective`: priorita `u1`, fallback `raw` (allineato a slave 1).
- `sensor.mirai_power_w_effective`: usa `sensor.mirai_power_w` se disponibile, altrimenti fallback diretto a `sensor.sensor_grid_power_w`.
- `sensor.mirai_probe_temp_a_c`: candidato temperatura scalata `x10` dal registro `4000` (dupliche coerenti su `9050/9086`).
- `sensor.mirai_probe_temp_b_c`: candidato temperatura scalata `x10` dal registro `3548` (duplica coerente su `9087`).
- `sensor.mirai_probe_temp_outdoor_c`: candidato temperatura scalata `x10` dal registro `3515`.
- `binary_sensor.mirai_pump_candidate_running`: candidato stato pompa/runtime dal registro `3547`; oggi e` `on` con valori ~`22528/22784` e `off` con valori ~`9984`.
- `binary_sensor.cm_modbus_mirai_ready`: usa `sensor.mirai_status_word_effective` per readiness reale.
- `binary_sensor.mirai_machine_running`: usa `status_word_effective` (bit 01) come semantica primaria di RUN, ma accetta anche un override da consumi quando `sensor.mirai_power_w` supera la soglia operativa pur con Modbus disponibile.
- `sensor.mirai_snapshot`: snapshot operativo allineato al profilo corrente `status_only_unit1`.

## Note operative

- Mappa aggiornata dopo riallineamento runtime del 7 marzo 2026:
  - MIRAI -> `192.168.178.191` / `slave 1`
  - EHW -> `192.168.178.190` / `slave 3`
- Il profilo MIRAI oggi e` volutamente `status-only`: nel repo restano supportati solo i registri stabili `1003/1208/1209`.
- I registri estesi storici (`9058`, `9068`, `9078`, `9079`, `8986`, `8987`, `8988`) non fanno parte del profilo operativo corrente perche' hanno generato timeout/runtime noise nelle evidenze di fine febbraio.
- Nota storica: indicazioni STEP23 (01 marzo 2026) sono supersedute da validazione runtime successiva.
- Il fallback da consumi (`binary_sensor.mirai_machine_running_by_power`) resta attivo come resilienza se Modbus non risponde.
- Il ramo consumi operativo usa `sensor.mirai_power_w_effective` per evitare che un alias template fermo blocchi la rilevazione RUN.
- La soglia iniziale `input_number.mirai_running_power_on_w` e` fissata a `150 W`: deriva da evidenza runtime recente con idle ~`3-5 W` e assorbimento macchina attiva ~`232 W`. E` un’inferenza operativa, non una semantica ufficiale del registro `1003`.
- `sensor.mirai_machine_running_source` puo` riportare `POWER_OVERRIDE` quando il mapping Modbus non riflette una partenza reale ma i consumi mostrano macchina attiva.
- Evidenza diretta `2026-03-28` fuori da HA:
  - `4000 = 340`, `9050 = 340`, `9086 = 340` -> candidato comune `34.0°C`
  - `3548 = 338`, `9087 = 338` -> candidato comune `33.8°C`
  - `3515 = 117` -> candidato `11.7°C`
- Evidenza acceso/spento `2026-03-28`:
  - `3547` ~`22528/22784` con macchina in marcia
  - `3547` ~`9984` con macchina spenta
  - `3548/9087` ~`34.4°C -> 29.5°C` nella transizione da acceso a spento
- Questi valori sono trattati come `probe` finche' non vengono correlati con verita' fisica macchina/campo; non sono ancora promossi a naming semantico definitivo (`mandata`, `ritorno`, `ACS`, `esterna`) senza evidenza addizionale.
- Riferimenti vendor correnti:
  - `docs/vendor/mirai/manuale_pdc.md` (parametri RS-485: RTU 9600, 8E1, address 1, timeout 1000)
  - `docs/vendor/mirai/pdc_registers_review.md` e `docs/vendor/mirai/pdc_io_map.json`
- Nota: la documentazione vendor Mirai disponibile non espone una tabella completa `C4xx -> registro Modbus` numerico.
