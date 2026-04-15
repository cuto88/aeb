# TASKS

| ID | Task | Stato | File target (allowlist) | Gate richiesti | Note |
| --- | --- | --- | --- | --- | --- |
| T1 | Governance repo-wide (RULES/CONTEXT/TASKS) | Done | `AI/` | N/A | Single source of truth repo-wide. |
| T2 | Quality gates (yamllint + check_config + include tree) | Done | `ops/`, `.github/` | yamllint, check_config, include tree | Gate CI/locali in modalita` strict; warning non piu` declassati. |
| T3 | Anti-regressione entity map (script o checklist) | Done | `ops/`, `docs/logic/core/` | entity map check | Entity map allineata, missing clima a zero e verifica automatica attiva nei gate. |
| T4 | Supervisor architecture e handoff contract | Done | `AI/`, `docs/audits/` | governance review | Definisce orchestratore `n8n`, supervisor read-only, handoff strutturato verso Codex e gate umano obbligatorio. |
| T5 | n8n MVP workflow e prompt supervisor | Done | `AI/`, `docs/audits/` | governance review | Definisce workflow MVP nodo per nodo, contratto payload, prompt supervisor e condizioni per draft handoff verso Codex. |
| T6 | Host bridge contract per supervisor AEB | Done | `AI/`, `ops/` | governance review | Formalizza endpoint bridge compatibili con `life-os-2100` per payload, scrittura report e handoff draft sul repo `aeb`. |
| T7 | Workflow export n8n supervisor MVP | Done | `n8n/`, `AI/`, `ops/` | import review | Export JSON importabile per workflow read-only `aeb`, con trigger manuale/schedulato, bridge payload, chiamata modello, scrittura report e notifica Telegram via env vars. |
