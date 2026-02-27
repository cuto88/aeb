# STEP15 Phase6 NO-GO Guard + Retention (2026-02-27)

Date: 2026-02-27  
Scope: aggiungere controllo automatico NO-GO e manutenzione retention nel runner schedulato.

## Boundary

1. Nessuna modifica writer/attuatori.
2. Solo hardening operativo del monitoraggio.
3. Conservata compatibilita' con pipeline Phase4/Phase5.

## Modifiche

1. Nuovo script:
- `ops/phase6_no_go_guard.ps1`
  - Legge l'ultimo `phase4_daily_summary_*.md`.
  - Se `Decision: **GO**` -> exit `0` + file stato `phase6_no_go_guard_<timestamp>.txt`.
  - Se `Decision: **NO-GO**` -> exit `2` + alert file `phase6_no_go_alert_<timestamp>.txt`.
  - Se decisione non parsabile -> exit `3`.

2. Aggiornato:
- `ops/phase5_task_runner.ps1`
  - Esegue in sequenza:
    1) `phase4_daily_runtime_report.ps1`
    2) `phase6_no_go_guard.ps1`
    3) `retention_runtime_evidence.ps1`
  - Fail-fast su qualsiasi step non-zero.

3. Aggiornato:
- `ops/README.md` con note Phase6.

## Verifica runtime (FACT)

Comandi:
1. `powershell -ExecutionPolicy Bypass -File ops/phase6_no_go_guard.ps1`
2. `powershell -ExecutionPolicy Bypass -File ops/phase5_schedule_daily_report.ps1 -Action RunNow`
3. `powershell -ExecutionPolicy Bypass -File ops/phase5_schedule_daily_report.ps1 -Action Status`

Esito:
- NO-GO guard manuale: `NO-GO guard: GO`
- Scheduled task dopo `RunNow`:
  - `State: Ready`
  - `LastTaskResult: 0`
  - `NextRunTime: 2026-02-28 07:30:30`

Evidence:
- `docs/runtime_evidence/2026-02-27/phase5_scheduler_run_*.log`
- `docs/runtime_evidence/2026-02-27/phase4_daily_summary_*.md`
- `docs/runtime_evidence/2026-02-27/phase6_no_go_guard_*.txt`

## Decisione

- Phase6 guardrail: **ENABLED**
- Scheduler chain (report + NO-GO + retention): **ACTIVE**
