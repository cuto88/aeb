# README sensori MIRAI (Modbus)

Single source of truth per la mappa registri MIRAI usata in Home Assistant.

Documento canonico di mapping:
- [MIRAI_MODBUS_MAPPING.md](C:\2_OPS\aeb\docs\logic\core\MIRAI_MODBUS_MAPPING.md)

Riferimento vendor utile per discovery:
- [manual_mirai_address.md](C:\2_OPS\aeb\docs\vendor\mirai\manual_mirai_address.md)

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
| `sensor.mirai_discovery_pump_do4_9007_raw` | 1 | 9007 | `uint16` | 60s |
| `sensor.mirai_discovery_compressor_9043_raw` | 1 | 9043 | `uint16` | 60s |
| `sensor.mirai_discovery_target_9051_raw` | 1 | 9051 | `uint16` | 60s |
| `sensor.mirai_discovery_reference_9052_raw` | 1 | 9052 | `uint16` | 60s |
| `sensor.mirai_discovery_outdoor_8986_raw` | 1 | 8986 | `uint16` | 60s |
| `sensor.mirai_discovery_outlet_8987_raw` | 1 | 8987 | `uint16` | 60s |
| `sensor.mirai_discovery_inlet_8988_raw` | 1 | 8988 | `uint16` | 60s |
| `sensor.mirai_discovery_power_absorbed_9121_raw` | 1 | 9121 | `uint16` | 60s |

## Sensori template di riferimento

- File: `packages/mirai_templates.yaml`
- `binary_sensor.mirai_manual_unit_profile_ok`: `on` se il profilo manuale (`slave=1`) risponde con valore numerico.
- `sensor.mirai_status_word_effective`: priorita `u1`, fallback `raw` (allineato a slave 1).
- `sensor.mirai_status_code_effective`: priorita `u1`, fallback `raw` (allineato a slave 1).
- `sensor.mirai_fault_code_effective`: priorita `u1`, fallback `raw` (allineato a slave 1).
- `sensor.mirai_power_w_effective`: usa `sensor.mirai_power_w` se disponibile, altrimenti fallback diretto a `sensor.sensor_grid_power_w`.
- `sensor.mirai_probe_temp_a_c`: candidato temperatura scalata `x10` dal registro `4000` (dupliche coerenti su `9050/9086`).
- `sensor.mirai_probe_temp_b_c`: candidato temperatura scalata `x10` dal registro `3548` (duplica coerente su `9087`).
- `sensor.mirai_probe_temp_outdoor_c`: candidato temperatura scalata `x10` dal registro `3515`, ma mapping outdoor non confermato e attualmente sospetto; non trattarlo come verita' fisica esterna senza correlazione storica aggiuntiva.
- `binary_sensor.mirai_pump_candidate_running`: candidato storico stato pompa/runtime dal registro `3547`; non piu' candidato principale.
- `binary_sensor.mirai_pump_do4_running`: corroborazione pompa preferita dal registro `9007` (`L204`, DO4 circolatore PdC); oggi e` il segnale piu' promettente osservato sul campo.
- `binary_sensor.cm_modbus_mirai_ready`: usa `sensor.mirai_status_word_effective` per readiness reale.
- `binary_sensor.mirai_machine_running`: usa `status_word_effective` (bit 01) come semantica primaria di RUN, ma accetta anche un override da consumi quando `sensor.mirai_power_w` supera la soglia operativa pur con Modbus disponibile.
- `sensor.mirai_snapshot`: snapshot operativo allineato al profilo corrente `status_only_unit1`.

## Note operative

- Mappa aggiornata dopo riallineamento runtime del 7 marzo 2026:
  - MIRAI -> `192.168.178.191` / `slave 1`
  - EHW -> `192.168.178.190` / `slave 3`
- Bus RS-485 condiviso verificato sul campo il `2026-03-30`:
  - gateway/path TCP operativo per MIRAI e SDM120: `192.168.178.191:502`
  - MIRAI: `slave 1`, Modbus RTU `9600 8E1`
  - SDM120: `slave 2`, Modbus RTU `9600 8E1`
  - cablaggio corretto:
    - bianco/arancio = `A` / positivo
    - arancio = `B` / negativo
    - bianco/verde = `GND`
  - nota di campo: un precedente errore di cablaggio sul ramo SDM120 impediva la risposta Modbus; corretto il wiring, lo slave `2` e` tornato leggibile sullo stesso path di MIRAI.
- Il profilo MIRAI oggi e` volutamente `status-only` per il layer stabile; i registri extra restano come probe read-only lenti per audit mirato.
- I probe documentati attivi piu' utili oggi sono `9007`, `9051`, `9052`, `8986`, `8987`, `8988`, `9121`.
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
- Evidenza diretta `2026-03-30` su bus condiviso MIRAI+SDM120:
  - MIRAI (`192.168.178.191`, `slave 1`) continua a rispondere su `1003/1208/1209`
  - SDM120 (`192.168.178.191`, `slave 2`, `FC4`) risponde dopo correzione cablaggio:
    - `addr 0` tensione `229.599 V`
    - `addr 6` corrente `3.08 A`
    - `addr 12` potenza attiva `-224.136 W`
    - `addr 18` potenza apparente `706.55 VA`
    - `addr 30` power factor `-0.316`
    - `addr 70` frequenza `50.043 Hz`
    - `addr 72` energia importata `13.4 kWh`
  - package HA dedicato predisposto: `packages/sdm120_modbus.yaml`
  - i raw SDM120 sono integrati nello stesso hub `mirai` in `packages/mirai_modbus.yaml` per evitare il vincolo HA sui duplicati `host:port`
- Evidenza storica `2026-03-30` in HA:
  - `sensor.mirai_probe_temp_outdoor_c` e` rimasto piatto a `11.7°C` per tutta la giornata (range `0`), salvo brevi `unavailable`
  - `sensor.t_out` nello stesso intervallo ha variato circa `3.1°C -> 19.0°C`
  - conclusione operativa: il match puntuale serale `11.7°C == 11.7°C` non valida `3515` come vera sonda esterna
- Audit live 2026-04-08 / 2026-04-09:
  - `9007` promosso a miglior candidato pompa/circolatore
  - `9043` declassato: non discrimina `OFF` vs `RUN`
  - `9120/9121/9122/9123` declassati: a `0` anche in `RUN`
  - `9051/9052` promossi come segnali di controllo utili (`L561/L562`)
  - `8988` molto sospetto (`32768` fisso)
  - `8986/8987` restano candidati vivi ma da chiarire come scala/semantica fisica
- Nota password:
  - `PW 59` nel manuale corretto e` un livello menu/service dello Smart-MT, non una password Modbus documentata da inviare al bus.
- Questi valori sono trattati come `probe` finche' non vengono correlati con verita' fisica macchina/campo; non sono ancora promossi a naming semantico definitivo (`mandata`, `ritorno`, `ACS`, `esterna`) senza evidenza addizionale.
- Riferimenti vendor correnti:
  - `docs/vendor/mirai/manuale_pdc.md` (parametri RS-485: RTU 9600, 8E1, address 1, timeout 1000)
  - `docs/vendor/mirai/pdc_registers_review.md` e `docs/vendor/mirai/pdc_io_map.json`
- Nota: la documentazione vendor Mirai disponibile non espone una tabella completa `C4xx -> registro Modbus` numerico.
