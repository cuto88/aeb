# Ops notes

## UTF-8 hygiene
- Keep YAML/MD/JSON/JS/TS/CSS files encoded as UTF-8 without BOM.
- Run `ops/check_utf8_mojibake.ps1` (or `ops/gates_run.ps1`) to detect mojibake regressions.
- `ops/gates_run.ps1` includes the DOCS gate for markdown link/reference validation.

## deploy_safe.ps1
- The script preflights the target path before the backup. If `Z:\` is missing it attempts to map the drive.
- Customize SMB mapping with `HA_SMB_SHARE`, `HA_SMB_USER`, and `HA_SMB_PASS` environment variables (avoid committing secrets).
- `deploy_safe.ps1` refuses to run if `configuration.yaml` or `secrets.yaml` is missing on the target.
- `tts/` and `www/` are excluded by default; use `-IncludeTts` / `-IncludeWww` to deploy them intentionally.
- Optional post-deploy check: `-RunConfigCheck` (runs `ha core check` when the HA CLI is available).

## retention_runtime_evidence.ps1
- Prunes old local runtime evidence and backups:
  - `docs/runtime_evidence/`
  - `_ha_runtime_backups/`
- Retention is age-based with minimum preserved snapshots (`KeepLatest*`) to avoid over-pruning.
- Use `-WhatIf` first to preview deletions.
- Defaults:
  - `EvidenceRetentionDays=14`, `KeepLatestEvidence=3`
  - `BackupRetentionDays=21`, `KeepLatestBackups=5`

## How to run
Pipeline ufficiale:
1) `repo_sync`
2) `gates_run`
3) `deploy_safe`

Nota: `repo_sync_and_gates` resta disponibile per compatibilità.

## PowerShell shortcuts
- The PowerShell shortcut functions live in `ops/profile.ps1`.
- `$PROFILE` only dot-sources that file for auto-updated ops naming.

Esempi:
- `.\ops\repo_sync_and_gates.ps1`
- `.\ops\repo_sync.ps1`
- `.\ops\gates_run.ps1`
- `.\ops\deploy_safe.ps1`
- `.\ops\deploy_safe.ps1 -RunGates` (solo per uso standalone)
- `.\ops\retention_runtime_evidence.ps1 -WhatIf`
- `.\ops\retention_runtime_evidence.ps1`
- `.\ops\phase5_schedule_daily_report.ps1 -Action Install -StartTime 07:30`
- `.\ops\phase5_schedule_daily_report.ps1 -Action Status`
- `.\ops\phase5_schedule_daily_report.ps1 -Action RunNow`
- Scheduler runner log: `docs/runtime_evidence/<date>/phase5_scheduler_run_<timestamp>.log`
- `.\ops\phase6_no_go_guard.ps1` validates latest Phase4 decision (`GO` => exit 0, `NO-GO` => exit 2 + alert file).
- Scheduled runner now also executes:
  - `phase6_no_go_guard.ps1`
  - `retention_runtime_evidence.ps1`
