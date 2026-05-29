# STEP121 — Planner cutover guard (source-side) — 2026-05-29

## Obiettivo

Ridurre il rischio di fallback implicito durante la promozione del planner da dry-run a controllo reale, senza introdurre nuove entita` e senza cambiare authority runtime.

## Scope

- `packages/climateops/strategies/requests.yaml`
- `packages/cm_system_facade.yaml`

## Decisione tecnica

Il fallback da `sensor.climateops_planner_recommended_mode` a `sensor.planner_recommended_mode` resta consentito solo prima del cutover planner completo.

Cutover planner completo definito come:

- `input_boolean.climateops_cutover_heating = on`
- `input_boolean.climateops_cutover_ac = on`

Quando entrambe sono `on`, il fallback legacy viene disabilitato e la sorgente effettiva resta solo `sensor.climateops_planner_recommended_mode`.

## Motivazione

- Evitare dipendenze legacy silenziose in fase post-cutover.
- Riusare gate gia` esistenti (`cutover_heating`, `cutover_ac`) senza nuove entita`.
- Mantenere rollback operativo semplice riportando i cutover su `off`.

## Verifiche eseguite

- `yamllint packages/climateops/strategies/requests.yaml packages/cm_system_facade.yaml` -> OK
- `ops/gates_run_ci.ps1` -> fallisce per path check VMC non risolto nel runner (`ops/gates/check_vmc_helper_split.ps1`), non per la patch.

## Rischio residuo

Se `cutover_heating=on` e `cutover_ac=on` ma `sensor.climateops_planner_recommended_mode` e` assente/non disponibile, i request sensor planner possono risultare non disponibili (fail-safe intenzionale).
