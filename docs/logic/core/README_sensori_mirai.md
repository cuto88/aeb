# README sensori MIRAI (Modbus)

Single source of truth per la mappa registri MIRAI usata in Home Assistant.

## Hub Modbus

- Hub: `mirai`
- File: `packages/mirai_modbus.yaml`
- Protocollo: Modbus TCP
- Host: `!secret mirai_modbus_host`
- Porta: `502`
- Profilo attivo:
  - probe manuale vendor su `slave/unit=1`
  - fallback runtime su `slave/unit=3`

## Registri attivi (stato/fault)

| Entity ID | Slave | Registro | Tipo | Scan |
|---|---:|---:|---|---:|
| `sensor.mirai_u1_status_word_raw` | 1 | 1003 | `uint16` | 30s |
| `sensor.mirai_u1_status_code_raw` | 1 | 1208 | `uint16` | 30s |
| `sensor.mirai_u1_fault_code_raw` | 1 | 1209 | `uint16` | 30s |
| `sensor.mirai_status_word_raw` | 3 | 1003 | `uint16` | 30s |
| `sensor.mirai_status_code_raw` | 3 | 1208 | `uint16` | 30s |
| `sensor.mirai_fault_code_raw` | 3 | 1209 | `uint16` | 30s |

## Sensori template di riferimento

- File: `packages/mirai_templates.yaml`
- `binary_sensor.mirai_manual_unit_profile_ok`: `on` se il profilo manuale (`slave=1`) risponde con valore numerico.
- `sensor.mirai_status_word_effective`: priorita `u1`, fallback `raw` (slave 3).
- `sensor.mirai_status_code_effective`: priorita `u1`, fallback `raw` (slave 3).
- `sensor.mirai_fault_code_effective`: priorita `u1`, fallback `raw` (slave 3).
- `binary_sensor.cm_modbus_mirai_ready`: usa `sensor.mirai_status_word_effective` per readiness reale.

## Note operative

- Mappa aggiornata dopo audit runtime del 1 marzo 2026 (STEP23/STEP25).
- Non invertire IP Mirai/EHW: la validazione runtime ha confermato mapping attuale.
- Il fallback da consumi (`binary_sensor.mirai_machine_running_by_power`) resta attivo come resilienza se Modbus non risponde.
- Riferimenti vendor correnti:
  - `docs/vendor/mirai/manuale_pdc.md` (parametri RS-485: RTU 9600, 8E1, address 1, timeout 1000)
  - `docs/vendor/mirai/pdc_registers_review.md` e `docs/vendor/mirai/pdc_io_map.json`
- Nota: la documentazione vendor Mirai disponibile non espone una tabella completa `C4xx -> registro Modbus` numerico.
