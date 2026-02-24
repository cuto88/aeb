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

## In Progress / Pending
- AEB maturity closure (forecast, tariff/grid-aware logic, multi-load hierarchy, KPI closure) still open.
- Operational task board (`AI/TASKS.md`) still marks T2/T3 as `Planned`.

## Evidence index
- `docs/audits/STEP3_RUNTIME_EVIDENCE_POST_DEPLOY_2026-02-24.md`
- `docs/runtime_evidence/2026-02-24/trace_context_correlation_after_restart.txt`
- `docs/runtime_evidence/2026-02-24/trace.saved_traces.after_restart.json`
- `docs/audits/STEP4_RESTART_HARDENING_2026-02-24.md`
