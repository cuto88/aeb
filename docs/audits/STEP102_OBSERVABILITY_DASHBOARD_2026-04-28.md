# STEP102 — Observability dashboard (2026-04-28)

## FACT

- Le plance dominio principali sono state razionalizzate.
- Restava un gap software ad alto ROI:
  - fault visibility
  - stale/unavailable visibility
  - battery/radio risk visibility
  - contracts/readiness visibility

## IPOTESI (confidenza alta)

- Una dashboard dedicata di observability riduce attrito operativo prima delle modifiche hardware.
- Il valore non e` nel creare nuova logica, ma nel rendere leggibili i segnali gia` esistenti.

## DECISIONE

- Aggiunta nuova dashboard:
  - `11 Observability`
- File:
  - `lovelace/observability_plancia.yaml`

## Struttura

### Runtime health

- MIRAI Modbus
- EHW Modbus
- VMC sensors
- AC failsafe
- Heating failsafe
- T_out stale
- MIRAI truth inputs
- Envelope inputs
- Solar gain inputs

### Contracts

- actuators defined / ready
- missing entities
- forecast inputs / forecast contract
- tariff-grid contract
- hierarchy contract
- reasons associate

### Sensor hygiene

- `sensor.t_out_effective`
- `binary_sensor.t_out_stale`
- `binary_sensor.policy_forecast_inputs_ready`
- `binary_sensor.aeb_kpi_inputs_ready`
- `sensor.cm_policy_forecast_reason`
- `sensor.cm_system_mode_suggested`
- `sensor.cm_system_reason`

### Unavailable / unknown

- entity-filter su entita` runtime critiche:
  - AC switches
  - heating master
  - VMC relays
  - MIRAI/EHW readiness
  - outdoor effective
  - EHW setpoint
  - sensori T/RH principali

### Battery / radio risk

- `sensor.batteria_giorno`
- `sensor.batteria_cam1`
- `sensor.batteria_cam2`
- `sensor.batteria_esterna`

### Proxy vs physical

- heating / VMC / AC proxy
- switch fisici/comandi associati

## Rationale

- `11 Observability` non sostituisce le plance di dominio.
- Serve come pannello operativo di salute del sistema.
- Riduce il tempo speso a capire se un problema e`:
  - sensore
  - transport
  - helper
  - runtime contract
  - proxy/driver mismatch

## File toccati

- `configuration.yaml`
- `lovelace/observability_plancia.yaml`
- `docs/audits/README.md`
