# STEP122 — Zone-based cooling decision (remove `t_in_med` mode dependency) — 2026-05-29

## Obiettivo

Chiudere il gap operativo segnalato: evitare passaggi anticipati a `VENT_BASE` dovuti a valutazioni globali su `sensor.t_in_med` quando le zone non sono ancora in comfort.

## Scope

- `packages/climateops/strategies/planner.yaml`
- `packages/cm_system_facade.yaml`

## Decisione tecnica

Rimosse le dipendenze decisionali da `sensor.t_in_med` nei percorsi principali di suggerimento mode/cooling branch:

1. `ClimateOps Planner Recommended Mode`
   - `HEAT` su minima delle zone (`giorno`, `notte1`, `notte2`, `bagno`) vs target heating.
   - `COOL` su massima delle zone vs `ac_cool_setpoint + 0.5`.
   - `IDLE` altrimenti.

2. Branch `COOL_DAY` vs `COOL_NIGHT`
   - Primary: `sensor.envelope_worst_room_name`.
   - Fallback: confronto temperature zone (`max night` vs `day`) invece di `t_in_med`.

## Vincoli rispettati

- Nessun rename `entity_id`.
- Nessuna cancellazione.
- Nessuna nuova entita` introdotta.
- Nessun deploy automatico.

## Verifiche eseguite

- `yamllint packages/climateops/strategies/planner.yaml packages/cm_system_facade.yaml` -> OK

## Rischio residuo

- La logica resta sensibile alla qualita` dei sensori zona: se una zona e` rumorosa/outlier puo` estendere la richiesta COOL.
- Il threshold `+0.5` e` invariato: se serve maggiore inerzia di uscita da COOL va introdotta hysteresis dedicata in un passo successivo.
