# AEB Secret Hygiene Baseline

## Scope

This document defines the repo/runtime contract for Home Assistant secrets used by AEB.
It covers repository content, developer workstations and the Home Assistant runtime.
It does not define n8n credential handling.

## Baseline

- Real secrets MUST NOT be committed to Git.
- Home Assistant runtime secrets belong in `/config/secrets.yaml` and are referenced from versioned YAML with `!secret`.
- Developer-machine credentials belong in local environment variables loaded from an ignored `.env` file.
- Private SSH keys and verified `known_hosts` files stay outside Git.
- Runtime evidence and backups that may contain credentials stay outside Git unless explicitly sanitized.
- Repository examples contain placeholders only.

## Versioned contract

Tracked files MAY contain:

- `!secret <name>` references;
- placeholder values in `docs/security/*.example`;
- variable names such as `HA_TOKEN`, `HA_SSH_KEY_PATH` and `HA_SSH_KNOWN_HOSTS`;
- non-secret internal endpoints when operationally justified.

Tracked files MUST NOT contain:

- live Home Assistant long-lived access tokens;
- Telegram bot tokens;
- passwords or API keys;
- private-key material;
- live `secrets.yaml` or `.env`;
- credential bundles or copied SSH keys.

## Runtime provisioning

1. Create the local `.env` from `docs/security/dev-machine.env.example`.
2. Populate values locally without printing them to logs.
3. Keep `HA_TOKEN`, `HA_SSH_KEY_PATH` and `HA_SSH_KNOWN_HOSTS` outside the repository.
4. Ensure Home Assistant `/config/secrets.yaml` contains the keys required by versioned `!secret` references.
5. Validate read-only API/SSH access before any deploy.
6. Never copy runtime secret values into documentation, issues, pull requests or chat transcripts.

## Rotation procedure

Rotation is an approval-gated operation.

1. Identify the affected credential and every consumer.
2. Create a replacement credential at the authoritative system.
3. Update only the local/runtime secret store.
4. Verify read-only access with the replacement.
5. Revoke the old credential.
6. Run the AEB quality gates.
7. Record the rotation date, credential type and verification result without storing the secret value.

If a credential may have been committed historically, rotate it even if it was later removed.
History rewriting is optional and requires separate approval; rotation is the security control.

## Classification

Use these labels during audits:

- `SAFE`: tracked content is non-sensitive and intentional.
- `LOCAL_ONLY`: required locally/runtime but must not be tracked.
- `STALE_REFERENCE`: obsolete host/path/credential reference with no current secret value.
- `ROTATION_REQUIRED`: a credential is known or reasonably suspected to have been exposed.
- `REMOVE_FROM_REPO`: live sensitive material exists in tracked content.
- `NEEDS_RUNTIME_VERIFY`: repository contract is clear but the live runtime has not been checked.

## Current baseline audit — 2026-09-20

- Current-tree `secrets.yaml`: not tracked.
- Current-tree `.env`: not tracked.
- Current-tree private key files: not identified.
- `packages/ehw_modbus_transport.yaml`: uses `!secret` for host/port/slave.
- `packages/mirai_modbus.yaml`: uses `!secret` for host.
- Developer credentials are documented through placeholders in `docs/security/dev-machine.env.example`.
- Git history lookup for paths `secrets.yaml`, `.env`, `id_rsa`, `id_ed25519`: no commits returned by the repository API.
- Active ops scripts no longer contain the previously identified hardcoded LAN/API endpoint fallbacks; `HA_SSH_HOST_LAN` and `HA_URL` are now explicit runtime inputs.
- Live runtime values were not read or changed during this audit.

## Verification

Run:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File ops/gate_secret_hygiene.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File ops/gates_run_ci.ps1
```

The gate is intentionally conservative and checks only high-confidence secret regressions.
It is not a substitute for credential rotation after a known exposure.
