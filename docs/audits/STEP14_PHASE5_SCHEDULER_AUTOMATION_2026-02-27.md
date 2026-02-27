# STEP14 Phase5 Scheduler Automation (2026-02-27)

Date: 2026-02-27  
Scope: schedulazione automatica giornaliera del report runtime con validazione run-time.

## Boundary

1. Nessuna modifica writer/attuatori.
2. Solo automazione operativa locale (Windows Task Scheduler).
3. Monitoraggio GO/NO-GO invariato (Phase4).

## Modifiche

1. Nuovo script scheduler:
- `ops/phase5_schedule_daily_report.ps1`
  - Azioni supportate: `Install`, `Status`, `RunNow`, `Remove`
  - Task name default: `CasaMercurio-Phase4-DailyRuntimeReport`
  - Orario default: `07:30`

2. Nuovo runner task:
- `ops/phase5_task_runner.ps1`
  - Esegue `ops/phase4_daily_runtime_report.ps1`
  - Salva log esecuzione scheduler in:
    - `docs/runtime_evidence/<date>/phase5_scheduler_run_<timestamp>.log`
  - Restituisce exit code esplicito (`0` success, `1` fail)

3. Aggiornamento:
- `ops/README.md` (comandi scheduler + path log runner).

## Esecuzione e verifica (FACT)

Comandi:
1. `powershell -ExecutionPolicy Bypass -File ops/phase5_schedule_daily_report.ps1 -Action Install -StartTime 07:30`
2. `powershell -ExecutionPolicy Bypass -File ops/phase5_schedule_daily_report.ps1 -Action RunNow`
3. `powershell -ExecutionPolicy Bypass -File ops/phase5_schedule_daily_report.ps1 -Action Status`

Esito:
- Task installato e pianificato: next run `2026-02-28 07:30:30`
- Esecuzione `RunNow` completata
- `LastTaskResult: 0`

Evidence:
- `docs/runtime_evidence/2026-02-27/phase5_scheduler_run_*.log`
- `docs/runtime_evidence/2026-02-27/phase4_daily_summary_20260227_185305.md`
- `docs/runtime_evidence/2026-02-27/phase1_runtime_truth_scan_current_boot_20260227_185325.txt`
- `docs/runtime_evidence/2026-02-27/phase1_runtime_truth_writer_scan_20260227_185325.txt`

## Decisione

- Phase5 scheduler: **ENABLED**
- Stato operativo giornaliero: **AUTOMATED**
