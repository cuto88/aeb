# STEP10 Phase1 AEB/Passivhaus DRY-RUN (2026-02-27)

Date: 2026-02-27  
Scope: avvio migrazione incrementale Phase 1 con KPI + planner predittivo in sola raccomandazione.

## Boundary (strict)

1. DRY-RUN only: nessuna attuazione, nessuna scrittura su switch/climate setpoint.
2. Nessuna modifica alla catena authority attuatori esistente.
3. Solo aggiunte additive e reversibili in package top-level caricati da `configuration.yaml`.

## Files introdotti

1. `packages/climateops_phase1_kpi.yaml`
2. `packages/climateops_phase1_planner_dryrun.yaml`

## Output previsto

- KPI giornalieri Passivhaus/AEB (comfort band, cicli heating/AC, minuti boost VMC).
- Raccomandazioni planner (`sensor.planner_*`) con explainability sintetica.

## Safety expectation

- Gating locale invariato: target `ALL GATES PASSED`.
