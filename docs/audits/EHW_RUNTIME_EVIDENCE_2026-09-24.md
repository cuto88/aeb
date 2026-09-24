# EHW runtime evidence — 2026-09-24

Workstream: M63 / AEB-DHW-001  
Audit timestamp: 2026-09-24T05:58:00Z  
Method: read-only SSH and Home Assistant Recorder SQLite  
Runtime writes: 0

## Verified snapshot

| Signal | Value | Classification |
|---|---:|---|
| `binary_sensor.cm_modbus_ehw_ready` | `on` | available |
| `sensor.ehw_tank_top` | 45.9 degC | value verified; report freshness not reconstructable from Recorder `last_updated` alone |
| `sensor.ehw_tank_bottom` | 42.0 degC | value verified; report freshness not reconstructable from Recorder `last_updated` alone |
| `sensor.ehw_setpoint` | 45.0 degC | value verified; unchanged-value freshness requires `last_reported` |
| `sensor.ehw_power_w` | 43.91 W | operational evidence, not dedicated PM4 measurement |
| `sensor.ehw_operation_state` | `active_power_confirmed` | available |
| `binary_sensor.policy_surplus_ok` | `off` | no preheat eligibility |
| grid import | 646.11 W | import confirmed |
| `sensor.pm4_acs_power` | `unavailable` | gap |

The simultaneous PV-derived surplus value of 112.78 W and measured grid import
prove that PV production/surplus estimation alone is insufficient. Preheat must
require stable measured export.

## Controls and authority

- ClimateOps DHW dry-run: on.
- DHW write enable: off.
- DHW commanded/cutover/permission/boost: off.
- No Home Assistant service call, deploy, reload, restart or Modbus write occurred.

## Open evidence

- Installed `g01..g04` values and native treatment schedule/state.
- Direct runtime validation of `last_reported` behavior across at least one EHW
  poll and one SDM120 poll.
- Dedicated PM4 ACS measurement remains unavailable; it is not required to run
  non-actuating shadow evaluation, but prevents causal energy attribution.
- Comfort/normal/preheat targets remain subject to explicit approval.

## Decision

The owner approved the 45/50/55 degC shadow bounds on 2026-09-24. The package is
not authorized for deployment yet: the remaining pre-deploy gate is validation
of its freshness logic against `last_reported`. Missing `g01..g04` blocks live promotion and any
attempt to control treatment; it does not justify inventing Modbus registers.

## Freshness follow-up — Recorder interpretation

A DS-XPS read-only observation from `2026-09-24T06:19:18Z` to
`2026-09-24T06:22:55Z` found `last_reported_ts = NULL` on the recorded EHW and
derived grid rows, while the raw SDM120 row had an explicit timestamp.

This does **not** prove a failed report. Home Assistant Recorder intentionally
stores `last_reported_ts` as `NULL` when `last_reported == last_updated`; the
effective report timestamp for that row is therefore `last_updated_ts`. Recorder
also cannot by itself demonstrate repeated unchanged reports when no new state
row is persisted. The SQL test is classified `INCONCLUSIVE`, not `FAIL`.

Observed facts retained:

- raw SDM120 reports were visible at about 30 second intervals;
- EHW bottom changed during the window and produced a fresh row;
- EHW top and setpoint did not produce a new Recorder row during the 217 second
  window;
- runtime writes remained zero.

The remaining gate must inspect the live Home Assistant state object's
`last_reported` before and after a poll, rather than interpreting nullable
Recorder columns directly.

## Live state follow-up — candidate-path result

DS-XPS read the live Home Assistant state objects from `2026-09-24T07:08:37Z`
to `2026-09-24T07:13:11Z` (274 seconds), without using Recorder for the
freshness decision.

Results:

- `sensor.ehw_t01_raw_a`, `sensor.ehw_t02_raw_a` and
  `sensor.ehw_setpoint_raw_a`: state and `last_reported` unchanged;
- `sensor.ehw_tank_top`, `sensor.ehw_tank_bottom` and `sensor.ehw_setpoint`:
  state and `last_reported` unchanged;
- `sensor.sdm120_ch2_active_power_w_raw` and `sensor.grid_power_w`:
  `last_reported` advanced and values changed;
- runtime writes: zero.

Classification for the entities tested: **EHW freshness FAIL; SDM120 freshness
PASS**. This is not yet a conclusive failure of the active EHW Modbus transport.
The runtime configuration enforces `input_select.ehw_address_mode =
doc_0_based`; in that mode the selected physical sources are the `_b`
candidates, including `sensor.ehw_t02_raw_b`, `sensor.ehw_t03_raw_b` and
`sensor.ehw_setpoint_1104_raw_b`. The test instead observed `_a` candidates,
and `sensor.ehw_setpoint_raw_a` is itself a selector/template rather than the
physical setpoint transport entity.

No EHW entity is currently accepted as freshness authority. The shadow package
must remain undeployed until a greater-than-240-second live-state test validates
the active `_b` physical sources, or the EHW transport is diagnosed and a
trustworthy heartbeat is implemented.

`binary_sensor.cm_modbus_ehw_ready` is not sufficient evidence of current
transport health: its template only checks whether a historical EHW value exists
and does not apply an age limit.

Next read-only test: record `input_select.ehw_address_mode` and observe
`sensor.ehw_t02_raw_b`, `sensor.ehw_t03_raw_b` and
`sensor.ehw_setpoint_1104_raw_b` before and after at least 240 seconds. The
derived tank/setpoint entities remain decision values, not freshness authority.

## Active-path follow-up — confirmed freshness block

DS-XPS read the live state objects from `2026-09-24T07:53:16Z` to
`2026-09-24T07:57:58Z` (282 seconds). Runtime routing was verified as
`doc_0_based`, with `ehw_swap_top_bottom = on`.

- `sensor.ehw_t02_raw_b` (address 2020): `last_reported` did not advance;
- `sensor.ehw_t03_raw_b` (address 2021): `last_reported` did not advance;
- `sensor.ehw_setpoint_1104_raw_b` (address 1104): `last_reported` did not
  advance;
- `sensor.ehw_t01_raw_b` (address 2019): advanced and changed from 108 to 107;
- SDM120 and canonical grid power advanced in the same window;
- all requested entities were present and available; runtime writes were zero.

Classification: **`FAIL_ACTIVE_TRANSPORT` for the selected policy input path**.
This is a conclusive freshness block for shadow deployment, but not evidence
that the entire EHW Modbus link is down: address 2019 remained live.

The transport package declares duplicate entities for the same physical
addresses: 2019 is exposed by `ehw_t01_raw_b` and `ehw_t02_raw_a`; 2020 by
`ehw_t02_raw_b` and `ehw_t03_raw_a`; 2021 by `ehw_t03_raw_b` and
`ehw_t04_raw_a`; 1104 by `ehw_setpoint_1104_raw_b` and
`ehw_setpoint_1105_raw_a`. The observed split on address 2019 means the next
diagnostic must compare each duplicate pair and inspect Home Assistant Modbus
logs before attributing the failure to the appliance registers. No transport
refactor is authorized by this evidence alone.

## Duplicate-pair follow-up — register-path result

A further live REST window ran from `2026-09-24T08:09:34Z` to
`2026-09-24T08:15:21Z` (347 seconds), with `doc_0_based`, all observed entities
available and no runtime writes.

| Address | Aliases | Result |
|---|---|---|
| 2019 | `ehw_t01_raw_b`, `ehw_t02_raw_a` | both advanced identically, 106 to 107 |
| 2020 | `ehw_t02_raw_b`, `ehw_t03_raw_a` | both failed to advance |
| 2021 | `ehw_t03_raw_b`, `ehw_t04_raw_a` | both failed to advance |
| 1104 | `ehw_setpoint_1104_raw_b`, `ehw_setpoint_1105_raw_a` | both failed to advance |

SDM120 advanced during the same window. No correlated Modbus timeout,
transaction mismatch, illegal-address or duplicate error was found in the
available logs.

Classification: **`REGISTER_PATH_STALE`**, not
`DUPLICATE_ALIAS_SCHEDULING`. Each duplicate pair behaved consistently within
its physical address. Duplicate declarations remain unnecessary polling and a
future cleanup target, but this observation does not establish them as the
cause. Address 2019's observed report cadence was approximately 361 seconds
despite a configured 180-second scan interval, so the runtime's effective poll
cadence also requires characterization.

The next non-actuating diagnostic is a passive 12-minute matrix across all
physical EHW addresses 2019 through 2024 plus parameters 1082, 1088, 1089,
1104, 1106 and 1109. This must identify whether polling stops at an address
boundary, operates at a longer effective cycle, or leaves only specific
registers stale. Shadow deployment remains blocked.

## Twelve-minute polling matrix — degraded transport

DS-XPS sampled live REST state objects 13 times from
`2026-09-24T10:43:03Z` to `2026-09-24T10:55:10Z` (727 seconds). Recorder was
not used as freshness authority and runtime writes were zero.

| Address/group | Observed result |
|---|---|
| 2019 | two advances; effective intervals up to 360 seconds |
| 2020 | no advance |
| 2021 | no advance |
| 2022 | no advance |
| 2023 | no advance |
| 2024 | two advances; effective intervals up to 360 seconds |
| 1082, 1088, 1089, 1104, 1106, 1109 | no advance |
| SDM120 control | 12 advances at approximately 60 seconds |

The `_a` aliases matched their corresponding physical addresses. Because 2024
advanced after the stale 2020 through 2023 range, no simple sequential cutoff
is established. Classification: **`TRANSPORT_DEGRADED` with
`PARAMETER_GROUP_STALE`**. Addresses 2019 and 2024 are diagnostic-only
`POLLING_SLOW`; they do not validate the temperatures or setpoint required by
the policy. No EHW entity observed in this audit is promoted to freshness
authority.

The next diagnostic must correlate live `last_reported` changes with existing
Home Assistant `ehw_modbus` logs during the same window. It must not enable
debug logging, call services, probe the Modbus gateway directly, restart Home
Assistant or change configuration without separate authorization.

## Synchronized REST/log window — silent poll failure

DS-XPS observed live state and existing Home Assistant logs from
`2026-09-24T16:30:23Z` to `2026-09-24T16:43:20Z` (777 seconds), with 13 REST
samples and zero runtime writes.

- only `sensor.ehw_t05_raw_b` advanced, at approximately 180-second intervals;
- the other observed EHW temperature registers and every parameter in
  1082/1088/1089/1104/1106/1109 did not advance;
- SDM120 advanced approximately every 60 seconds;
- an already-established socket to the EHW gateway was present at the final
  check;
- existing logs contained no correlated Modbus error, timeout, transaction
  mismatch, illegal-address event, reconnect or exception.

Classification: **`SILENT_POLL_FAILURE`**, retaining the broader
`TRANSPORT_DEGRADED` classification. The EHW register that advances changes
between observation windows, while the required temperature/setpoint chain is
never simultaneously fresh. Further identical passive observation has low
diagnostic value and is stopped here.

The next authorized scope is branch-only design and validation of a minimal,
reversible transport hardening change. Before editing transport configuration,
the design must inventory every consumer of the raw `_a`/`_b` entities, retain
public compatibility where required, reduce duplicate physical polling, add
per-register age-aware health, and define an exact backup/rollback and
post-deploy test. No deployment, reload or restart is authorized.

## Branch-only hardening candidate

A local, non-deployed candidate was prepared after the passive diagnosis:

- preserve every existing Modbus entity and `unique_id`;
- retain only addresses 2020, 2021 and 1104 at the 180-second policy cadence;
- move other `_b` temperature diagnostics to 900 seconds;
- move non-decision parameters to 1800 seconds;
- move legacy `_a` candidates and unused setpoint alternatives to 21600 seconds;
- calculate `cm_modbus_ehw_ready` from live `last_reported` age of the three
  required `_b` raw sources, with a 240-second fail-closed threshold;
- expose separate age-aware health for tank top, tank bottom and setpoint while
  retaining `cm_modbus_ready` as presence-only context;
- route `ehw_setpoint_raw_calc` explicitly from physical address 1104 `_b`;
- leave the writer and its write gates unchanged.

Static validation passed for YAML parsing of the five relevant EHW/DHW
packages, duplicate `unique_id` detection, required 180-second scan intervals,
absence of new Modbus writes and `git diff --check`. No runtime validation,
commit, push or deployment occurred. Repository instructions prohibit local Git
mutation in this workspace, so the candidate remains an uncommitted review
diff pending publication through an authorized working copy or connector.
