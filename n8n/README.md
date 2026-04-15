# AEB n8n

Workflow canonici `n8n` per il supervisore `aeb`.

## Files

- `workflows/aeb_supervisor_readonly_mvp.json`

## Runtime assumptions

- `n8n` gira nel container Linux.
- Accesso host-side tramite bridge su `http://host.docker.internal:8787`.
- Owner canonico del bridge: `C:\2_OPS\n8n-bridge`.
- Il workflow usa credenziali native gia` presenti in `n8n` per OpenAI e Gmail.

## Required n8n credentials

- `OpenAi account`
- `Gmail account`

## Optional env vars

- `AEB_SUPERVISOR_MODEL` default: `gpt-5.2`

## Host-side prerequisites

- Bridge host disponibile su `http://host.docker.internal:8787`
- Script presenti nel repo `aeb`:
  - `ops/supervisor/build_supervisor_payload.ps1`
  - `ops/supervisor/write_supervisor_report.ps1`
  - `ops/supervisor/write_supervisor_handoff.ps1`

## Current scope

MVP read-only:
- fetch payload
- call supervisor model
- write `docs/audits/CURRENT_SUPERVISOR_STATUS.md`
- send nightly email summary

No deploy, no runtime mutation, no Git promotion.
