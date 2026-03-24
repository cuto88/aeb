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

Profilo runtime attivo (aggiornato 2026-03-07):
- host: `192.168.178.190`
- slave/unit: `3`
- FC: `3` (holding)

Nota: il profilo storico `192.168.178.191 / slave 1` resta documentato ma non e` il profilo con dati termici utili in esercizio.

Sorgenti vendor correnti:
- `docs/vendor/ehw/ehw.json` (mappa parametri/registri estratta)
- `docs/vendor/ehw/docs/modbus_map.md` (tabella tecnica leggibile)
- `docs/vendor/ehw/exports/modbus_map.csv` (export per confronto)
- `docs/vendor/ehw/homeassistant/modbus_solar.yaml` (esempio HA, da trattare come bozza con assunzioni)

---

## Current runtime checkpoint (2026-03-23)

Stato consolidato dopo gli audit `STEP38` -> `STEP42`:

- `input_select.ehw_address_mode = doc_0_based`
- `sensor.ehw_setpoint_raw_a` e` il path raw live usato in runtime
- `sensor.ehw_setpoint_raw_calc` segue il raw live
- `sensor.ehw_setpoint` e` coerente come feedback scalato
- la catena read/feedback DHW e` chiusa e validata a runtime

Writer DHW attuale:

- writer formale in `packages/climateops_dhw_writer.yaml`
- singolo writer logico: `automation.climateops_dhw_writer_execute`
- target write validato: holding register `1104`
- gate runtime:
  - `input_boolean.climateops_cutover_dhw`
  - `input_boolean.climateops_dhw_write_enable`
  - `input_boolean.climateops_dhw_dry_run`
  - `input_boolean.climateops_dhw_request`
- default sicuri:
  - `cutover_dhw = off`
  - `write_enable = off`
  - `dry_run = on`
  - `request = off`

Osservabilita` writer:

- `sensor.climateops_dhw_actual_feedback`
- `sensor.climateops_dhw_expected_feedback`
- `binary_sensor.climateops_dhw_feedback_matches_expected`
- `binary_sensor.climateops_dhw_permitted`
- `sensor.climateops_dhw_blocked_reason`
- `input_text.climateops_dhw_write_result`
- `input_datetime.climateops_dhw_last_write_ts`

Boundary corrente:

- writer-path readiness: `CLOSED`
- planner-driven DHW actuation: `NOT ENABLED`
- multi-load orchestration / load shifting: `NOT ENABLED`
- UI/plancia operativa aggiornata in `lovelace/climate_casa_unified_plancia.yaml`

---

## Entity map (canonical)

| Entity ID canonico                 | Tipo           | Source (reg / FC) | Scala | Unità | Significato / note |
|------------------------------------|----------------|-------------------|-------|-------|--------------------|
| `sensor.ehw_reg56_status`          | modbus sensor  | 56 / FC3 holding  | 1:1   | raw   | Status word (uint16) |
| `sensor.ehw_reg57_runtime`         | modbus sensor  | 57 / FC3 holding  | 1:1   | raw   | Runtime word (uint16) |
| `sensor.ehw_reg60_value`           | modbus sensor  | 60 / FC3 holding  | 1:1   | raw   | Observed value (uint16), visto stabile a 0x002D/45 |
| `sensor.ehw_reg1082_solar_pump_delta_start` | modbus sensor | 1082 / FC3 holding | 1:1 | raw | Delta start circolatore solare (vendor param) |
| `sensor.ehw_reg1088_solar_drain_valve_setpoint` | modbus sensor | 1088 / FC3 holding | 1:1 | raw | Setpoint valvola scarico solare (vendor param) |
| `sensor.ehw_reg1089_solar_pump_stop_setpoint` | modbus sensor | 1089 / FC3 holding | 1:1 | raw | Setpoint stop circolatore solare (vendor param) |
| `sensor.ehw_reg1106_dhw_setpoint_delta` | modbus sensor | 1106 / FC3 holding | 1:1 | raw | Delta setpoint ACS (vendor param) |
| `sensor.ehw_reg1109_electric_heater_delay` | modbus sensor | 1109 / FC3 holding | 1:1 | raw | Ritardo riscaldatore elettrico (vendor param) |
| `sensor.ehw_reg1255_modbus_address` | modbus sensor | 1255 / FC3 holding | 1:1 | raw | Indirizzo Modbus configurato (vendor param) |
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
| `sensor.ehw_t01_inlet`            | template sensor| T01 raw -> °C     | alias semantico |
| `sensor.ehw_t04_finned_coil`      | template sensor| T04 raw -> °C     | alias semantico |
| `sensor.ehw_t05_suction`          | template sensor| T05 raw -> °C     | alias semantico |
| `sensor.ehw_t06_outlet_solar`     | template sensor| T06 raw -> °C     | alias semantico |
| `sensor.ehw_mapping_health`       | template sensor| checks runtime    | `ok` / `suspect_all_zero` |
| `binary_sensor.ehw_mapping_suspect`| template binary| mapping health   | true se mapping sospetto |

---

## Known constraints

- Su profilo runtime `190/unit3`, i registri `56/57/60` non sono affidabili per stato macchina e possono risultare non disponibili.
- Le temperature utili provengono dal blocco `2019..2024` e dai parametri `1082/1088/1089/1104/1106`.
- In caso di transport instability (`transaction_id mismatch`), il package riduce il polling
  dei registri diagnostici (T01..T06 + setpoint raw) a 180s per ridurre rumore Modbus.

---

## Validation procedure (modpoll)

Assunzioni runtime correnti: Modbus TCP, slave 3, host `192.168.178.190`, addressing 0-based (PDU), FC3 holding.

1) Leggi frame 50–81 in hex:
```
modpoll -m tcp -a 3 -r 50 -c 32 -t 4:hex 192.168.178.190
```

2) Leggi singoli registri 56/57/60:
```
modpoll -m tcp -a 3 -r 2019 -c 6 -t 4:hex 192.168.178.190
modpoll -m tcp -a 3 -r 1082 -c 1 -t 4:hex 192.168.178.190
modpoll -m tcp -a 3 -r 1088 -c 1 -t 4:hex 192.168.178.190
```
