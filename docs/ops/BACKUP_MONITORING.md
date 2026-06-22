# Backup Monitoring

## Purpose

This document defines the MVP for local freshness monitoring of the scheduled AEB /
Home Assistant disaster-recovery backup.

## Operational provenance requirement

Every monitoring, DR, restore, migration, infrastructure verification, or deploy note
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
| Access mode | `local filesystem + Windows Task Scheduler` |
| Deploy | `none` |
| Runtime changes | `none` |

## What the check does

- this is a local checker, not a Telegram/email notifier
- reads the local backup root only
- delegates validation to `ops/verify_backup_freshness.ps1`
- emits `DR_BACKUP_ALERT_OK ...` on success
- emits `DR_BACKUP_ALERT_FAIL ...` on failure
- writes a local log under `C:\2_OPS\_repo_archives\aeb\_dr_backups\logs`
  and falls back to `C:\2_OPS\aeb\.tmp\dr_backup_alert_logs` if the primary location is
  not writable
- returns exit code `0` for OK and non-zero for FAIL

## When to run it

Recommended schedule: after the backup task, for example at `14:00` or `13:45`.
The idea is to check freshness after the daily backup has had time to finish.

## Safe commands

### Preview only

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\ops\check_dr_backup_alert.ps1 -Action Preview
```

### Manual run

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\ops\check_dr_backup_alert.ps1 -Action RunJob -BackupRoot "C:\2_OPS\_repo_archives\aeb\_dr_backups" -MaxAgeHours 30
```

### Verify freshness directly

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\ops\verify_backup_freshness.ps1 -BackupRoot "C:\2_OPS\_repo_archives\aeb\_dr_backups" -MaxAgeHours 30
```

### Install a future scheduled task

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\ops\check_dr_backup_alert.ps1 -Action Install -StartTime 14:00
```

### Disable a future scheduled task

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\ops\check_dr_backup_alert.ps1 -Action Remove
```

## OK / FAIL meaning

- `DR_BACKUP_ALERT_OK`: the latest backup is present, parseable, and younger than the
  configured maximum age.
- `DR_BACKUP_ALERT_FAIL`: the backup root is missing, the latest backup is stale, the
  manifest is invalid, or freshness verification failed for another reason.

## Known limits

- no Telegram or email notifications yet
- no automatic task installation unless a human explicitly runs the install command
- no retention pruning in this MVP
- logs are local files only and should be reviewed manually
- the backup task must still run first; this check is only a freshness alert

## Future developments

- Telegram notification on FAIL only
- email notification on FAIL only
- n8n integration
- retention/pruning of backups
- local DR status dashboard
