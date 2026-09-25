# M63 EHW shadow deploy audit — 2026-09-25

Status: `SHADOW_DEPLOY_FAIL_ROLLED_BACK`  
AEB ID: `AEB-DHW-001`

## Scope and provenance

- Execution lane: `ds-xps\ds` via SSH to `mercurio-edge / dscomparin`.
- Main working tree was preserved and not used for deployment.
- Isolated worktree source commit: `b6d43d8483f4a3aff0a77c45e83fe5862c98de80`.
- Package last-touch commit: `56a0f66d439116894e946a86f13685aa8c074d24`.
- Runtime scope: `packages/ehw_shadow_policy.yaml` only.
- Evidence pack: `/home/dscomparin/.local/state/ehw-shadow-deploy/M63-20260925T151636Z/`.

## Preflight

- Home Assistant container: running.
- Shadow package baseline: absent.
- API read-only preflight: HTTP 200, reachable and authenticated.
- Writer gates: write enable off, dry run on, commanded off, cutover off.
- Package SHA-256: `860f993e25d7614b4178b930b16627e3a620b330639967aa8a374744762b020c`.
- Static, mock HTTP, Secret Hygiene and repository Quality Gates: pass.

## Deployment outcome

The package was copied alone and the runtime hash matched the source hash.
The Home Assistant configuration check returned only
`Testing configuration at /config` and did not provide an explicit PASS within
the allowed window. Under the deployment contract this is a failed gate.

Rollback removed the package and verified the original absent-file baseline.
No restart was executed. The authorized shadow enable service call was not
executed because the config gate failed. No Modbus writes or setpoint changes
occurred.

## Final state

- Runtime package: absent.
- Restarts: `0`.
- Shadow service calls: `0`.
- Runtime Modbus writes: `0`.
- LIVE promotion: blocked.
