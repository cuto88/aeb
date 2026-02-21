# ClimateOps Entrypoints

## Packages loading model
Home Assistant carica i package con `!include_dir_named packages`, quindi ogni file YAML sotto `packages/` viene incluso automaticamente.

## ClimateOps: posizione e scopo
- **Posizione**: `packages/climateops/`.
- **Scopo**: strategie di controllo *read-only* (logiche decisionali) e toggle di cutover per abilitare/disabilitare le strategie senza modificare i dispositivi core.

## How to rollback
1. Porta **OFF** tutti i toggle di cutover ClimateOps.
2. Torna al tag Git **`cutover-ok-2026-02-04`**.
