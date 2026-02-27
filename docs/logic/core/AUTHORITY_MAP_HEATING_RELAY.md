# Authority Map — Heating Relay

Date: 2026-02-27
Scope: runtime writer authority for physical heating relay.

## Physical actuator

- `switch.4_ch_interruttore_3`

## Direct writer (single-writer rule)

- `switch.heating_master` (template switch in `packages/climate_heating.yaml`)

## Non-writer logical gate

- `switch.heating_night_block` (template switch, logical only, no direct relay write)

## Upstream rule

- Any upstream automation/script must target `switch.heating_master` only.
- Upstream writers must not call `switch.turn_on/off` directly on `switch.4_ch_interruttore_3`.
