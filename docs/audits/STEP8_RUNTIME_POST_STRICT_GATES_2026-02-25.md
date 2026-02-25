# STEP8 Runtime Post Strict Gates (2026-02-25)

Date: 2026-02-25  
Scope: chiusura operativa hardening quality gates + deploy runtime.

## Operazioni eseguite
- Gate locali/CI resi strict (nessun downgrade warning `yamllint`).
- Aggiunto controllo anti-regressione per file `.pyc` tracciati.
- Rimossi dal repository 122 file `.pyc` legacy in `custom_components/**/__pycache__/`.
- Allineata entity map per dipendenze runtime:
  - `input_boolean.ac_send_command_busy`
  - `sensor.vmc_boost_bagno_eta_spegnimento`
- Commit e push su `main`:
  - `e2db70c chore(gates): enforce strict CI checks and purge tracked pyc artifacts`

## Verifiche (FACT)
- `ops/gates_run_ci.ps1` -> `ALL GATES PASSED` (missing entity map: 0).
- Deploy eseguito con `ops/deploy_safe.ps1 -RunConfigCheck` -> completato.
- Runtime check via SSH:
  - `ha core check` -> `Command completed successfully.`

## Impatto
- Ridotto rumore di repository e rischio regressioni silenziose.
- Pipeline quality piu` predicibile (fail-fast coerente tra locale e CI).
- Documentazione allineata alla dipendenza runtime reale delle entita`.

## Evidenza
- Commit: `e2db70c` su `origin/main` (2026-02-25).
- Output deploy: backup + sync allowlist completati.
- Output runtime: `ha core check` OK.
