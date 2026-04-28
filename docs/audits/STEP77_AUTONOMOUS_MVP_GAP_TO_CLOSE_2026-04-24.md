# STEP77 - Autonomous MVP gap to close

Date: 2026-04-24
Scope: define what "autonomous MVP 100%" means for Casa Mercurio / AEB and isolate the minimum remaining gaps before that label can be used honestly.

This step does not change runtime logic and does not authorize purchases by itself.

## FACT

- Observability continuity is now active:
  - scheduled runner validated
  - `LastTaskResult: 0`
  - recorder-independent evidence chain available
- Core ClimateOps authority baseline is closed.
- DHW/EHW writer path is closed for the conservative governed path.
- AC canonical driver bridge and reader feedback cleanup are closed enough to avoid raw-switch ambiguity in core readers.
- Field inspection is substantially closed:
  - gateways identified
  - branch measurement boundaries understood
  - wired serramenti contacts already physically present
  - CO2 first-wave physical posture known for `giorno` and `matrimoniale`
- `MIRAI` runtime truth is now closed through the 2026-04-24 Modbus-first observed run evidence pack.
- Wired contacts are physically present, but not yet promoted as a formal runtime I/O layer for BMS logic.
- CO2 sensors are not yet installed/integrated.
- Garage main door state sensing is still missing.

## IPOTESI

- Confidenza alta: "autonomous MVP 100%" should not mean "perfect system"; it should mean the minimum serious autonomous operating baseline is closed across control, feedback and observability.
- Confidenza alta: the project is now past the generic audit/discovery phase.
- Confidenza alta: after MIRAI truth closure, the remaining MVP blockers are not more architecture work, but integrating field signals that already physically exist or are already narrowly scoped.

## DECISIONE

- Define `Autonomous MVP 100%` with these minimum criteria:
  1. core runtime authority closed
  2. evidence/observability autonomous and stable
  3. main machine domains separated and understood
  4. minimum physical feedback loop present for key domains
  5. no critical BMS block depends only on manual/virtual placeholders where real signals already exist

## What is already closed

| area | status | note |
|---|---|---|
| HA/ClimateOps authority | closed | single-source runtime posture is mature |
| daily observability | closed | scheduler + evidence runner validated |
| DHW/EHW governed path | closed enough for MVP | conservative writer path validated |
| AC canonical runtime abstraction | closed enough for MVP | proxy/reader cleanup done; still not physical-proof grade |
| field discovery | substantially closed | enough physical clarity for bounded implementation |
| branch measurement boundaries | closed enough for MVP | `VMC`, `EHW`, `MIRAI`, shared `Toshiba AC` |

## What is NOT yet closed for Autonomous MVP 100%

### 1. Wired contact promotion

FACT
- Serramenti contacts already exist physically and are wired to the garage junction box.
- Runtime logic already has the full helper/aggregate window model, but it still relies on manual/virtual upstream helper states as the primary source boundary.

DECISIONE
- Existing wired contacts must be bound into the already existing helper/aggregate runtime model before claiming the opening-state layer is autonomous.

### 2. CO2 first wave

FACT
- Physical posture is known for `giorno` and `matrimoniale`.
- Sensors are not yet installed/integrated.

DECISIONE
- VMC can run without CO2, but the target autonomous MVP for serious BMS ventilation should include:
  - `CO2 giorno`
  - `CO2 matrimoniale`

### 3. Garage main door state

FACT
- It is the only known remaining opening-state hardware gap.

DECISIONE
- This is not the top blocker, but it is part of the residual physical completeness gap.

## Minimum gap-to-close sequence

1. `MIRAI runtime truth`
   - closed by `STEP81_MIRAI_MODBUS_FIRST_RUNTIME_TRUTH_CLOSURE_2026-04-24.md`

2. `wired contacts integration`
   - formalize the serramenti inputs as runtime physical signals
   - zone aggregation is enough; no need to over-model every sash first

3. `CO2 first wave`
   - `giorno`
   - `matrimoniale`

4. `garage main door sensor`
   - close the remaining opening-state hardware gap

## Not required before Autonomous MVP 100%

These can stay backlog and should not block the MVP label:

- exact RS485 biasing proof
- exact shield bonding point
- exact cable lengths
- CO2 in camera2/camera3
- premium IAQ (VOC/PM)
- gateway consolidation
- 12 V branch hardening upgrades
- broader hardware standardization

## MVP readiness verdict

FACT
- Software/control maturity is already high.
- Field understanding is now strong enough.

DECISIONE
- Current status: `Autonomous MVP 100% = NOT YET`.
- Closest honest wording today:
  - `software and observability baseline: closed enough`
  - `field/runtime closure: pending contact integration + CO2 first wave + garage main door state`

## Final decision

DECISIONE
- Stop broad discovery.
- Do not expand architecture scope.
- Use the next implementation effort only for the remaining MVP blockers:
  1. wired contacts integration
  2. CO2 giorno + matrimoniale
  3. garage main door state
