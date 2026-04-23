# STEP72 - Observability runner validation

Date: 2026-04-23
Scope: recorder-independent evidence continuity while MIRAI manual window is unavailable.

## FACT

- MIRAI runtime truth cannot be executed without a human-observable run window.
- `ops/aeb_runtime_audit_snapshot.ps1` and `ops/phase5_task_runner.ps1` already implement the recorder-safe evidence path.
- `ops/retention_runtime_evidence.ps1` still depended on `git rev-parse --show-toplevel`.
- This repository currently has no local `.git` pointer, so `git rev-parse` fails by design.
- Windows Task Scheduler registration is blocked in this session:
  - `New-ScheduledTaskTrigger`: `Accesso negato`
  - `Register-ScheduledJob`: access denied; elevated PowerShell required

## IPOTESI

- Confidenza alta: the correct non-MIRAI next step is observability continuity, not new automation logic.
- Confidenza alta: the runner must work without local Git because this repo is now connector-first.
- Confidenza alta: scheduled installation is an environment/privilege boundary, not an application failure.

## DECISIONE

- Add script-relative repo-root fallback to `ops/retention_runtime_evidence.ps1`.
- Add safe manual validation controls to `ops/phase5_task_runner.ps1`:
  - `-SkipRetention`
  - `-RetentionWhatIf`
- Do not weaken quality gates.
- Do not require runtime deployment.
- Treat scheduler installation as blocked until the user runs the install from an elevated/user-permitted shell.

## Verification

- `ops/retention_runtime_evidence.ps1 -WhatIf`: passed.
- `ops/phase5_task_runner.ps1 -RetentionWhatIf`: passed.
- Generated evidence under `docs/runtime_evidence/2026-04-23/`:
  - `phase4_daily_summary_20260423_113655.md`
  - `aeb_runtime_audit_snapshot_20260423_113842.md`
  - `aeb_runtime_audit_snapshot_20260423_113842.json`
  - `phase6_no_go_guard_20260423_113847.txt`
  - `phase7_executive_status_20260423_113850.txt`
  - `phase5_scheduler_run_20260423_113654.log`
- Phase4 daily summary result:
  - `Decision: GO`
  - `HA core check: PASS`
  - `Current boot Phase1 errors: PASS`
  - `Phase1 writer service scan: PASS`
- `ops/gates_run_ci.ps1`: `ALL GATES PASSED`.

## Manual Safe Command

Use this when a manual recorder-safe evidence pack is needed:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ops\phase5_task_runner.ps1 -RetentionWhatIf
```

Use this only when retention pruning is intentionally allowed:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ops\phase5_task_runner.ps1
```

## Remaining Boundary

- Daily automation is not installed from this session because Windows denied scheduled task registration.
- To install it later, run from a permitted/elevated shell:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ops\phase5_schedule_daily_report.ps1 -Action Install -StartTime 07:30
```

- Until then, evidence continuity is validated but manual/on-demand.
