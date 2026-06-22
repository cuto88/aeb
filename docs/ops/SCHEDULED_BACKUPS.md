# Scheduled DR Backups

## Purpose

This document defines the MVP for periodic AEB / Home Assistant disaster-recovery backups
from DS-WORK without touching the live Home Assistant runtime.

## Operational provenance requirement

Every scheduled-backup note, audit, cutover, DR, restore, migration, infrastructure
verification, or deploy record must state:

- operator machine used;
- runtime target verified or touched;
- legacy machine status, if relevant;
- access mode used: LAN, Tailscale, SSH, HA API, GitHub Actions, local filesystem, or similar;
- deploy executed: yes/no;
- runtime changes executed: yes/no;
- relevant commits or GitHub Actions runs, if present.

## Provenance for this MVP

| Field | Value |
| --- | --- |
| Operator machine | `DS-WORK` |
| Runtime target | `mercurio-edge` |
| Legacy machine status | `DS-01 powered off` |
| Access mode | `Tailscale + SSH + local filesystem` |
| Deploy | `none` |
| Runtime changes | `none` |

## Scripts

- core backup job: `ops/dr_backup_task.ps1`
- scheduler wrapper: `ops/schedule_dr_backup_task.ps1`
- freshness verifier: `ops/verify_backup_freshness.ps1`

The wrapper loads the local `.env`, prefers `HA_SSH_HOST_TAILSCALE` for the remote
host, falls back to `HA_SSH_HOST_LAN` when needed, runs the core DR backup job, and
performs a freshness check in the same pass.

## Default paths

- source snapshot target: `__REMOTE_HOME_ASSISTANT_CONFIG__`
- backup root: `C:\2_OPS\_repo_archives\aeb\_dr_backups`
- restore drill target: not used here

## Safe commands

### Preview only

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\ops\schedule_dr_backup_task.ps1 -Action Preview
```

### Install the scheduled task

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\ops\schedule_dr_backup_task.ps1 -Action Install
```

Recommended first step if you want a no-side-effect check:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\ops\schedule_dr_backup_task.ps1 -Action Install -WhatIf
```

Verification rule: the `-WhatIf` output must not echo any real `.env` value, especially
`HA_TOKEN` or any variable name containing `TOKEN`, `SECRET`, `PASSWORD`, `KEY`, or
`CREDENTIAL`.

### Run one scheduled pass manually

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\ops\schedule_dr_backup_task.ps1 -Action RunJob
```

### Verify freshness

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\ops\verify_backup_freshness.ps1 -BackupRoot "C:\2_OPS\_repo_archives\aeb\_dr_backups" -MaxAgeHours 24
```

### Disable the task

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\ops\schedule_dr_backup_task.ps1 -Action Remove
```

## Known limits

- no automatic activation without human confirmation
- no automatic retention pruning in this MVP
- no deploy to Home Assistant
- no runtime modification
- `dr_backup_task.ps1` remains the core engine and still owns the actual backup logic
- this setup is designed for DS-WORK and should not assume DS-01 is available

## Notes

- Use this MVP only after the local `.env` has been validated.
- If the task must be changed, preview first and avoid removing the task until the new
  configuration has been checked.
- Freshness monitoring for the daily backup is documented in `docs/ops/BACKUP_MONITORING.md`.
