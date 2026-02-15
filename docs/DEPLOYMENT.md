# Home Assistant Deployment (Safe, Non-Destructive)

This repository is the **source of truth** for Home Assistant configuration, but **stateful runtime data must never be deleted or overwritten**. The deploy workflow below is designed to be safe, repeatable, and to **protect `secrets.yaml` and other runtime folders**.

## What gets deployed

`ops/deploy_safe.ps1` mirrors the repository into the Home Assistant `/config` directory while applying strict exclusions (see below). It also runs repo gates before copying.

## What is excluded (and why)

These paths are **stateful** or **host-owned** and must not be removed or replaced during deploy:

- `secrets.yaml` (host-only secrets; must never be deleted or overwritten)
- `.storage/` (Home Assistant runtime state)
- `.cloud/` (Home Assistant cloud state)
- `backup/`, `backups/` (snapshots/backups)
- `media/` (local media files)
- `tts/` (generated TTS cache — excluded by default)
- `www/` (static assets, often stateful in HA — excluded by default)

> Note: `tts/` and `www/` are excluded **by default**. Use the explicit flags to include them if desired.

## How to run deploy

From a PowerShell prompt on Windows:

```powershell
# Default safe deploy (excludes secrets.yaml, .storage, tts, www, etc.)
./ops/deploy_safe.ps1 -Target Z:\
```

Optional flags:

```powershell
# Include tts/ and www/ if you explicitly want them
./ops/deploy_safe.ps1 -Target Z:\ -IncludeTts -IncludeWww

# Run a post-deploy HA config check when HA CLI is available
./ops/deploy_safe.ps1 -Target Z:\ -RunConfigCheck
```

Environment variables for mapping the SMB share (if `Z:` is missing):

- `HA_SMB_SHARE` (e.g., `\\192.168.178.84\config`)
- `HA_SMB_USER`
- `HA_SMB_PASS`

## Pre-flight safety gates

The deploy **aborts** if:

- The target path does not exist or is not reachable.
- `configuration.yaml` is missing on the target.
- `secrets.yaml` is missing on the target.
- `secrets.yaml` appears invalid (no `key: value` entries).

These checks prevent accidental deployment to the wrong folder and guard against deleting or overwriting secrets.

## Post-deploy config check (optional)

If `-RunConfigCheck` is used and the Home Assistant CLI is available, the script runs:

```
ha core check
```

If the CLI is not available, run it on the HA host or use **Settings → System → Repairs → Check Configuration** in the UI.

## Rollback procedure

`deploy_safe.ps1` creates a timestamped backup in `_ha_runtime_backups/`. To rollback:

1. Identify the desired backup folder (e.g., `_ha_runtime_backups/deploy_20240123_141500`).
2. Mirror it back to `/config` **without deleting stateful data**:

```powershell
robocopy _ha_runtime_backups\deploy_YYYYMMDD_HHMMSS Z:\ /MIR /XF secrets.yaml /XD .storage tts www .cloud backup backups media
```

## Troubleshooting

### “Secrets is not a dictionary”

This error usually indicates `secrets.yaml` is missing or invalid. The deploy script now **aborts** before any file operations if `secrets.yaml` is missing or fails a basic sanity check. Ensure `secrets.yaml` exists on the HA host and contains valid `key: value` entries.

### Deploy fails with robocopy errors

Robocopy exit codes **0–7** are OK. **8+** indicates a failure (permissions, file locks, or invalid path). Ensure the HA target path is accessible and not open in another process.

## Canonical deploy script

- **Use:** `ops/deploy_safe.ps1`
- **Legacy (archived):** `ops/_archive/synch_ha.ps1` (kept for reference; it now includes the same safety exclusions but is not the recommended path).

## Smoke test 60s

Eseguire questi 4 check rapidi dopo deploy/cutover ClimateOps v1.0:

- `cm_contract_missing_entities=OK`
- `cm_contract_actuators_defined=on`
- `cm_system_mode_suggested` non `unavailable`
- Boost VMC funziona: `vmc_vel_3` ON quando `target=3`

## Contracts quick check

- `cm_contract_missing_entities` must be OK
- `cm_contract_actuators_defined` must be ON
