# WIP Runtime Tracker
Date: 2026-02-24
Scope: ClimateOps runtime hardening and evidence closure

## Closed
- Gate naming bridge fixed (`CM ...` names in bridge templates).
- `policy_surplus_ok` hardened (fallback chain + anti-flap + diagnostics).
- Ventilation meteo gate hardened (rain/wind/PM2.5 fallback logic).
- Freecooling guard restored with `windows_all_closed`.
- Deploy executed and validated (`ha core check`, restart completed).
- Event-level context evidence closed for:
  - `automation.climateops_system_actuate` (heating chain)
  - AC OFF-enforcement path (`switch.ac_giorno` / `switch.ac_notte`)
- Restart hardening executed:
  - startup schema/template fixes applied
  - Modbus MIRAI polling reduced to essential registers only
  - runtime restart/check validated post-change
- EHW raw template hardening executed:
  - removed non-numeric outputs from raw template sensors
  - commit `2aebc49` pushed on `main`
  - deploy validated with `ha core check` + restart
- Step6 thermostat TEMP hardening executed:
  - remap su sorgenti LDR raw con soglie e isteresi configurabili
  - allineamento plancia heating + documentazione core/heating
  - audit dedicato: `docs/audits/STEP6_THERMOSTAT_TEMP_LDR_THRESHOLD_2026-02-25.md`

## In Progress / Pending
- Step7 avviato: piano esecutivo AEB in 4 micro-step (`forecast`, `tariff/grid`, `multi-load hierarchy`, `KPI closure`).
- Step7.1 implementato a livello repo: forecast input contracts + bridge + docs (`STEP7_1_FORECAST_INPUT_CONTRACTS_2026-02-25.md`).
- Step7.2 implementato a livello repo: tariff/grid policy layer + contracts + bridge (`STEP7_2_TARIFF_GRID_POLICY_2026-02-25.md`).
- Step7.3 implementato a livello repo: hierarchy multi-load + contracts + bridge (`STEP7_3_MULTI_LOAD_HIERARCHY_2026-02-25.md`).
- Step7.4 implementato a livello repo: KPI closure AEB + dashboard (`STEP7_4_KPI_CLOSURE_2026-02-25.md`).
- AEB maturity closure (forecast, tariff/grid-aware logic, multi-load hierarchy, KPI closure) still open.
- Operational task board (`AI/TASKS.md`) allineata con T2/T3 in `In Progress`.

## Evidence index
- `docs/audits/STEP3_RUNTIME_EVIDENCE_POST_DEPLOY_2026-02-24.md`
- `docs/runtime_evidence/2026-02-24/trace_context_correlation_after_restart.txt`
- `docs/runtime_evidence/2026-02-24/trace.saved_traces.after_restart.json`
- `docs/audits/STEP4_RESTART_HARDENING_2026-02-24.md`
- `docs/audits/STEP6_THERMOSTAT_TEMP_LDR_THRESHOLD_2026-02-25.md`
- `docs/audits/STEP7_AEB_EXECUTION_PLAN_2026-02-25.md`
- `docs/audits/STEP7_1_FORECAST_INPUT_CONTRACTS_2026-02-25.md`
- `docs/audits/STEP7_2_TARIFF_GRID_POLICY_2026-02-25.md`
- `docs/audits/STEP7_3_MULTI_LOAD_HIERARCHY_2026-02-25.md`
- `docs/audits/STEP7_4_KPI_CLOSURE_2026-02-25.md`
- `docs/audits/STEP7_POST_PR_RUNTIME_CHECKLIST_2026-02-25.md`
- `docs/audits/STEP7_POST_DEPLOY_RUNTIME_2026-02-25.md`
