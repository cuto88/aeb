# BMS Field Layer / RS485 Topology Plan (2026-04-22)

## Scope

Piano topologico non-esecutivo per il field layer Casa Mercurio / AEB.

Obiettivo:
- evitare acquisti o aggiunte RS485 impulsive
- fissare la struttura target del bus
- distinguere cosa e` gia` validato da cosa e` ipotizzato
- preparare le future scelte su CO2, finestre, metering HVAC e I/O cablati

Questo documento non modifica runtime e non abilita nuovi writer.

## Sources

- `docs/logic/core/runtime_hardware_profiles.md`
- `packages/mirai_modbus.yaml`
- `packages/sdm120_modbus.yaml`
- `packages/ehw_modbus_transport.yaml`
- `packages/ehw_modbus.yaml`
- `docs/audits/BMS_ARCHITECTURE_SENSOR_AUDIT_2026-04-22.md`
- `docs/audits/BMS_PHYSICAL_SENSOR_ACTUATOR_INVENTORY_2026-04-22.md`
- `docs/audits/STEP60_ROI_CLOSURE_BACKLOG_2026-04-22.md`

## Executive position

FACT
- RS485/Modbus is already useful in the current system.
- MIRAI and SDM120 are already combined under the Home Assistant Modbus hub named `mirai`.
- EHW/ACS uses a separate Home Assistant Modbus hub named `ehw_modbus`.
- SDM120 is validated as the canonical grid meter source.
- MIRAI branch and Modbus readiness are observable, but MIRAI runtime truth under real run is still not closed.
- EHW read/write path is already more mature than MIRAI actuation readiness.

IPOTESI (confidenza alta)
- The next ROI gain is not "more Modbus devices"; it is a controlled field topology that prevents bus instability, polling overload and diagnostic ambiguity.

DECISION
- Do not add new RS485 slaves before the physical topology is documented.
- Do not put comfort-room sensing on RS485 by default; use RS485 mainly for technical field devices, DIN modules, I/O and meters.
- Use PoE or powered local nodes for room IAQ where cabling allows it.

## Current field topology

| bus / hub | function | endpoint | serial params | slave | device | status | role |
|---|---|---|---|---|---|---|---|
| `mirai` | PDC + grid meter bus | `!secret mirai_modbus_host`:502 | `9600 8E1` | `1` | MIRAI / PDC | PARTIAL | diagnostics / runtime truth pending |
| `mirai` | PDC + grid meter bus | same endpoint | `9600 8E1` | `2` | SDM120 | VALIDATED | canonical grid power/energy |
| `ehw_modbus` | ACS / EHW | `!secret ehw_modbus_host`: `!secret ehw_modbus_port` | UNKNOWN in repo | `!secret ehw_modbus_slave` | EHW / ACS | VALIDATED for current path | read/write ACS |

FACT
- Home Assistant cannot reliably load two separate Modbus hubs on the same `host:port`; SDM120 raw transport is intentionally integrated into the `mirai` hub.
- Current MIRAI hub parameters:
  - `delay: 2`
  - `timeout: 1`
  - `retries: 0`
  - `message_wait_milliseconds: 30`
  - `retry_on_empty: true`
  - `close_comm_on_error: true`
- SDM120 confirmed registers use FC4/input, float32 big-endian, two registers:
  - `0` voltage
  - `6` current
  - `12` active power
  - `18` apparent power
  - `30` power factor
  - `70` frequency
  - `72` import energy

IPOTESI (confidenza media)
- EHW may be on a different RS485/Ethernet gateway or different logical transport; the repo uses separate secrets and a separate hub, so it must be treated as an independent bus until proven otherwise.

DECISION
- Treat current architecture as two field segments:
  1. `MIRAI + SDM120` technical bus
  2. `EHW/ACS` technical bus

## Physical wiring facts currently known

FACT
- `MIRAI + SDM120` path is `192.168.178.191:502`.
- Operating serial params for that path are `9600 8E1`.
- Validated addresses:
  - MIRAI: `slave 1`
  - SDM120: `slave 2`
- Corrected SDM120 wiring:
  - white/orange = `A` / positive
  - orange = `B` / negative
  - white/green = `GND`
- A previous wiring error on SDM120 prevented Modbus response; correcting wiring restored readability.

UNKNOWN
- cable type and total length
- exact gateway model
- whether termination resistors are present
- whether biasing is provided by the gateway
- exact physical bus order
- shield handling
- separation from power cables
- EHW physical topology, serial parameters and gateway model

DECISION
- These unknowns must be resolved by physical inspection before adding slaves.

## Target topology principle

DECISION
- Keep RS485 as a technical-field bus, not a whole-house gadget bus.

Recommended split:

| segment | target use | should include | should not include |
|---|---|---|---|
| Technical HVAC bus | PDC, ACS, thermal plant telemetry | MIRAI, EHW if physically appropriate, hydronic sensors, HVAC technical I/O | room comfort gadgets |
| Electrical / DIN bus | energy and relay/I/O in panel | SDM meters, DIN digital input modules, DIN relay feedback modules | loose plug meters |
| Room IAQ / comfort | room CO2/T/RH/presence | PoE/powered local nodes, ESPHome Ethernet/PoE, selected cabling | battery cloud sensors as control-grade |
| Advisory wireless | non-critical supplemental data | temporary sensors, hard-to-cable positions | primary BMS feedback |

IPOTESI (confidenza alta)
- One overloaded mixed RS485 bus is worse than two or three clear segments.

DECISION
- Future additions should prefer a new segment/gateway when the existing bus is already carrying critical HVAC or meter data.

## Add-new-slave rules

Before adding any RS485 slave:

1. FACT
   - Every slave must have a unique address.
   - The current `mirai` bus already uses slave `1` and `2`.

2. DECISION
   - Reserve addresses:
     - `1`: MIRAI
     - `2`: SDM120 grid meter
     - `3-9`: future DIN meters on the same electrical segment only if bus health remains good
     - `10-19`: DIN digital input modules, preferably on a dedicated I/O segment
     - `20-29`: HVAC technical I/O
     - `30+`: temporary lab/probe devices only

3. DECISION
   - Never add a slave without recording:
     - physical location
     - bus segment
     - address
     - baud/parity
     - register map source
     - polling interval
     - owner package
     - fallback behavior

4. DECISION
   - New Modbus sensors start as raw/diagnostic with slow polling.
   - Promotion to canonical/control-grade happens only after repeated runtime evidence.

## Polling policy

FACT
- The MIRAI hub currently includes a mix of:
  - 30 s status/probe sensors
  - 60 s discovery probes
  - 30 s SDM120 grid meter reads
- EHW has:
  - very slow status registers at `21600 s`
  - configuration/status reads around `300 s`
  - tank raw reads around `180 s`

IPOTESI (confidenza alta)
- Polling load and timeout behavior are a real stability risk on shared Modbus TCP/RS485 gateways.

DECISION
- Polling classes:

| class | interval | examples | notes |
|---|---:|---|---|
| control feedback | 10-30 s | grid power, branch readiness, critical run bit | only if bus proven stable |
| operational telemetry | 30-60 s | PDC state, pump/compressor candidate registers | acceptable for runtime truth |
| thermal slow telemetry | 120-300 s | tank temperatures, hydronic temperatures | enough for ACS/radiant systems |
| static/config registers | 300-21600 s | addresses, setpoints, status words that change rarely | avoid churn |
| discovery probes | 60-300 s | unknown candidate registers | disable after validation window |

DECISION
- Do not poll room comfort sensors over the same critical HVAC bus at fast intervals.

## Cabling and electrical rules

FACT
- At least one previous field fault was caused by incorrect RS485 wiring.

DECISION
- Physical checklist before any expansion:
  - use twisted pair for A/B
  - keep GND/reference where device/gateway documentation requires it
  - avoid star topology where possible
  - use daisy-chain trunk with short stubs
  - document bus order physically
  - separate RS485 from mains/power cable routes
  - terminate only at the two physical ends of a long bus
  - verify whether gateway provides biasing
  - label A/B/GND at every device
  - record photo evidence of terminals after changes

IPOTESI (confidenza media)
- For a residential retrofit, practical cable paths may force compromises; if topology becomes star-like, use additional gateways instead of forcing one electrically poor bus.

DECISION
- Prefer more gateways over one noisy undocumented bus.

## What should go to RS485

High fit:
- DIN energy meters for AC/VMC/loads
- DIN digital input modules for window/door contact aggregation
- technical HVAC I/O in plant room
- hydronic technical temperature modules if vendor/installer path supports it
- relay state feedback or dry contact status modules

Medium fit:
- T/RH in technical areas
- panel temperature/humidity
- utility room sensors

Low fit:
- CO2 in living/night rooms, unless an RS485 room sensor has clean cabling and local serviceability
- occupancy/presence sensors in rooms
- battery replacement-only retrofits where PoE is easier

DECISION
- CO2 target should likely be PoE/powered local node first, RS485 only if the physical path is already clean.

## What should not go to RS485 now

DECISION
- Do not move everything to RS485.
- Do not add RS485 relay modules for AC IR control until AC feedback/authority is defined.
- Do not add extra PDC probes until MIRAI runtime truth is closed.
- Do not add window contacts directly to the MIRAI/SDM120 bus if a separate DI segment is practical.
- Do not put experimental unknown registers into high-frequency polling.

## ROI-specific field additions

| priority | addition | preferred field layer | why | prerequisite |
|---|---|---|---|---|
| 1 | AC/VMC metering | DIN Modbus meter or reliable local Ethernet meter | real actuator feedback | panel line identification |
| 2 | window contacts by zone | DIN DI over RS485 or wired local node | replaces virtual window state | cable path and grouping plan |
| 3 | CO2 giorno/notte | PoE/powered local node | IAQ-grade VMC input | placement plan |
| 4 | hydronic diagnostics | Modbus/vendor path or wired probes | MIRAI/heating diagnostics | MIRAI truth closure |
| 5 | relay feedback | DI/aux contact | verifies commands | panel review |

DECISION
- First hardware-side field work should be measurement/feedback, not new actuation.

## Failure modes and observability

For every segment, define:
- gateway reachable
- bus read success
- last successful update
- stale threshold
- expected branch powered/off semantics
- `ready` binary sensor
- `reason` sensor
- raw value retained for audit
- canonical alias only after validation

FACT
- The project already uses branch power semantics for AC/MIRAI.

DECISION
- Reuse that pattern for future bus segments:
  - `*_expected_ready`
  - `*_posture_ok`
  - `*_reason`
  - raw sensor availability separate from operator-facing readiness

## Documentation artifact required before purchases

DECISION
- Create or fill a physical field map before buying modules:

| field | value |
|---|---|
| segment name | |
| gateway model | |
| IP / port | |
| serial settings | |
| cable type | |
| estimated length | |
| topology | |
| termination present | |
| biasing present | |
| shield/GND policy | |
| slave list | |
| polling owner package | |
| failure mode | |
| fallback behavior | |

## Immediate next action

DECISION
- Since the manual MIRAI run window is not available now, the next non-runtime action is:
  1. physically identify the RS485 gateway model and cable route for `192.168.178.191:502`
  2. document whether SDM120 and MIRAI are on one daisy chain and in which order
  3. inspect/record termination and GND handling
  4. identify whether EHW is on a separate gateway/bus

## Final decision

DECISION
- Do not buy RS485 modules yet.
- Do not add new Modbus slaves yet.
- Keep MIRAI/SDM120 bus stable.
- Treat EHW as independent until field inspection proves otherwise.
- Design future field expansion around feedback and observability first:
  - AC/VMC power feedback
  - physical window contacts
  - CO2 powered sensing
  - hydronic diagnostics only after MIRAI truth closure
