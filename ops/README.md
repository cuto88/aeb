# Ops notes

## UTF-8 hygiene
- Keep YAML/MD/JSON/JS/TS/CSS files encoded as UTF-8 without BOM.
- Run `ops/check_utf8_mojibake.ps1` (or `ops/gates_run.ps1`) to detect mojibake regressions.
- `ops/gates_run.ps1` includes the DOCS gate for markdown link/reference validation.

## supervisor/
- Host-side scripts for the AEB supervisor bridge contract.
- Current scripts:
  - `ops/supervisor/build_supervisor_payload.ps1`
  - `ops/supervisor/write_supervisor_report.ps1`
  - `ops/supervisor/write_supervisor_handoff.ps1`
- Intended usage:
  - called by the host bridge used by `n8n`
  - restricted to read/write only approved `aeb` supervisor paths
  - output JSON suitable for bridge passthrough

## deploy_safe.ps1
- The script preflights the target path before the backup. If `Z:\` is missing it attempts to map the drive.
- The script also preflights stale Git index locks and removes old `index.lock` files before the first Git command.
- Customize SMB mapping with `HA_SMB_SHARE`, `HA_SMB_USER`, and `HA_SMB_PASS` environment variables (avoid committing secrets).
- `deploy_safe.ps1` refuses to run if `configuration.yaml` or `secrets.yaml` is missing on the target.
- `tts/` and `www/` are excluded by default; use `-IncludeTts` / `-IncludeWww` to deploy them intentionally.
- Optional post-deploy check: `-RunConfigCheck` (runs `ha core check` when the HA CLI is available).

## Shared git lock cleanup
- Shared helper: `C:\2_OPS\00_shared\scripts\Resolve-StaleGitLocks.ps1`
- Default behavior: removes only stale `index.lock` files older than 15 minutes and only when no Git process is running.
- Root cause already observed on `2026-04-10`: broken ACLs on `C:\2_OPS\aeb\.git-local` can allow lock creation but block lock deletion, leaving Git stuck on `index.lock`.
- When `git add`, `git commit`, or deploy preflight fail with `Unable to create ... index.lock` or `unable to unlink ... index.lock`, verify the directory permissions on `.git-local` before treating the file as a simple stale lock.
- Optional broader cleanup:
  - `.\00_shared\scripts\Resolve-StaleGitLocks.ps1 -Root C:\2_OPS -IncludeTempLocks -WhatIf`
  - `.\00_shared\scripts\Resolve-StaleGitLocks.ps1 -Root C:\2_OPS -IncludeTempLocks`

## retention_runtime_evidence.ps1
- Prunes old local runtime evidence and backups:
  - `docs/runtime_evidence/`
  - `_ha_runtime_backups/`
- Retention is age-based with minimum preserved snapshots (`KeepLatest*`) to avoid over-pruning.
- Use `-WhatIf` first to preview deletions.
- Defaults:
  - `EvidenceRetentionDays=14`, `KeepLatestEvidence=3`
  - `BackupRetentionDays=21`, `KeepLatestBackups=5`

## involucro_audit_snapshot.ps1
- Captures a read-only runtime snapshot for the envelope/involucro audit.
- Reads Home Assistant Core states through SSH to the HA host and writes:
  - `docs/runtime_evidence/<date>/involucro_audit_snapshot_<window>_<timestamp>.md`
  - `docs/runtime_evidence/<date>/involucro_audit_snapshot_<window>_<timestamp>.json`
- Uses `HA_TOKEN` from `.env`.
- Assumes shutters are open by default; annotate shutters only when they are actually closed or when running a targeted test.
- Example:
  - `.\ops\involucro_audit_snapshot.ps1 -WindowType night_flush`

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
- `.\ops\involucro_audit_snapshot.ps1 -WindowType night_flush`
- `.\ops\retention_runtime_evidence.ps1 -WhatIf`
- `.\ops\retention_runtime_evidence.ps1`
- `.\ops\phase5_schedule_daily_report.ps1 -Action Install -StartTime 07:30`
- `.\ops\phase5_schedule_daily_report.ps1 -Action Status`
- `.\ops\phase5_schedule_daily_report.ps1 -Action RunNow`
- Scheduler runner log: `docs/runtime_evidence/<date>/phase5_scheduler_run_<timestamp>.log`
- `.\ops\phase6_no_go_guard.ps1` validates latest Phase4 decision (`GO` => exit 0, `NO-GO` => exit 2 + alert file).
- `.\ops\phase7_executive_status.ps1` writes a compact one-file executive snapshot.
- Scheduled runner now also executes:
  - `phase6_no_go_guard.ps1`
  - `retention_runtime_evidence.ps1`
  - `phase7_executive_status.ps1`
