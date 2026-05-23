# Current Supervisor Status

- Generated at: 2026-05-15T11:48:38.331Z
- Trigger source: unknown
- Model: gpt-5.2
- Report path: docs/audits/CURRENT_SUPERVISOR_STATUS.md

## FACT
- Repository `aeb` on branch `main` is **dirty** with many modified files, multiple deleted `lovelace/*.yaml` files, and multiple untracked items including `.tmp_ssh*/`, `docs/security/`, new `lovelace/0*_*.yaml` dashboards, and new ops scripts (e.g., `ops/ha_secure_key.ps1`, `ops/ha_ssh.ps1`, `ops/phase5_burn_in.ps1`).
- Latest commits (2026-05-13) are documentation-only, authored by `dscomparin`, related to AEB chat triage and runtime evidence gating.
- Audit doc `STEP109_RUNTIME_BURN_IN_FREEZE_PLAN_2026-05-14.md` states an intent to freeze HA perimeter after stabilization, run burn-in via `n8n`, with checkpoints at 24h (2026-05-15) and 7d (2026-05-21), and explicitly calls for no refactors, no entity/bridge renames, and no logic changes unless regression-evidenced.
- Runtime evidence exists for 2026-05-15: `phase4_daily_summary_20260515_073004.md` reports **Decision: GO** with checks PASS (HA core check, current boot Phase1 errors, Phase1 writer service scan) and raw values indicating no Phase1 errors and no writer services found in Phase1 files.
- Runtime audit snapshots for 2026-05-14 and 2026-05-15 show policy booleans/sensors (e.g., vacation mode off; allow AC/VMC boost/shift load on) in expected on/off states as captured.
- The AEB supervisor bridge transport issue is now resolved:
  - `n8n-bridge` binds to `0.0.0.0:8787`
  - `lifeos_n8n` reaches it through `http://host.docker.internal:8787`
  - `GET /aeb/supervisor/payload?max_audits=3` returns `200`
  - the supervisor report write path completed successfully

## RISKS
- Large uncommitted surface area across `configuration.yaml`, many `packages/*.yaml`, and dashboard files increases risk of unintended config/runtime divergence and complicates traceability/rollback.
- Presence of untracked `.tmp_ssh*/` directories and untracked `docs/security/` plus new ops scripts named like `ha_secure_key.ps1`/`ha_ssh.ps1` raises a concrete risk of sensitive material or secret-handling artifacts being present in the working tree (even if not shown in payload).
- Deleted legacy `lovelace/*.yaml` files combined with new untracked `lovelace/0*_*.yaml` dashboards suggests dashboard cutover is in-flight; risk of broken `configuration.yaml` dashboard references or incomplete promotion/visibility governance if not fully reconciled.
- Trigger source is unknown, and current evidence does not confirm that the working tree matches the burn-in freeze constraints stated in STEP109.

## DRIFT
- Confirmed repo/process drift: working tree is dirty with extensive modifications and untracked artifacts, while burn-in plan calls for a freeze/no-refactor posture.
- Potential repo/runtime drift: runtime evidence indicates current runtime checks are passing, but it is not evidenced that runtime is aligned to the current uncommitted repository state.

## PRIORITY
HIGH

## NEXT ACTION
Have a human perform a focused review to determine whether any untracked items (especially `.tmp_ssh*/`, `docs/security/`, and `ops/ha_secure_key.ps1`/`ops/ha_ssh.ps1`) contain sensitive data or violate the burn-in freeze scope, before any further commit or promotion decisions.
- The bridge transport block is no longer part of that review.

## RECOMMENDED OWNER
Human

## GO / NO-GO
NO-GO
