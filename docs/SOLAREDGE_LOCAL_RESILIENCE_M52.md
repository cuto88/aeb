# M52 — SolarEdge local resilience

**Status:** ACTIVE / PHYSICAL_VALIDATION_REQUIRED  
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
- historical MAC candidate: `84:d6:c5:20:c5:bd`
- current LAN IP: **UNKNOWN**

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

`UNRESOLVED`.

Neither the AEB repository nor the available connected data contains a current DHCP/ARP/mDNS observation for the inverter. Serial, historical hostname, and historical MAC do not prove a current IP.

### Phase 2 — local services

`UNRESOLVED`.

TCP 1502, TCP 502, HTTP, and HTTPS have not been probed from the Casa Mercurio LAN. No conclusion may be made about whether Modbus TCP is enabled on this unit.

### Phase 3 — SunSpec identification

`NOT_EXECUTED` because Phase 1/2 are unresolved.

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

Required before any source migration:

- current inverter IP verified;
- local protocol/port verified;
- SunSpec Common Model identity verified;
- local power value and scale verified;
- local lifetime value and scale verified;
- at least two production-time lifetime readings prove monotonicity/increment;
- physical comparison with cloud/grid is coherent;
- continuity plan for `sensor.pv_energy_total` and LTS is defined.

## Next action

Recover the inverter current DHCP lease by matching MAC `84:d6:c5:20:c5:bd` on the active Casa Mercurio router/LAN. Do not scan the subnet and do not enable Modbus TCP yet.
