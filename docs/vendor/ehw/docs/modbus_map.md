# EHW Modbus Register Map (from `ehw.json`)

Source note: `parameters.json` was not found in this folder; this map is derived from `ehw.json`.

## Assumptions (explicit)

- Register addresses are used exactly as documented (no `-1` offset applied).
- `T01..T06` are treated as read-only temperature points in degrees Celsius.
- Non-`Txx` parameters are treated as writable holding registers where applicable.
- Data type is conservatively `int16` with scale `1` unless documented otherwise.
- Modbus function code is **not** documented in the source; register type below is inferred and marked as uncertain.

## Register Table

| Code | Register | Meaning | Access (inferred) | Register Type (inferred) | Data Type (inferred) | Unit | Scale (inferred) | Range | Default | Notes |
|---|---:|---|---|---|---|---|---:|---|---|---|
| /01 | 1020 | OUT5 (2-solar pump, 5-low flow alarm) | RW | Holding (?) | int16 | enum | 1 | 2/5 | 5 | Enum-like field, writable assumption uncertain |
| H30 | 1076 | Modbus address | RW | Holding (?) | int16 | id | 1 | 1-255 | 3 | Likely slave ID; writing may disrupt communication |
| n03 | 1082 | Temperature differential of solar water pump starting | RW | Holding (?) | int16 | °C | 1 | 0-20 °C | 5 °C | Temperature parameter, writable assumption uncertain |
| n09 | 1088 | The set point of solar drainage valve | RW | Holding (?) | int16 | °C | 1 | 50-90 °C | 78 °C | Temperature parameter, writable assumption uncertain |
| n10 | 1089 | The stop point of solar water pump | RW | Holding (?) | int16 | °C | 1 | 50-90 °C | 70 °C | Temperature parameter, writable assumption uncertain |
| r01 | 1104 | Dot water temperature set point | RW | Holding (?) | int16 | °C | 1 | 10-60 °C | 53 °C | Temperature parameter, writable assumption uncertain |
| r03 | 1106 | The temperature differential in heating mode | RW | Holding (?) | int16 | °C | 1 | 1-20 °C | 15 °C | Temperature parameter, writable assumption uncertain |
| r06 | 1109 | The delay time of starting up the electrical heater | RW | Holding (?) | int16 | min | 1 | 0-450 min | 200 min | Time parameter, writable assumption uncertain |
| T01 | 2019 | Inlet temp. sensor | RO | Input (?) | int16 | °C | 1 | - | reading | Read-only assumption from sensor naming |
| T02 | 2020 | Water tank top temp. sensor | RO | Input (?) | int16 | °C | 1 | - | reading | Read-only assumption from sensor naming |
| T03 | 2021 | Water tank bottom temp. sensor | RO | Input (?) | int16 | °C | 1 | - | reading | Read-only assumption from sensor naming |
| T04 | 2022 | Finned coil temp. sensor | RO | Input (?) | int16 | °C | 1 | - | reading | Read-only assumption from sensor naming |
| T05 | 2023 | Suction temp. sensor | RO | Input (?) | int16 | °C | 1 | - | reading | Read-only assumption from sensor naming |
| T06 | 2024 | Outlet temp / Solar temp. sensor | RO | Input (?) | int16 | °C | 1 | - | reading | Read-only assumption from sensor naming |

