# Step 26 - Clima UI unification + ClimateOps UI cleanup (2026-03-01)

## Scope
Allineare la UI clima a una plancia moderna unica e rimuovere elementi ClimateOps non piu utili in sidebar/dashboard operative.

## Changes
1. Aggiunta nuova dashboard in `configuration.yaml`:
   - key: `1-clima-casa`
   - file: `lovelace/climate_casa_unified_plancia.yaml`
   - `show_in_sidebar: true`
2. Rimossa voce dashboard `9-climateops-step7` da `configuration.yaml`.
3. Rimossa sezione `ClimateOps Cutover` da:
   - `lovelace/climate_ventilation_plancia_v2.yaml`
4. Aggiunta nuova plancia unificata:
   - `lovelace/climate_casa_unified_plancia.yaml`
   - include sezioni condivise: stato generale, KPI, zone, VMC, AC, Heating, timeline decisioni.

## Runtime evidence
Intervento applicato anche su runtime HA via SSH read/write su `/homeassistant` con verifica:
- `ha core check` -> `Command completed successfully.`

## Outcome
1. Entry point moderno unico disponibile (`1 Clima Casa`).
2. UI operativa senza pannelli ClimateOps di cutover.
3. Riduzione duplicazioni tra plance VMC/AC/Heating mantenendo fallback legacy.

## Follow-up consigliato
Se validata in uso quotidiano:
1. mettere `show_in_sidebar: false` su `1-ventilazione-v2` e `3-ac`;
2. mantenere `1-clima-casa` come unico accesso utente per il dominio clima.
