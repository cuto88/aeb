# M64 — AEB DRY deploy and commissioning audit

- Date: 2026-09-24
- Machine: DS-WORK
- Runtime: `mercurio-edge` / `192.168.178.110`, container `homeassistant`
- Runtime config: `/opt/data/homeassistant` (container bind `/config`)
- Access: LAN SSH, SCP, and Home Assistant API
- Broad deploy: no
- Runtime modified: yes, only the three authorized package files

## Baseline and patch provenance

- `git fetch origin main`: passed.
- `origin/main`: `88473f4` (`Merge M65 documentation consistency fix`).
- Required M64 commit `29b8f56df557340c4590d1fc4655d9e2af0b7024` is an ancestor of `origin/main`.
- Offline commit `409dd16` was not present in the old local repository and was not used.
- The M64 diff was restricted to these five files: the three runtime packages, `ops/gate_ac_dry_mode_policy.ps1`, and `ops/gates_run_ci.ps1`.
- M61 security hygiene changes were preserved.
- `C:\2_OPS\aeb` was not modified.

## Gates before deploy

- DRY policy gate: PASS.
- Secret hygiene gate: PASS; no credentials or `HA_*` values recorded.
- Complete gate set: individual gates PASS (include tree, HA structure, VMC/Lovelace, naming, CM naming, nested-template, AC night policy, DRY policy, docs links, artifact policy).
- Scoped yamllint used by the suite: PASS with existing non-blocking line-length warnings.
- Full-repository yamllint reports pre-existing errors in `data/systems.yaml`, outside the suite scope and outside this change.
- `git diff --check`: PASS.

## Pre-deploy runtime audit

The runtime was confirmed pre-M64: `input_boolean.ac_auto_dry_enabled`, `sensor.ac_giorno_requested_hvac_mode`, and `sensor.ac_notte_requested_hvac_mode` returned 404. Both climate entities already exposed `dry`.

Initial audit evidence:

| Entity | State | Setpoint / modes | Context ID |
|---|---|---|---|
| `climate.ac_giorno` | `cool` | `24`; `heat_cool,cool,dry,fan_only,heat,off` | `01M37WSGXNZK22447EZD17JMBM` |
| `climate.ac_notte` | `cool` | `24`; `heat_cool,cool,dry,fan_only,heat,off` | `01M37WSGXQ7EMWF96P4WCNN0DY` |
| `switch.ac_giorno` | `off` | — | `01M37WVHWPA8S84JDK76XR4VRC` |
| `switch.ac_notte` | `on` | — | `01M38YV224HFRVR7VXX7BM2ZZ0` |

Immediately before deployment, `switch.ac_notte` had transitioned to `off` with a new runtime context; it was not forced back on.

## Hashes and backup

Pre-deploy runtime hashes:

| File | SHA-256 |
|---|---|
| `packages/climate_ac_comfort_control.yaml` | `00b284bfb396ba0a16a5de4ee5ffe42ca6faaa92da253e091b2ee5bf4446559f` |
| `packages/climate_ac_mapping.yaml` | `dea9c2e76360bf7860fb5d08a3e98d5509c37687f966d63af211ad5b8d75ddfb` |
| `packages/climateops/actuators/system_actuator.yaml` | `8a6879ec94787fda7003bf90e2b1fd57e6a4cafdf61f346cb98318850151b7e3` |

Timestamped backup:

`/config/backups/aeb_m64_dry_20260924_090205/`

The backup hashes matched the pre-deploy runtime hashes. Drift guard passed.

## Deploy and restart

- Copied only the three authorized package files.
- Post-copy hashes matched the expected local M64 hashes:
  - `packages/climate_ac_comfort_control.yaml`: `8361c66b75ac2dbe1090d7f2ad4f6ac0d61ef05c4cf96e3e11531103e30ba65c`
  - `packages/climate_ac_mapping.yaml`: `8f32453bcaafcb55040e7da26d14c8964baf3e5c5b1f0824b8084fe45cd036a2`
  - `packages/climateops/actuators/system_actuator.yaml`: `e48705f1a6b83e1c943747634fb60a64c7139eba1b50955b8081b637f6ccbe71`
- Pre-deploy config check: PASS, 0 errors, 0 warnings.
- Post-copy config check: PASS, 0 errors, 0 warnings.
- Restart: controlled restart of `homeassistant` only; return code 0.
- API after restart: available.
- Automatic rollback: not triggered.

## Post-restart runtime verification

- `input_boolean.ac_auto_dry_enabled`: `on`.
- `sensor.ac_giorno_requested_hvac_mode`: present, final state `off`, `dry_supported=true`, reason `COMFORT_SATISFIED`.
- `sensor.ac_notte_requested_hvac_mode`: present, final state `off`, `dry_supported=true`, reason `COMFORT_SATISFIED`.
- `climate.ac_giorno`: `cool`, 24°C, `dry` present in `hvac_modes`.
- `climate.ac_notte`: `cool`, 24°C, `dry` present in `hvac_modes`.
- Final switches: `switch.ac_giorno=off`, `switch.ac_notte=off`. The night switch was not forced on because the live automation/request state was `off` and the observed pre-deploy transition had already occurred.

## Reversible test matrix

### Structural/template test

Executed through Home Assistant `/api/template` using synthetic values only; no sensor states, helpers, thresholds, or automations were changed.

| Case | Result |
|---|---|
| Humidity-only demand | `dry` |
| Thermal demand | `cool` |
| Combined demand | `cool` (thermal priority) |
| Hysteresis hold from DRY | `dry` |
| DRY unsupported fallback | `cool` |
| DRY helper disabled / previous behavior | `cool` |

### Reversible climate actuation

- `climate.set_hvac_mode(dry)` on both climate entities: accepted; both reported `dry`.
- DRY context ID: `01M393WT4XE76CBMNVZ2W794R8`.
- `climate.set_hvac_mode(cool)` on both entities, followed by `climate.set_temperature(24)`: accepted.
- Final COOL context ID: `01M393WZGX51SRA6B1BWWNXKGS`.
- No test override, helper change, threshold change, or automation disable was left active.
- No real humidity-only demand was available during this run; end-to-end automatic promotion from a real event remains observation work for the next qualifying event.

## Errors and evidence qualification

No M64-specific template, climate, or actuator errors were found in the post-restart filtered logs. The runtime log contained unrelated/pre-existing Modbus and Meross timeouts, duplicate template unique-ID messages, and unavailable external sensors; these are recorded as environmental noise and were not introduced by the M64 files.

## Publication status

- Audit updated locally.
- Commit/PR: not created; local Git mutation remains disabled by repository policy.
- `CHAT_PORTFOLIO`: not updated, pending the user's requested publication workflow.
- No credentials, tokens, or HA secret values are recorded.

**Task status: NON ARCHIVIABILE.** Runtime deployment and verification are complete, but the audit still requires publication through the approved branch/PR workflow before archival.
