# STEP61 - Runtime cleanup audit

Date: 2026-04-22
Scope: `/homeassistant` runtime filesystem on HA host `192.168.178.84:2222`

## FACT

- Runtime inspection found repository/documentation debris under `/homeassistant`.
- Current deploy script excludes documentation and repository metadata from deploy.
- Removed runtime-only debris:
  - `/homeassistant/docs`
  - `/homeassistant/logic`
  - `/homeassistant/.git`
  - `/homeassistant/.github`
  - `/homeassistant/.codex_backup_20260224_144431`
  - `/homeassistant/_backup`
  - `/homeassistant/_backup_codex`
  - `/homeassistant/README.md`
  - `/homeassistant/README_ClimaSystem.md`
  - `/homeassistant/.editorconfig`
  - `/homeassistant/.gitattributes`
  - `/homeassistant/.gitignore`
  - `/homeassistant/.yamllint`
  - `/homeassistant/configuration.yaml.bak_clima_unified_2026-03-01`
  - `/homeassistant/configuration.yaml.bak_rm_climateops_2026-03-01`
  - `/homeassistant/configuration.yaml?`
  - `/homeassistant/secrets.yaml.bak-20260307_100643`
  - `/homeassistant/secrets.yaml.bak-mirai-20260307`
- Post-cleanup suspicious-file scan returned no matches for:
  - `*.md`
  - `*.txt`
  - `*.bak`
  - `*~`
  - `*.tmp`
  - `configuration.yaml?`
- `ha core check` completed successfully after cleanup.

## IPOTESI

- Confidenza alta: the removed paths were historical deploy/repo/back-up residue, not active HA runtime dependencies.
- Confidenza alta: active runtime config remains in the expected paths: `configuration.yaml`, `packages`, `lovelace`, `custom_components`, `www`, `themes`, `.storage`, `secrets.yaml`.
- Confidenza media: `/homeassistant/_ha_runtime_backups` is intentional operational retention and should not be removed without a separate retention policy.
- Confidenza alta: the corrupt recorder DB retained from the 2026-04-21 incident is evidence/rollback material and should remain until an explicit recorder-retention decision.

## DECISIONE

- Keep runtime filesystem focused on HA execution artifacts only.
- Keep documentation, audits, design notes, and repo metadata only in Git/repository, not in `/homeassistant`.
- Do not remove `.storage`, active DB files, package directories, secrets, custom components, Lovelace, themes, `www`, or runtime backups in this cleanup pass.
- Treat future documentation found under `/homeassistant` as deploy leakage unless explicitly justified.

## Verification Snapshot

Remaining root items after cleanup:

- `.HA_VERSION`
- `.cache`
- `.cloud`
- `.ha_run.lock`
- `.ops_state`
- `.storage`
- `_ha_runtime_backups`
- `blueprints`
- `configuration.yaml`
- `custom_components`
- `deps`
- `esphome`
- `home-assistant.log.fault`
- `home-assistant_v2.db`
- `home-assistant_v2.db-shm`
- `home-assistant_v2.db-wal`
- `home-assistant_v2.db.corrupt.2026-04-21T20:44:59.837397+00:00`
- `lovelace`
- `packages`
- `secrets.yaml`
- `themes`
- `tts`
- `www`

## Next Controls

- Add a deploy preflight check that fails if docs, repo metadata, or backup files are staged for `/homeassistant`.
- Add a lightweight runtime hygiene audit after each deploy.
- Define a retention policy for `_ha_runtime_backups` and the corrupt recorder DB separately from deploy cleanup.
