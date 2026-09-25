# EHW shadow policy contract

Status: DRAFT / SAFE-BLOCKED  
Owner chat: M63  
AEB ID: AEB-DHW-001  
Scope: Casa Mercurio ACS / EHW  
Last reviewed: 2026-09-24

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
- The model-specific Emmeti manual `E7000670C` for `EQ 2018 / EQ 3018 ES`
  documents a 9-60 degC water operating field and a user setpoint of 10-60
  degC in 0.5 degC increments. The validated writer register `1104` exposes the
  same 10-60 degC setpoint range. This is a manufacturer boundary, not by
  itself an approved comfort/preheat policy.
- The installed unit is documented in the AEB digital twin as an Emmeti
  Eco Hot Water `EQ 3018 ES`, nominal capacity 300 L. The source is the 2021
  plant design plus the owner's confirmation that the installed ACS unit was
  not replaced.
- The same model-specific manual documents a thermal ACS treatment for limiting
  Legionella with factory parameters: `g01=60 degC` (range 30-70), `g02=0 min`
  (range 0-90), `g03=0 h` (range 0-23), and `g04=7 d` (range 7-99). The factory
  treatment is effectively disabled by the zero-minute duration. These defaults
  do not prove the current installed configuration.
- Dropbox also contains `Ecohotwater.pdf`, Rev. A 04/2021, for the later
  `EQ 2021 / EQ 3021 ES` generation. It is retained as family evidence but is
  not the authority for installed-unit limits.
- `binary_sensor.policy_surplus_ok` has 2 minute ON and 3 minute OFF hysteresis.
- Grid direction and power are normalized through
  `binary_sensor.policy_grid_importing_now` and `sensor.policy_grid_power_w`.
- The tariff/grid layer is disabled by default and the real electricity contract
  is not yet documented.
- A read-only runtime audit at `2026-09-24T05:58:00Z` confirmed Modbus readiness,
  both tank temperatures, setpoint feedback, EHW power/state, SolarEdge/PV,
  SDM120 grid direction and the existing ClimateOps dry-run/write gates. Runtime
  writes during the audit: zero.
- At the audit instant the house was importing about 646 W while the calculated
  surplus was about 113 W and `binary_sensor.policy_surplus_ok` was off. This is
  a verified example where production alone must not authorize preheat.
- A 274-second live-state test showed no `last_reported` advance on the tested
  `_a` EHW candidates while SDM120 advanced. This does not yet prove failure of
  the active transport: runtime `doc_0_based` selects the physical `_b` sources.
  Until those sources pass a greater-than-240-second test, no EHW entity is a
  validated freshness authority and this package remains undeployed.
- `binary_sensor.cm_modbus_ehw_ready` is value-presence only; it cannot by
  itself authorize a shadow decision or establish current transport health.

## Policy bounds and remaining verification

The owner approved the following shadow-only bounds on 2026-09-24:

- minimum comfort temperature: 45 degC;
- normal target: 50 degC;
- maximum preheat target: 55 degC.

They remain non-authoritative for live actuation. The manufacturer limit is
60 degC and is not an autonomous normal target.

The following evidence remains open:

- current installed values of `g01..g04` and the resulting native legionella
  schedule/state;
- a runtime-validated freshness signal based on the state object's
  `last_reported` timestamp;
- user draw profile.

`input_boolean.ehw_shadow_limits_verified` defaults to `on` for the approved
shadow bounds. `input_boolean.ehw_shadow_legionella_verified` remains `off` and
is exposed as context. Because the package has no write authority, this does not
block observation or proposed shadow decisions; it remains a mandatory LIVE gate.

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
| `sensor.pv_power_now` | direct PV freshness cross-check | block preheat |

Freshness is evaluated independently for tank top, tank bottom, setpoint, raw grid
direction and raw grid power. The default threshold is 300 seconds, matching the
180 second EHW Modbus scan interval plus bounded jitter, and is configurable. A stale or missing
temperature/setpoint input blocks the policy. A stale grid input prevents PV
preheat but does not prevent comfort recovery.

The shadow package intentionally does not use the periodically refreshed
`sensor.policy_grid_power_w` as freshness evidence: its timestamp can be newer
than the underlying meter sample. It also does not accept PV production alone as
proof of export.

Freshness uses Home Assistant `last_reported`, which advances when a source
reports even if its value is unchanged. `last_updated` is not a freshness
fallback for this package. Recorder timestamps alone must not classify an
unchanged setpoint as fresh or stale.

The branch-only M63 transport hardening candidate applies a stricter 240-second
gate to the three physical `_b` raw sources for addresses 2020, 2021 and 1104.
The shadow policy's configurable 300-second limit remains an outer limit; the
transport readiness gate must already be true before any policy decision can be
proposed.

Recorder persistence is not the freshness authority: a `NULL`
`last_reported_ts` means `last_reported == last_updated` for that stored row, and
unchanged reports may not create a new history row. Pre-deploy validation must
therefore read `last_reported` from the live Home Assistant state object.

The live state-object test on 2026-09-24 observed no `last_reported` advance for
the tested `_a` candidates or derived EHW entities over 274 seconds, while
SDM120 advanced. EHW freshness remains a blocker, but the active `_b` transport
path still requires validation before diagnosing a transport failure.
`binary_sensor.cm_modbus_ehw_ready` must not override this block because its
current implementation is value-presence only, not age-aware.

A subsequent 282-second test validated `doc_0_based` routing and confirmed that
the selected raw inputs for addresses 2020, 2021 and 1104 did not advance,
while address 2019 and SDM120 did. This closes the deployment gate as
`BLOCK_DATA_STALE`. The transport contains duplicate entity declarations per
physical address; matching aliases and Modbus logs must be audited before any
mapping change. Until then, no EHW temperature or setpoint source is a validated
freshness authority for this policy.

The duplicate-pair follow-up showed identical behavior within each shared
address: both aliases of 2019 advanced, while both aliases of 2020, 2021 and
1104 did not. The current classification is therefore `REGISTER_PATH_STALE`,
not duplicate-alias scheduling. Duplicate transport declarations should still
be removed eventually, but only after passive polling coverage identifies the
actual failure boundary.

The subsequent 727-second matrix confirmed degraded, non-uniform polling:
addresses 2019 and 2024 advanced slowly, addresses 2020 through 2023 remained
stale, and every observed parameter from 1082 through 1109, including setpoint
1104, remained stale. There is no simple sequential cutoff and no EHW source
currently qualifies as freshness authority. The shadow deployment gate remains
closed with `BLOCK_DATA_STALE`.

The synchronized 777-second REST/log observation classified the fault as
`SILENT_POLL_FAILURE`: only T05 advanced, the required temperature/setpoint
chain remained stale, the EHW socket existed, and the available logs contained
no correlated error. Repeating the same passive audit is no longer a promotion
gate. Transport hardening and a successful post-change freshness test are now
prerequisites; the shadow package itself remains undeployed and non-actuating.

The prepared hardening candidate does not remove or rename entities. It retains
legacy `_a` raw sensors at a six-hour diagnostic cadence, keeps only 2020/2021/
1104 at the 180-second decision cadence, and makes EHW readiness age-aware.
This avoids an unverified entity-registry migration while materially reducing
polling load. It is not runtime evidence until separately authorized and
deployed.

## Decision priority

1. Shadow disabled.
2. Policy limits unverified.
3. Manual override.
4. Legionella pass-through active.
5. Modbus/EHW not ready.
6. Temperature or setpoint data missing/stale.
7. Comfort recovery required.
8. Stable measured export and surplus permit preheat.
9. Otherwise maintain current target.

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
- `BLOCK_SAFETY`
- `BLOCK_MANUAL_OVERRIDE`
- `BLOCK_MODBUS_NOT_READY`
- `BLOCK_DATA_STALE`
- `HOLD_COMFORT`
- `PREHEAT_PV_SURPLUS`
- `BLOCK_GRID_IMPORT`
- `HOLD_NO_SURPLUS`
- `HOLD_TARGET_REACHED`
- `BLOCK_TARIFF_UNAVAILABLE` (only when an economic decision requires tariff data)

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

- installed model remains `EQ 3018 ES`; model-specific manufacturer operating
  constraints remain sourced from manual `E7000670C`;
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

## Final M63 transport evidence and shadow boundary

`TRANSPORT_HARDENING_PASS` was recorded on 2026-09-25 after five advances of
each decision raw source, approximately 180.2 s maximum cadence, simultaneous
freshness/readiness/derived PASS, SDM120 PASS, writer safety PASS and zero
Modbus writes. This does not declare shadow pass or LIVE readiness.

The shadow package hard-bounds comfort/normal targets to 45–50 degC and
preheat to 50–55 degC. It does not modify native legionella settings. Missing
`g01..g04` and PM4 ACS/tariff accounting remain explicit LIVE/economic gaps;
they must never be described as legionella safety or measured savings proof.

## Pre-mortem gates

| Failure mode | Early signal | Countermeasure | Gate |
|---|---|---|---|
| Heat during false surplus | proposed preheat while importing | require stable export plus surplus | zero false-surplus promotions |
| Reduce hot-water comfort | repeated recovery/override | comfort recovery outranks optimization | no comfort regression |
| Oscillating targets | frequent action changes | 5 minute eligibility confirmation; live cooldown still TBD | decision churn reviewed |
| Stale sensor decisions | age exceeds threshold | explicit age checks and block/hold codes | stale share below 5 percent |
| Economically irrelevant gain | many windows, negligible shifted energy | keep EUR provisional; reconcile through AEB-ENER-003 | measurable benefit required |
