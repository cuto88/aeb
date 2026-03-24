# STEP38 - DHW Derived Chain Closure (2026-03-22)

## Scope

Close the DHW derived setpoint feedback chain in live Home Assistant runtime after the selector mismatch and `raw_calc` mapping failure identified in AEB-01.

No DHW writer is implemented in this step.

## Prior Failure Mode

Before the fix, live runtime had:

- `input_select.ehw_address_mode = doc_1_based`
- proven live setpoint path on the `raw_b` branch during field test
- `sensor.ehw_setpoint_raw_calc = 0`
- `sensor.ehw_setpoint = 0.0`

Then, after the selector correction to `doc_0_based`, live runtime still showed:

- `input_select.ehw_address_mode = doc_0_based`
- `sensor.ehw_setpoint_raw_a = 150`
- `sensor.ehw_setpoint_raw_b = 0`
- `sensor.ehw_setpoint_raw_calc = 0`
- `sensor.ehw_setpoint = 0.0`

Failure cause: under `doc_0_based`, `sensor.ehw_setpoint_raw_calc` was still selecting the wrong exposed raw sensor.

## Applied Fix Path

File patched:

- `packages/ehw_modbus.yaml`

Minimal corrective path applied:

1. `input_select.ehw_address_mode`
   - default changed to `doc_0_based`
   - startup automation added to enforce `doc_0_based` at Home Assistant start because live restore-state was forcing `doc_1_based`

2. `sensor.ehw_setpoint_raw_calc`
   - `doc_0_based` branch changed to read `sensor.ehw_setpoint_raw_a`

No change was made to:

- underlying Modbus diagnostic raw sensors
- exposed diagnostic visibility of `sensor.ehw_setpoint_raw_a`
- exposed diagnostic visibility of `sensor.ehw_setpoint_raw_b`
- any DHW writer/control path

## Deploy / Restart Method

Live deploy method used:

- single-file copy of `packages/ehw_modbus.yaml` to `/homeassistant/packages/ehw_modbus.yaml`
- `ha core restart && ha core check`

Result:

- restart completed successfully
- config check completed successfully

## Post-Deploy Runtime Evidence

Read-only runtime verification after deploy/restart:

| Entity | Live value | Interpretation |
|---|---:|---|
| `input_select.ehw_address_mode` | `doc_0_based` | selector fixed and effective |
| `sensor.ehw_setpoint_raw_a` | `150` | live exposed raw path |
| `sensor.ehw_setpoint_raw_b` | `0` | alternate exposed raw path |
| `sensor.ehw_setpoint_raw_calc` | `150` | derived raw chain now follows live path |
| `sensor.ehw_setpoint` | `45.0` | scaled setpoint now coherent with raw chain |

Coherence result: `YES`

## Closure Decision

Decision: `DERIVED CHAIN CLOSED`

What is now closed:

- DHW runtime health feedback: available
- DHW exposed raw feedback: coherent with live runtime branch
- DHW derived raw feedback: coherent
- DHW scaled setpoint feedback: coherent

What is still missing:

- no DHW writer/control path has been implemented yet

## Next Step Boundary

This audit closes the DHW read/feedback chain sufficiently for **DHW writer candidate validation** to begin next.

It does **not** mean DHW actuation is already safe or implemented.
