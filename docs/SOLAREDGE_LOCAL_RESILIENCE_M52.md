# M52 — SolarEdge local resilience

**Status:** ACTIVE / MODBUS_ENABLEMENT_REQUIRED  
**Date:** 2026-08-25  
**Scope:** Casa Mercurio PV source resilience; read-only discovery and validation before any Home Assistant change.

## Canonical baseline

M51 remains closed. The Energy Dashboard contract is unchanged:

- PV: `sensor.pv_energy_total`
- grid import: `sensor.grid_energy_import_kwh`
- grid export: `sensor.grid_energy_export_kwh`
- AC branch: `sensor.ac_energy_total_kwh`

Current PV implementation remains the SolarEdge cloud lifetime wrapper. No entity, statistics, or runtime configuration is changed by M52 at this stage.

## Inverter identity

- model / part number: `SE6000H-RW000BNN4`
- serial: `74059EAB-C2`
- communication: Wi-Fi
- historical hostname: `solaredgeinverter`
- MAC: `84:d6:c5:20:c5:bd`
- current LAN IP: `192.168.178.111`
- identity confidence: HIGH

Runtime evidence collected on 2026-08-25:

- active EdgeRouter DHCP lease maps `192.168.178.111` to `84:d6:c5:20:c5:bd`;
- Windows ARP reports the same IP/MAC mapping;
- `mercurio-edge` neighbour cache reports the same IP/MAC mapping in `REACHABLE` state;
- ping succeeds with TTL 64.

The exact part number is a single-phase 6 kW HD-Wave inverter with SetApp configuration. SolarEdge documentation states that SetApp-configured inverters support SunSpec.

## Vendor protocol facts

Source: SolarEdge, *SunSpec Implementation Technical Note* (official Knowledge Center; current search result version 3.2 / June 2025, with equivalent register mapping also documented in v2.5).

- Modbus TCP is disabled by default.
- When enabled, default TCP port is `1502`; the configured port can be changed.
- Default Modbus device ID for the inverter connected to Ethernet/LAN is `1`.
- SunSpec Common Model base is PLC/base-1 `40001`, protocol/base-0 `40000`.
- Common Model identification fields include `C_Manufacturer`, `C_Model`, `C_Version`, `C_SerialNumber`, and `C_DeviceAddress`.
- Inverter monitoring mappings include SunSpec inverter model IDs `101`, `102`, and `103` as applicable.
- AC Power is `I_AC_Power` with `I_AC_Power_SF`.
  - base-0: `40083`, SF `40084`
  - base-1: `40084`, SF `40085`
- Lifetime AC energy is `I_AC_Energy_WH` (`acc32`, Wh) with `I_AC_Energy_WH_SF`.
  - base-0: `40093` (2 registers), SF `40095`
  - base-1: `40094` (2 registers), SF `40096`

These addresses are **reference mappings only**. They are not authorized for runtime use until the local device is identified through its SunSpec Common Model and the actual service/unit ID is verified.

## Current validation state

### Phase 1 — LAN IP

`VERIFIED`.

Current inverter identity is `192.168.178.111` ↔ `84:d6:c5:20:c5:bd` with HIGH confidence from DHCP, ARP, neighbour and ping evidence.

Casa Mercurio LAN runtime drift was also identified:

- EdgeRouter X / gateway / DHCP / DNS: `192.168.178.1` (`switch0 192.168.178.1/24`);
- FRITZ!Box 6850 LTE: `192.168.178.3`;
- `mercurio-edge`: `192.168.178.110`;
- DS-XPS: `192.168.178.105`;
- old documented EdgeRouter address `192.168.178.2` is no longer operational.

The LAN inventory in `cuto88/mra-ops` has been reconciled to this runtime state.

### Phase 2 — local services

`PARTIALLY_VERIFIED / MODBUS_UNAVAILABLE`.

Targeted read-only probes against `192.168.178.111` returned:

- TCP 1502: CLOSED OR FILTERED
- TCP 502: CLOSED OR FILTERED
- HTTP: TIMEOUT
- HTTPS: TIMEOUT

Therefore Modbus TCP is not currently reachable. This does not prove incompatibility; given SolarEdge defaults, disabled Modbus TCP is the leading hypothesis. No enablement or configuration change has been attempted.

### Phase 3 — SunSpec identification

`NOT_EXECUTED` because no Modbus TCP endpoint is currently reachable.

### Phase 4 — local PV power

`UNRESOLVED`. No raw value, scale factor, or simultaneous physical comparison has been collected.

### Phase 5 — local lifetime energy

`UNRESOLVED`. No raw value, scale factor, monotonicity sample, reset behavior, or simultaneous comparison with `sensor.pv_energy_total` has been collected.

## Architecture gate

Until local lifetime energy is physically verified, keep SolarEdge cloud as the primary PV source.

Preferred end-state **only if validation passes**:

1. native local SolarEdge lifetime energy as primary source behind the canonical `sensor.pv_energy_total` contract;
2. native local SolarEdge AC power as `sensor.pv_power_now`;
3. SolarEdge cloud retained for diagnostics/comparison and as a secondary recovery source, not numerically merged with the local cumulative counter.

A migration must not apply an offset unless simultaneous measurements prove a stable semantic relationship. It must explicitly prevent drop, jump, reset-statistic, and double-counting behavior. Existing Home Assistant long-term statistics must not be manually rewritten as part of discovery.

## Safe-to-modify gate

**NO**.

Verified:

- current inverter IP and MAC identity;
- targeted service reachability state.

Still required before any source migration:

- Modbus TCP enabled/reachable through authorized commissioning;
- SunSpec Common Model identity verified;
- local power value and scale verified;
- local lifetime value and scale verified;
- at least two production-time lifetime readings prove monotonicity/increment;
- physical comparison with cloud/grid is coherent;
- continuity plan for `sensor.pv_energy_total` and LTS is defined.

## Next action

Using authorized SolarEdge SetApp commissioning access, inspect **Commissioning → Site Communication → Modbus TCP** and record the displayed enable/disable state and configured TCP port. Do not change the setting until the current state is known and the enablement action is explicitly authorized.
