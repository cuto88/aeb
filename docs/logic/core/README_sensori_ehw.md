# EcoHotWater (EHW) — ENTITY MAP (canonical)

Single source of truth per le entità EHW via Modbus TCP.
Tutti i package EHW **devono** usare **esattamente** questi `entity_id`.

> Nota: naming in inglese, descrizioni in italiano.
> Legacy archived on 2026-02-06 (ex `packages/climate_ehw_modbus.yaml`).

---

## Overview (scope)

Questa mappa copre il layer Modbus TCP EcoHotWater con lettura di registri holding
(FC3, addressing 0-based/PDU). Include sensori raw, hex decoding e flag binari da
status word.

Manuale di riferimento previsto in: `docs/vendor/ehw/Ecohotwater 2021 - manual_compressed.pdf`.

---

## Entity map (canonical)

| Entity ID canonico                 | Tipo           | Source (reg / FC) | Scala | Unità | Significato / note |
|------------------------------------|----------------|-------------------|-------|-------|--------------------|
| `sensor.ehw_reg56_status`          | modbus sensor  | 56 / FC3 holding  | 1:1   | raw   | Status word (uint16) |
| `sensor.ehw_reg57_runtime`         | modbus sensor  | 57 / FC3 holding  | 1:1   | raw   | Runtime word (uint16) |
| `sensor.ehw_reg60_value`           | modbus sensor  | 60 / FC3 holding  | 1:1   | raw   | Observed value (uint16), visto stabile a 0x002D/45 |
| `sensor.ehw_status_word_hex`       | template sensor| reg56             | n/a   | hex   | Status word formattato 0x%04X |
| `sensor.ehw_runtime_word_hex`      | template sensor| reg57             | n/a   | hex   | Runtime word formattato 0x%04X |
| `binary_sensor.ehw_status_bit_0100`| template binary| reg56             | n/a   | bool  | Bit 0x0100 (mask 256) |
| `binary_sensor.ehw_status_bit_0200`| template binary| reg56             | n/a   | bool  | Bit 0x0200 (mask 512) |

---

## Legacy compatibility entities (kept in canonical module)

Queste entità sono mantenute per retro-compatibilità con plance/automazioni esistenti.

| Entity ID legacy                  | Tipo           | Source            | Note |
|-----------------------------------|----------------|-------------------|------|
| `input_select.ehw_address_mode`   | input_select   | helper            | doc_1_based vs doc_0_based |
| `input_boolean.ehw_swap_top_bottom`| input_boolean | helper            | swap sonda top/bottom |
| `input_number.ehw_temp_scale`     | input_number   | helper            | scala temperatura |
| `input_number.ehw_temp_offset`    | input_number   | helper            | offset temperatura |
| `input_number.ehw_setpoint_scale` | input_number   | helper            | scala setpoint |
| `input_number.ehw_setpoint_offset`| input_number   | helper            | offset setpoint |
| `sensor.ehw_t01_raw_a`            | modbus sensor  | reg 2018          | raw A |
| `sensor.ehw_t01_raw_b`            | modbus sensor  | reg 2019          | raw B |
| `sensor.ehw_t02_raw_a`            | modbus sensor  | reg 2019          | raw A |
| `sensor.ehw_t02_raw_b`            | modbus sensor  | reg 2020          | raw B |
| `sensor.ehw_t03_raw_a`            | modbus sensor  | reg 2020          | raw A |
| `sensor.ehw_t03_raw_b`            | modbus sensor  | reg 2021          | raw B |
| `sensor.ehw_t04_raw_a`            | modbus sensor  | reg 2021          | raw A |
| `sensor.ehw_t04_raw_b`            | modbus sensor  | reg 2022          | raw B |
| `sensor.ehw_t05_raw_a`            | modbus sensor  | reg 2022          | raw A |
| `sensor.ehw_t05_raw_b`            | modbus sensor  | reg 2023          | raw B |
| `sensor.ehw_t06_raw_a`            | modbus sensor  | reg 2023          | raw A |
| `sensor.ehw_t06_raw_b`            | modbus sensor  | reg 2024          | raw B |
| `sensor.ehw_setpoint_1104_raw_a`  | modbus sensor  | reg 1103          | raw A |
| `sensor.ehw_setpoint_1104_raw_b`  | modbus sensor  | reg 1104          | raw B |
| `sensor.ehw_setpoint_1105_raw_a`  | modbus sensor  | reg 1104          | raw A |
| `sensor.ehw_setpoint_1105_raw_b`  | modbus sensor  | reg 1105          | raw B |
| `sensor.ehw_t01_raw`              | template sensor| raw A/B           | selector input_select |
| `sensor.ehw_t02_raw`              | template sensor| raw A/B           | selector input_select |
| `sensor.ehw_t03_raw`              | template sensor| raw A/B           | selector input_select |
| `sensor.ehw_t04_raw`              | template sensor| raw A/B           | selector input_select |
| `sensor.ehw_t05_raw`              | template sensor| raw A/B           | selector input_select |
| `sensor.ehw_t06_raw`              | template sensor| raw A/B           | selector input_select |
| `sensor.ehw_setpoint_raw_a`       | template sensor| 1104 raw          | selector input_select |
| `sensor.ehw_setpoint_raw_b`       | template sensor| 1105 raw          | selector input_select |
| `sensor.ehw_tank_top_raw`         | template sensor| T02/T03           | swap top/bottom |
| `sensor.ehw_tank_bottom_raw`      | template sensor| T02/T03           | swap top/bottom |
| `sensor.ehw_setpoint_raw`         | template sensor| raw A/B           | selector input_select |
| `sensor.ehw_tank_top`             | template sensor| raw -> °C         | scale/offset |
| `sensor.ehw_tank_bottom`          | template sensor| raw -> °C         | scale/offset |
| `sensor.ehw_setpoint`             | template sensor| raw -> °C         | scale/offset |
| `sensor.ehw_delta_stratificazione`| template sensor| top-bottom        | Δ°C |
| `sensor.ehw_status`               | template sensor| binary            | In funzione/Spento |
| `binary_sensor.ehw_running`       | template binary| top/setpoint      | setpoint - top >= 1.0 |

---

## Known constraints

- Il setpoint **non è esposto in chiaro**: il cambio setpoint si riflette su reg56/reg57,
  mentre reg60 resta 0x002D/45 nei test.

---

## Validation procedure (modpoll)

Assunzioni: Modbus TCP, slave 1, addressing 0-based (PDU), FC3 holding.

1) Leggi frame 50–81 in hex:
```
modpoll -m tcp -a 1 -r 50 -c 32 -t 4:hex 192.168.178.191
```

2) Leggi singoli registri 56/57/60:
```
modpoll -m tcp -a 1 -r 56 -c 1 -t 4:hex 192.168.178.191
modpoll -m tcp -a 1 -r 57 -c 1 -t 4:hex 192.168.178.191
modpoll -m tcp -a 1 -r 60 -c 1 -t 4:hex 192.168.178.191
```
