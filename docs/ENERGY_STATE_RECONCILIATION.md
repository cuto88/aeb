# Mercurio — Energy State Reconciliation

**Status:** reconciled / runtime-verified  
**Implementation:** M51 closeout completed; further Energy development may proceed from this verified baseline  
**Scope:** AEB energy design, Home Assistant runtime, whole-house balance, PV/grid/AC energy sources, historical continuity  
**Closeout reference:** `M51[MANUTENZIONE] Energy Dashboard HA — Ripristinare monitoraggio e validare export rete`  
**Follow-up:** `M52[SYSTEM] SolarEdge locale — Verificare Modbus TCP/SunSpec e rendere resiliente il dato PV`

## 1. Decision

The whole-house Energy monitoring baseline is now reconciled and runtime-verified.

The canonical Home Assistant Energy contract is:

| Role | Canonical entity | Physical/logical source | Status |
| --- | --- | --- | --- |
| PV production | `sensor.pv_energy_total` | SolarEdge lifetime energy normalized Wh -> kWh | `DONE_VERIFIED` |
| Grid import | `sensor.grid_energy_import_kwh` | SDM120 slave 2 import cumulative register | `DONE_VERIFIED` |
| Grid export | `sensor.grid_energy_export_kwh` | SDM120 slave 2 export cumulative register | `DONE_VERIFIED` |
| AC branch energy | `sensor.ac_energy_total_kwh` | SDM120 slave 3 import cumulative register | `DONE_VERIFIED` |
| Grid instantaneous power | `sensor.grid_power_w` | SDM120 slave 2 active power, signed | `DONE_VERIFIED` |
| AC branch power | `sensor.ac_power_w` | SDM120 slave 3 active power | `DONE_VERIFIED` |

Home Assistant Energy Dashboard is configured with the four cumulative entities above. Raw Modbus entities and legacy Energy entities are not part of the dashboard contract.

## 2. Verified physical meaning

### Grid — SDM120 slave 2

Slave 2 is the authoritative bidirectional grid meter.

Verified semantics:

- positive `sensor.grid_power_w` = import;
- negative `sensor.grid_power_w` = export;
- import cumulative source = SDM120 register address 72;
- export cumulative source = SDM120 register address 74;
- both cumulative entities use kWh and `state_class: total_increasing`.

Export was validated empirically during real export: the export counter increased while import remained stationary, with the energy increment coherent with measured power and elapsed time.

### AC branch — SDM120 slave 3

Slave 3 measures the branch feeding the domestic AC units, including branch standby/auxiliary consumption.

Canonical entities:

- `sensor.ac_power_w`;
- `sensor.ac_energy_total_kwh`.

This is an individual load/sub-consumption and must not be added to the whole-house balance.

### Legacy Dual Meter channels

Dual Meter A/B channels are local load channels and are **not** authoritative grid import/export sources. They must not be promoted to the whole-house Energy contract.

## 3. PV source and SolarEdge incident

Canonical PV cumulative source remains:

`sensor.pv_energy_total`

implemented as a wrapper over:

`sensor.solaredge_energia_dall_installazione`

with Wh -> kWh conversion and availability protection.

During M51 the SolarEdge cloud integration became stale while remaining technically `available`: current power and daily production returned zero and lifetime energy stopped increasing while the grid meter showed real export.

The integration itself remained authenticated and responsive; the stale content originated upstream in SolarEdge Monitoring telemetry/publication.

SolarEdge later recovered and backfilled the missing production. Final observed healthy values included:

- lifetime SolarEdge: `22,230,128 Wh`;
- `sensor.pv_energy_total`: `22,230.128 kWh`;
- current SolarEdge power: about `3,643.94 W`;
- daily production restored and historical production for 2026-08-21 available again.

From 05:46 to 11:16 UTC on 2026-08-25 the lifetime increased from `22,222.596` to `22,230.128 kWh`, confirming resumed cumulative growth.

## 4. Energy Dashboard validation

Persistent Energy Dashboard sources:

```text
PV:          sensor.pv_energy_total
GRID IMPORT: sensor.grid_energy_import_kwh
GRID EXPORT: sensor.grid_energy_export_kwh
AC:          sensor.ac_energy_total_kwh
```

Runtime validation confirmed for all four cumulative sensors:

- entity exists;
- entity available;
- unit `kWh`;
- `device_class: energy`;
- `state_class: total_increasing`;
- Recorder long-term statistics present;
- `has_sum: 1`;
- no relevant repair issues;
- no duplicate `_2` entities in the dashboard contract;
- no legacy/raw entities used by the dashboard.

## 5. Whole-house balance

Canonical balance:

`house_consumption = PV + grid_import - grid_export`

Verified examples after SolarEdge recovery:

### Export interval — 2026-08-25 07:00–08:00 UTC

```text
PV          = 1.532 kWh
Grid import = 0.000 kWh
Grid export = 1.170 kWh
House       = 1.532 + 0.000 - 1.170 = 0.362 kWh
```

### Import interval — 2026-08-25 00:00–01:00 UTC

```text
PV          = 0.000 kWh
Grid import = 0.120 kWh
Grid export = 0.000 kWh
House       = 0.000 + 0.120 - 0.000 = 0.120 kWh
```

### Dashboard daily total observed during final validation

```text
PV          = 6.45 kWh
Grid import = 1.01 kWh
Grid export = 5.81 kWh
House       = 6.45 + 1.01 - 5.81 = 1.65 kWh
```

The Home Assistant UI displayed the same `1.65 kWh` house consumption result.

Therefore whole-house Energy truth is now operationally usable.

## 6. Historical data note

SolarEdge backfilled the missing cumulative production, but Home Assistant Recorder received part of the recovery as later jumps rather than redistributing the energy into the original missing hourly intervals.

Consequences:

- current cumulative state is correct;
- SolarEdge daily historical production is recovered;
- some hourly HA balances during the stale/backfill incident remain temporally distorted;
- no destructive manual statistics repair is justified for this historical artifact.

This historical limitation does not block current operation.

## 7. Reconciliation matrix

| Capability | State | Evidence / note |
| --- | --- | --- |
| Grid instantaneous power | `DONE_VERIFIED` | SDM120 slave 2 signed active power |
| Grid import cumulative | `DONE_VERIFIED` | slave 2 register 72 + LTS |
| Grid export cumulative | `DONE_VERIFIED` | slave 2 register 74, empirically validated during export + LTS |
| PV cumulative | `DONE_VERIFIED` | SolarEdge lifetime wrapper, recovered and increasing |
| Home Assistant Energy Dashboard sources | `DONE_VERIFIED` | canonical PV/import/export/AC contract persisted and UI healthy |
| Whole-house balance | `DONE_VERIFIED` | positive/plausible in both import and export intervals |
| AC branch metering | `DONE_VERIFIED` | SDM120 slave 3 correlated with AC operation |
| SolarEdge local/LAN source | `DESIGNED_NOT_IMPLEMENTED` | model supports SunSpec/Modbus family; local IP/service not yet verified |
| Local PV resilience | `DESIGNED_NOT_IMPLEMENTED` | tracked separately by M52 |
| Historical hourly reconstruction of cloud-stale interval | `LEGACY_OR_OBSOLETE` as repair target | keep existing statistics; no destructive rewrite |

## 8. Local SolarEdge resilience follow-up — M52

M51 is closed and must not remain blocked by local inverter integration.

The separate follow-up is:

`M52[SYSTEM] SolarEdge locale — Verificare Modbus TCP/SunSpec e rendere resiliente il dato PV`

Known inverter facts:

- model: `SE6000H-RW000BNN4`;
- communication: Wi-Fi;
- historical hostname: `solaredgeinverter`;
- historical MAC candidate: `84:d6:c5:20:c5:bd`;
- current LAN IP: not yet known;
- model family supports SunSpec / Modbus TCP when enabled;
- SolarEdge Modbus TCP is normally disabled by default and commonly uses TCP 1502 when enabled.

M52 next action:

1. recover the inverter current LAN IP from the active router/DHCP lease table;
2. verify read-only whether TCP 1502 / SunSpec is already exposed;
3. if available, read the Common Model first and then validate local AC Power and lifetime energy;
4. do not change the canonical PV wrapper until local semantics, scale, monotonicity and continuity are proven.

No offset is authorized without simultaneous comparable evidence.

## 9. Development gate after M51

The previous blanket development block is removed for the verified monitoring baseline.

New Energy work may proceed only if it preserves these invariants:

- grid truth remains SDM120 slave 2;
- AC remains a sub-load from slave 3;
- Energy Dashboard consumes canonical wrappers, not raw entities;
- cumulative sensors must not use false-zero fallbacks;
- `total_increasing` is reserved for true monotonic cumulative counters;
- derived house/self-consumption energy must not be misrepresented as a raw cumulative meter;
- historical statistics are not manually rewritten without a specific evidence-backed migration plan.

## 10. Next Energy layer

With whole-house truth now verified, subsequent roadmap work can focus on:

- load allocation and unattributed residual;
- billing reconciliation;
- normalized baseline;
- energy automation ROI;
- predictive optimization.

M52 improves PV-source resilience but is not a blocker for these current-state monitoring capabilities.
