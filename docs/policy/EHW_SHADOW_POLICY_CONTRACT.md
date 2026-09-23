# EHW shadow policy contract

Status: DRAFT / SAFE-BLOCKED  
Owner chat: M63  
AEB ID: AEB-DHW-001  
Scope: Casa Mercurio ACS / EHW  
Last reviewed: 2026-09-23

## Outcome

Define a deterministic ACS/EHW decision policy that can run in shadow mode without
changing the real setpoint. Live promotion is outside this contract and requires a
separate explicit authorization.

## Authority boundary

The shadow package may:

- read EHW temperatures, setpoint, readiness and electrical state;
- read the existing surplus and grid direction abstractions;
- calculate an action, target and reason code;
- expose input ages and a compact evidence snapshot to Home Assistant history.

The shadow package must not:

- call `modbus.write_register` or any other service;
- toggle `input_boolean.climateops_dhw_request`;
- change `input_number.climateops_dhw_requested_setpoint`;
- replace the existing safe writer;
- infer or command a legionella cycle;
- participate in multi-load dispatch.

## Verified facts

- EHW setpoint feedback is exposed as `sensor.ehw_setpoint`.
- Tank temperatures are exposed as `sensor.ehw_tank_top` and
  `sensor.ehw_tank_bottom`.
- The safe writer targets Modbus register `1104` and has validated dry-run and
  narrow live-write paths.
- The vendor range for register `1104` is 10-60 degC. This is a transport range,
  not an approved operating policy.
- The installed unit is documented in the AEB digital twin as an Emmeti
  Eco Hot Water `EQ 3018 ES`, nominal capacity 300 L. The source is the 2021
  plant design plus the owner's confirmation that the installed ACS unit was
  not replaced.
- Dropbox contains `Ecohotwater.pdf`, Rev. A 04/2021, for the later/different
  `EQ 2021` and `EQ 3021 ES` models. It documents a configurable thermal ACS
  treatment for limiting Legionella, disabled by default and governed by
  parameters `g01..g04`. This is useful family evidence but is not accepted as
  model-specific authority for the installed `EQ 3018 ES`.
- `binary_sensor.policy_surplus_ok` has 2 minute ON and 3 minute OFF hysteresis.
- Grid direction and power are normalized through
  `binary_sensor.policy_grid_importing_now` and `sensor.policy_grid_power_w`.
- The tariff/grid layer is disabled by default and the real electricity contract
  is not yet documented.

## Unverified policy bounds

The following values remain provisional and cannot authorize even a shadow
recommendation until explicitly verified:

- minimum comfort temperature;
- normal operating target;
- maximum normal/preheat target;
- native `EQ 3018 ES` legionella schedule, authority, setpoint and current
  configuration;
- acceptable input freshness at runtime;
- user draw profile.

`input_boolean.ehw_shadow_limits_verified` and
`input_boolean.ehw_shadow_legionella_verified` therefore default to `off`.
While either is off, the required result is `BLOCK_LIMITS_UNVERIFIED` or
`BLOCK_LEGIONELLA_UNVERIFIED`.

## Inputs

| Input | Purpose | Missing/stale behavior |
|---|---|---|
| `binary_sensor.cm_modbus_ehw_ready` | EHW transport readiness | block |
| `sensor.ehw_tank_top` | primary comfort state | block |
| `sensor.ehw_tank_bottom` | stratification/evidence | block |
| `sensor.ehw_setpoint` | current real target | block |
| `sensor.ehw_operation_state` | demand/power diagnostics | evidence only |
| `binary_sensor.policy_surplus_ok` | existing surplus abstraction | hold |
| `sensor.grid_direction` | raw/canonical SDM120 import/export direction | hold |
| `sensor.grid_power_w` | raw/canonical SDM120 power | hold |
| `input_boolean.ehw_shadow_manual_override` | user authority | hold |
| `input_boolean.ehw_shadow_legionella_active` | observed/manual pass-through flag | hold |

Freshness is evaluated independently for tank top, tank bottom, setpoint, raw grid
direction and raw grid power. Default threshold is 180 seconds and is configurable. A stale or missing
temperature/setpoint input blocks the policy. A stale grid input prevents PV
preheat but does not prevent comfort recovery.

The shadow package intentionally does not use the periodically refreshed
`sensor.policy_grid_power_w` as freshness evidence: its timestamp can be newer
than the underlying meter sample. It also does not accept PV production alone as
proof of export.

## Decision priority

1. Shadow disabled.
2. Policy limits unverified.
3. Legionella authority unverified.
4. Manual override.
5. Legionella pass-through active.
6. Modbus/EHW not ready.
7. Temperature or setpoint data missing/stale.
8. Comfort recovery required.
9. Stable measured export and surplus permit preheat.
10. Otherwise maintain current target.

## Output contract

| Entity | Meaning |
|---|---|
| `sensor.ehw_shadow_action` | `BLOCK`, `HOLD`, `COMFORT_RECOVERY`, `PREHEAT`, `MAINTAIN` |
| `sensor.ehw_shadow_reason_code` | deterministic reason code |
| `sensor.ehw_shadow_proposed_target` | proposed setpoint, never written |
| `sensor.ehw_shadow_data_quality` | `READY`, `ENERGY_STALE`, `EHW_STALE`, `UNVERIFIED` |
| `binary_sensor.ehw_shadow_preheat_eligible` | export/surplus eligibility with 5 minute confirmation |

The action sensor attributes contain the evaluated inputs, ages and provisional
bounds. Home Assistant recorder history is the MVP log; no new database or
dashboard is required.

## Reason codes

- `SHADOW_DISABLED`
- `BLOCK_LIMITS_UNVERIFIED`
- `BLOCK_LEGIONELLA_UNVERIFIED`
- `HOLD_MANUAL_OVERRIDE`
- `HOLD_LEGIONELLA_PASS_THROUGH`
- `BLOCK_MODBUS_NOT_READY`
- `BLOCK_EHW_DATA_MISSING`
- `BLOCK_EHW_DATA_STALE`
- `RECOVER_COMFORT_LOW_TOP_TEMP`
- `PREHEAT_STABLE_GRID_EXPORT`
- `HOLD_ENERGY_DATA_MISSING`
- `HOLD_ENERGY_DATA_STALE`
- `HOLD_GRID_IMPORTING`
- `HOLD_NO_SURPLUS`
- `HOLD_AT_CURRENT_TARGET`

## KPI contract

The first shadow release must record enough evidence to calculate:

- number of decisions by action and reason code;
- share of time blocked by unverified limits or insufficient/stale data;
- number and duration of comfort-recovery recommendations;
- number and duration of eligible preheat windows;
- overlap between preheat recommendations and measured grid export;
- manual override count;
- safety block count.

Avoided kWh and EUR remain estimates until AEB-ENER-003 establishes a trustworthy
accounting and tariff baseline. They must not be labelled as measured savings.

## Promotion gate: SHADOW to LIVE

All conditions are mandatory:

- installed model remains `EQ 3018 ES`; its model-specific manufacturer
  operating constraints are verified;
- comfort minimum, normal target and maximum preheat target approved;
- native legionella behavior documented and left authoritative;
- at least 14 consecutive days of valid shadow history;
- zero safety violations and zero proposed target outside approved bounds;
- no comfort regression attributable to the proposed policy;
- stale/insufficient data below 5 percent of evaluated time;
- preheat recommendations coincide with real export, not production alone;
- benefit is measurable and not merely theoretical;
- safe writer remains single authority and immediate rollback is documented;
- explicit user authorization for live promotion.

## Pre-mortem gates

| Failure mode | Early signal | Countermeasure | Gate |
|---|---|---|---|
| Heat during false surplus | proposed preheat while importing | require stable export plus surplus | zero false-surplus promotions |
| Reduce hot-water comfort | repeated recovery/override | comfort recovery outranks optimization | no comfort regression |
| Oscillating targets | frequent action changes | 5 minute eligibility confirmation; live cooldown still TBD | decision churn reviewed |
| Stale sensor decisions | age exceeds threshold | explicit age checks and block/hold codes | stale share below 5 percent |
| Economically irrelevant gain | many windows, negligible shifted energy | keep EUR provisional; reconcile through AEB-ENER-003 | measurable benefit required |
