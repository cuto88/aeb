# STEP25 MIRAI Manual Addr1 + Fallback Addr3 (2026-03-01)
Date: 2026-03-01
Scope: allineare il runtime Mirai al manuale RS-485 (address 1) mantenendo continuita' operativa con fallback address 3.

## Input dal manuale vendor
- Protocollo seriale RS-485 / Modbus RTU
- Address: `1`
- Timeout: `1000`
- Nota: baud/parita' (`9600`, `E 8.1`) sono parametri seriali del gateway RS485, non del client Modbus TCP in HA.

## Modifiche applicate
- `packages/mirai_modbus.yaml`
  - aggiunti probe manual profile (`slave: 1`):
    - `sensor.mirai_u1_status_word_raw` (reg 1003)
    - `sensor.mirai_u1_status_code_raw` (reg 1208)
    - `sensor.mirai_u1_fault_code_raw` (reg 1209)
  - mantenuti i sensori raw runtime (`slave: 3`) come fallback operativo:
    - `sensor.mirai_status_word_raw`
    - `sensor.mirai_status_code_raw`
    - `sensor.mirai_fault_code_raw`

- `packages/mirai_templates.yaml`
  - `sensor.mirai_status_word_effective`: priorita' `u1`, fallback `raw`.
  - aggiunti:
    - `sensor.mirai_status_code_effective` (u1 -> fallback raw)
    - `sensor.mirai_fault_code_effective` (u1 -> fallback raw)
    - `binary_sensor.mirai_manual_unit_profile_ok` (ON se `u1` risponde numericamente)
  - `mirai_snapshot` esteso con attributi di verifica profilo.

## Verifica runtime
- Deploy completato su `/homeassistant/packages/`.
- `ha core check`: OK.
- `ha core restart`: OK.
- Nuove entita' presenti in `core.entity_registry`:
  - `sensor.mirai_u1_status_word_raw`
  - `sensor.mirai_u1_status_code_raw`
  - `sensor.mirai_u1_fault_code_raw`
  - `binary_sensor.mirai_manual_unit_profile_ok`
  - `sensor.mirai_status_code_effective`
  - `sensor.mirai_fault_code_effective`

## Esito
- Configurazione ora robusta rispetto alla divergenza manuale/runtime:
  - aderenza al manuale (addr 1) quando disponibile,
  - fallback trasparente su addr 3 finche' necessario.
