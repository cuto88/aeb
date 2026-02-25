# Delta Audit Status (2026-02-25)
Date: 2026-02-25
Scope: allineamento documentazione/repo/runtime dopo hardening ClimateOps

## Verifiche eseguite (FACT)
- Repo gates locali: `ops/validate.ps1` -> PASS (2026-02-25).
- Merge branch Step6/Step7 su `main` completato e push su `origin/main`.
- Deploy runtime completato con `ops/deploy_safe.ps1 -Target Z:\` (backup + sync OK).
- Runtime core: `ha core info` -> `version: 2026.2.3`, `boot: true` (2026-02-25).
- Runtime config check: `ha core check` -> `Command completed successfully.` (2026-02-25).
- Restart core completato (con retry per coda job supervisor).
- File runtime verificati:
  - `/homeassistant/packages/climateops/actuators/system_actuator.yaml`
  - `/homeassistant/packages/climateops/core/kpi.yaml`
  - `/homeassistant/packages/climate_policy_energy.yaml`
- Tracce presenti per `automation.climateops_system_actuate` in `.storage/trace.saved_traces`.
- Evidenza snapshot raccolta:
  - `docs/runtime_evidence/2026-02-25/step7_state_snapshot_20260225_220506.txt`
  - `docs/runtime_evidence/2026-02-25/step7_live_states_20260225_222310.txt`

## Stato obiettivo
- Stabilizzazione runtime writer authority ClimateOps: QUASI CHIUSO.
- Hardening restart/check/deploy: CHIUSO operativamente.
- Maturita` AEB (forecast + tariff/grid-aware + gerarchia multi-load + KPI closure): IMPLEMENTATA A LIVELLO REPO + DEPLOY, CHIUSURA FUNZIONALE RUNTIME PARZIALE.

## Gap residui principali
1. Conferma live post-warmup degli stati Step7 (UI state machine) ancora da completare:
   - `policy_forecast_inputs_ready`, `policy_allow_shift_load`, `contract_hierarchy_mode_ready`, `cm_system_mode_suggested`, `aeb_*`.
   - tentativo API diretto da shell runtime non conclusivo (`401 Unauthorized`).
2. Chiusura evidence pack evento-level con export UI/trace/logbook per contesto post-deploy.

## Doc drift corretto in questo delta
- `docs/climateops/ENTRYPOINTS.md`: rimosso riferimento "read-only" assoluto, allineato a stack con attuazione.
- `docs/audits/STEP5_VMC_TARGET1_FIX_2026-02-25.md`: chiarito comportamento con `cutover_vmc=off` (applicazione `vmc_target`, non disattivazione totale writer).
- `AI/TASKS.md`: T2/T3 portati da `Planned` a `In Progress`.
- `packages/climateops/overrides/thermostat_indicators_temp.yaml`: remap termostati TEMP da binary source a soglia LDR raw (3.00V default) con isteresi.
- `lovelace/climate_heating_plancia.yaml`: esposti helper di tuning LDR raw/soglia/isteresi.
- `docs/logic/heating/plancia.md`, `docs/logic/heating/README.md`, `docs/logic/core/README_sensori_clima.md`: documentazione allineata al nuovo mapping.
- `docs/audits/STEP6_THERMOSTAT_TEMP_LDR_THRESHOLD_2026-02-25.md`: audit dedicato del fix.
- `docs/audits/STEP7_AEB_EXECUTION_PLAN_2026-02-25.md`: piano esecutivo Step7.
- `docs/audits/STEP7_1_FORECAST_INPUT_CONTRACTS_2026-02-25.md`: forecast contracts.
- `docs/audits/STEP7_2_TARIFF_GRID_POLICY_2026-02-25.md`: tariff/grid policy.
- `docs/audits/STEP7_3_MULTI_LOAD_HIERARCHY_2026-02-25.md`: hierarchy multi-load.
- `docs/audits/STEP7_4_KPI_CLOSURE_2026-02-25.md`: KPI closure.
- `docs/audits/STEP7_POST_PR_RUNTIME_CHECKLIST_2026-02-25.md`: runbook post-PR.
- `docs/audits/STEP7_POST_DEPLOY_RUNTIME_2026-02-25.md`: verifica post-deploy.

## Prossimo step consigliato (Step 8)
- Closure funzionale runtime Step7:
  1) conferma stati live da UI su entita` chiave,
  2) export evidenza in `docs/runtime_evidence/2026-02-25/`,
  3) aggiornamento finale status da "parziale" a "chiuso".
