# STEP67 - GitHub Actions Node 24 opt-in

Date: 2026-04-22
Scope: GitHub Actions workflow warning cleanup, no runtime deploy.

## FACT

- GitHub Actions reported a warning for Node.js 20-based actions:
  - `actions/checkout@v4`
  - `actions/setup-python@v5`
- GitHub will force JavaScript actions to Node.js 24 by default starting 2026-06-02.
- GitHub recommends opting in with `FORCE_JAVASCRIPT_ACTIONS_TO_NODE24=true`.

## IPOTESI

- Confidenza alta: this warning is not a quality gate failure.
- Confidenza alta: opting into Node 24 now is lower risk than waiting for the platform default switch.

## DECISIONE

- Add `FORCE_JAVASCRIPT_ACTIONS_TO_NODE24: 'true'` to the `quality-gates` job environment.
- Do not change the quality gate command.
- Do not change Home Assistant runtime.

## Verification

- Remote verification requires the next GitHub Actions run.
