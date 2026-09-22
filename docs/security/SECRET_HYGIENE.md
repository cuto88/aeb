# AEB secret hygiene baseline

## Scope

This document defines the repository-side contract for AEB and Home Assistant
secret handling. It does not contain credential values and does not authorize
runtime changes, deployment, restart, rotation, or SSH access changes.

## Repository contract

Runtime-only files must remain untracked:

- `.env`
- `secrets.yaml`
- `.storage/`
- backup and secret bundle directories
- private-key files and common key-container formats

The versioned AEB configuration references these Home Assistant `!secret`
keys:

- `ehw_modbus_host`
- `ehw_modbus_port`
- `ehw_modbus_slave`
- `mirai_modbus_host`

The values for these keys belong only in the Home Assistant runtime
`/config/secrets.yaml` (or the path supplied by the approved runtime contract).
They must never be copied into Git, issue comments, audit reports, or chat.

## Developer-machine contract

The non-secret variable names are documented in
`docs/security/dev-machine.env.example`:

- `HA_URL`
- `HA_TOKEN`
- `HA_SSH_HOST_LAN`
- `HA_SSH_HOST_TAILSCALE` (optional alternate transport)
- `HA_SSH_KEY_PATH`
- `HA_SSH_KNOWN_HOSTS`
- `HA_REMOTE_CONTAINER`
- `HA_REMOTE_PATH`

The example is a schema only. A real `.env` is local-only, must not be
committed, and must be provisioned through the operator's protected local
configuration process.

## Runtime contract

The documented target is Home Assistant on `mercurio-edge`, with container
`homeassistant` and configuration path `/config`. Runtime verification must be
performed read-only and must report only key names and status, never values.

The repository cannot declare runtime parity until all required contract
variables are available locally and an authorized read-only audit has verified:

1. the Home Assistant container is running;
2. `/config/secrets.yaml` exists;
3. the runtime key-name set covers the repository key-name set; and
4. `/api/config` is reachable and authenticated without exposing the token.

## Provisioning and rotation

Provisioning is an operator-controlled action outside normal repository
changes. Rotation is required when a credential is confirmed to have been
exposed, copied into Git history, logged, or disclosed outside its intended
scope. Rotation, revocation, SSH access changes, and runtime deployment are
separate approved work items; this baseline only prevents regressions and
documents the handoff.

## Audit classification

- `SAFE`: repository contains no credential value and the reference is
  intentionally runtime-only.
- `LOCAL_ONLY`: required only in protected local or runtime configuration.
- `STALE_REFERENCE`: historical or disabled reference with no active runtime
  dependency.
- `ROTATION_REQUIRED`: a real credential exposure is confirmed.
- `REMOVE_FROM_REPO`: a credential or sensitive artifact is present in the
  current repository and must be removed after any required rotation decision.
- `NEEDS_RUNTIME_VERIFY`: repository contract is known but runtime parity has
  not been checked.

## Read-only audit boundary

The secret-hygiene gate checks repository paths and high-confidence secret
signatures only. It does not read `.env`, `secrets.yaml`, `.storage`, SSH
private keys, or runtime configuration files.

## Baseline evidence — 2026-09-21

The local AEB working copy passed `ops/gate_secret_hygiene.ps1` and the full
`ops/gates_run_ci.ps1` wrapper. No tracked `.env`, `secrets.yaml`, `.storage`,
private-key file, Telegram-token signature, bearer-token signature, or common
cloud-token signature was found.

Runtime parity remains open: the required local contract variables were not
available in the audit process, so API reachability, SSH host-key validation,
container state, and runtime secret-key names were intentionally not checked.
No runtime connection, deployment, restart, rotation, or credential change was
performed.

## Verified runtime result — 2026-09-22

The read-only runtime audit completed successfully against the M61 branch:

- Home Assistant API: reachable and authenticated;
- Home Assistant version: `2026.4.4`;
- configuration directory: `/config`;
- location name: `Casa`;
- SSH target: `mercurio-edge`, user `dscomparin`;
- Home Assistant container: `homeassistant`, running;
- bind mount: `/opt/data/homeassistant` to `/config`;
- runtime `secrets.yaml`: present, owned by `root:root`;
- required repository keys: 4/4 present;
- no secret values were recorded or exposed;
- no rotation, deployment, restart, or runtime modification was required.

Residual review item: runtime `secrets.yaml` was observed with mode `744`.
This is documented for a separate least-privilege review; this workstream did
not change runtime permissions.

Current classification: `RUNTIME_SECURITY_PASS_WITH_REVIEW`.
