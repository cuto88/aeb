# TASKS

| ID | Task | Stato | File target (allowlist) | Gate richiesti | Note |
| --- | --- | --- | --- | --- | --- |
| T1 | Governance repo-wide (RULES/CONTEXT/TASKS) | Done | `AI/` | N/A | Single source of truth repo-wide. |
| T2 | Quality gates (yamllint + check_config + include tree) | Done | `ops/`, `.github/` | yamllint, check_config, include tree | Gate CI/locali in modalita` strict; warning non piu` declassati. |
| T3 | Anti-regressione entity map (script o checklist) | Done | `ops/`, `docs/logic/core/` | entity map check | Entity map allineata, missing clima a zero e verifica automatica attiva nei gate. |
