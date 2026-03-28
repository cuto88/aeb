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

## Sensori template di riferimento

- File: `packages/mirai_templates.yaml`
- `binary_sensor.mirai_manual_unit_profile_ok`: `on` se il profilo manuale (`slave=1`) risponde con valore numerico.
- `sensor.mirai_status_word_effective`: priorita `u1`, fallback `raw` (allineato a slave 1).
- `sensor.mirai_status_code_effective`: priorita `u1`, fallback `raw` (allineato a slave 1).
- `sensor.mirai_fault_code_effective`: priorita `u1`, fallback `raw` (allineato a slave 1).
- `binary_sensor.cm_modbus_mirai_ready`: usa `sensor.mirai_status_word_effective` per readiness reale.
- `binary_sensor.mirai_machine_running`: usa `status_word_effective` (bit 01) come semantica primaria di RUN, con fallback da consumi solo quando Modbus non e` disponibile.
- `sensor.mirai_snapshot`: snapshot operativo allineato al profilo corrente `status_only_unit1`.

## Note operative

- Mappa aggiornata dopo riallineamento runtime del 7 marzo 2026:
  - MIRAI -> `192.168.178.191` / `slave 1`
  - EHW -> `192.168.178.190` / `slave 3`
- Il profilo MIRAI oggi e` volutamente `status-only`: nel repo restano supportati solo i registri stabili `1003/1208/1209`.
- I registri estesi storici (`9058`, `9068`, `9078`, `9079`, `8986`, `8987`, `8988`) non fanno parte del profilo operativo corrente perche' hanno generato timeout/runtime noise nelle evidenze di fine febbraio.
- Nota storica: indicazioni STEP23 (01 marzo 2026) sono supersedute da validazione runtime successiva.
- Il fallback da consumi (`binary_sensor.mirai_machine_running_by_power`) resta attivo come resilienza se Modbus non risponde.
- Riferimenti vendor correnti:
  - `docs/vendor/mirai/manuale_pdc.md` (parametri RS-485: RTU 9600, 8E1, address 1, timeout 1000)
  - `docs/vendor/mirai/pdc_registers_review.md` e `docs/vendor/mirai/pdc_io_map.json`
- Nota: la documentazione vendor Mirai disponibile non espone una tabella completa `C4xx -> registro Modbus` numerico.
