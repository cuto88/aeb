# STEP65 - Connector-first quality gates

Date: 2026-04-22
Scope: local/host quality gates, no HA runtime deploy.

## FACT

- `.git` was removed from `C:\2_OPS\aeb`.
- The workspace is now connector-first and GitHub is the source of truth.
- Several local gate scripts still assumed a local Git repository:
  - `ops/gates_run.ps1`
  - `ops/gate_lovelace_dashboards.ps1`
  - `ops/gate_artifact_policy.ps1`
  - `ops/gate_docs_links.ps1`
  - `ops/gate_docs_warn.ps1`
- This caused `ops/validate.ps1` to fail even when the actual runtime/package changes were valid.

## IPOTESI

- Confidenza alta: the mail notification about quality gate failure was caused by local no-git assumptions or the same class of gate fragility.
- Confidenza alta: making gates no-git compatible reduces operational noise and improves ROI.
- Confidenza media: CI running on GitHub still has Git available, so these fallbacks should not degrade CI behavior.

## DECISIONE

- Keep Git behavior when Git is available.
- Add script-relative fallback repo root resolution when Git is unavailable.
- Use scoped file discovery fallback for YAML/Lovelace/artifact/doc gates.
- Skip the mutating hygiene formatter when Git is unavailable.
- Write `.ops_state/gates.ok` with `HEAD=NO_LOCAL_GIT` and `BRANCH=connector-first` in no-git mode.

## Verification

- `ops/validate.ps1`: PASS.
- `ha core check`: not run in this step.
- No Home Assistant runtime files changed.

## Residual Notes

- `ops/deploy_safe.ps1`, `ops/repo_sync*.ps1`, `ops/push_dep.ps1`, and legacy/archive scripts still contain Git assumptions by design.
- They should not be used as the connector-first publication path.
- Runtime deploy remains explicit and separate.
