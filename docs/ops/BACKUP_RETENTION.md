# Backup Retention

## Purpose

This document defines the MVP retention policy for AEB / Home Assistant DR backups.
The current implementation is preview-first and does not delete anything by default.

## Operational provenance requirement

Every retention, DR, restore, migration, infrastructure verification, or deploy note
must state:

- operator machine used;
- runtime target verified or touched;
- legacy machine status, if relevant;
- access mode used: local filesystem, Windows Task Scheduler, Tailscale, SSH, HA API,
  GitHub Actions, or similar;
- deploy executed: yes/no;
- runtime changes executed: yes/no;
- relevant commits or GitHub Actions runs, if present.

## Provenance for this MVP

| Field | Value |
| --- | --- |
| Operator machine | `DS-WORK` |
| Runtime target | `none / local backup root only` |
| Legacy machine status | `DS-01 powered off` |
| Access mode | `local filesystem` |
| Deploy | `none` |
| Runtime changes | `none` |

## Proposed rule

- keep the latest valid snapshot always
- keep one daily snapshot per day for the last `14` days
- keep one weekly snapshot per ISO week for the last `8` weeks after the daily window
- optionally protect explicit snapshot names with `-ProtectedSnapshots`
- ignore non-snapshot directories, files, logs, and malformed names

The retention script only considers directories that match:

`ha_runtime_snapshot_YYYYMMDD_HHMMSS`

and that also contain a valid `manifest.json`.

## Current implementation

- script: `ops/dr_backup_retention.ps1`
- default action: `Preview`
- real prune mode exists only as an explicit `-Action Prune -ConfirmPrune`
- real prune mode is not exercised in this step

## Preview output

The preview prints:

- `DR_RETENTION_PREVIEW`
- `KEEP ... reason=latest`
- `KEEP ... reason=daily`
- `KEEP ... reason=weekly`
- `DELETE_CANDIDATE ...`
- `estimated_freed_bytes=...`

## Safe commands

### Preview only

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\ops\dr_backup_retention.ps1 -Action Preview
```

### Preview with protected snapshots

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\ops\dr_backup_retention.ps1 -Action Preview -ProtectedSnapshots ha_runtime_snapshot_20260622_121348
```

### Real prune

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\ops\dr_backup_retention.ps1 -Action Prune -ConfirmPrune
```

Real prune is intentionally not used yet. It should be enabled only after manual
validation of the preview output.

## Why auto-delete is not enabled

- the latest valid snapshot must never be deleted by mistake
- the restore drill snapshot must remain protected until a separate policy says otherwise
- a malformed directory name or partial backup must not be mistaken for a valid snapshot
- manual review of the preview output is the safer transition step

## Risks

- disk growth if pruning is never activated
- over-pruning if the preview logic is changed without review
- confusion between valid backups and partial or malformed directories
- accidental removal of a restore-drill snapshot if protections are not configured

## Future developments

- scheduled pruning task only after manual validation of the preview output
- optional dashboard or report summarizing keep/delete candidates
- integration with the freshness alert flow if retention pressure becomes operationally relevant
