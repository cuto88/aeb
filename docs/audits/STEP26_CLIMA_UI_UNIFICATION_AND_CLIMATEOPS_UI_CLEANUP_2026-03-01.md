# Step 26 - Clima UI unification + ClimateOps UI cleanup (2026-03-01)

## Scope
Allineare la UI clima a una plancia moderna unica e rimuovere elementi ClimateOps non piu utili in sidebar/dashboard operative.

## Changes
1. Aggiunta nuova dashboard in `configuration.yaml`:
   - key: `1-clima-casa`
   - file: `lovelace/climate_casa_unified_plancia.yaml`
   - `show_in_sidebar: true`
2. Rimossa voce dashboard `9-climateops-step7` da `configuration.yaml`.
3. Creata copia archivio della plancia Step7 in `lovelace/_archive/climateops_step7_plancia.yaml`; il duplicato runtime `lovelace/climateops_step7_plancia.yaml` e` stato poi rimosso dal repo attivo.
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

## Follow-up eseguito
Con successivo allineamento UI:
1. `show_in_sidebar: false` applicato a `1-ventilazione-v2`;
2. `show_in_sidebar: false` applicato a `2-heating`;
3. `show_in_sidebar: false` applicato a `3-ac`;
4. `show_in_sidebar: false` applicato a `0-lovelace` (`Overview`) per ridurre rumore UI;
5. titolo sidebar `PV SolarEdge` riallineato a `5 PV SolarEdge` per coerenza visiva con le altre plance numerate;
6. vista `AEB` della plancia unificata ripulita sostituendo i badge superiori con tile di stato rapido piu' leggibili;
7. `1-clima-casa` mantenuto come unico accesso utente principale per il dominio clima.
