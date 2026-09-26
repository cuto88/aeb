# AEB canonical backlog

Status: ACTIVE  
Owner chat: M60 — AEB Control Room  
Scope: Casa Mercurio / AEB  
Last reviewed: 2026-09-26

## Rules

- One backlog row per outcome/workstream, not per TODO, commit, audit note, branch, or PR.
- Create a dedicated chat only when the work has an autonomous deliverable and an executable next action.
- Historical priorities are not inherited automatically.
- `M30 Casa Mercurio Digital Twin` is CLOSED/ARCHIVED and must not be reopened; residual gaps are routed to dedicated workstreams.
- Runtime/repository evidence prevails over stale audit summaries.

Classification values: `CLOSED`, `COVERED`, `BACKLOG_ONLY`, `NEW_CHAT_REQUIRED`, `STALE`, `NEEDS_EVIDENCE`.

## Canonical backlog

| AEB_ID | WORKSTREAM | SOURCE | CURRENT_STATUS | CHAT_CODE | CLASSIFICATION | BLOCKER | NEXT_ACTION | PRIORITY |
|---|---|---|---|---|---|---|---|---|
| AEB-SEC-001 | Home Assistant secret hygiene | STEP111 + HA token inventory 2026-09-20 + runtime hygiene closeout 2026-09-22 | Legacy token revoked; repo/runtime contract verified read-only. Secret hygiene gate is active on tracked files; 4/4 required `!secret` keys verified in runtime; no current exposure confirmed and no rotation required. | M60 | CLOSED | — | Reopen only on authentication regression or new evidence of secret exposure. Review `secrets.yaml` mode `744` separately if hardening is prioritized. | CLOSED |
| AEB-STAT-001 | Current repo/runtime/docs checkpoint | audit reconciliation | Later runtime evidence supersedes the May checkpoint in several areas. | M60 | BACKLOG_ONLY | — | Refresh only when needed by an active decision. | P1 |
| AEB-DR-001 | Portability / disaster recovery MVP | P0 portability + restore audits, June 2026 | Portability blockers closed; restore drill PASS; scheduled backup PASS. | — | CLOSED | — | — | CLOSED |
| AEB-DR-002 | Backup retention / pruning | scheduled backup follow-up | Core backup works; retention/pruning is optional follow-up. | — | BACKLOG_ONLY | — | Define preview-first retention policy only when storage pressure/maintenance justifies it. | P3 |
| AEB-AC-001 | Whole-home AC comfort / humidity control | STEP123/124/125/130 + M64 runtime closeout | Automatic DRY for humidity-only demand and COOL priority for thermal/combined demand deployed and commissioned on 2026-09-24. Config checks, runtime hashes, rollback control and reversible test matrix passed; audit published through PR #487. Real-event E2E observation is non-blocking. | M64 | CLOSED | — | Reopen only on regression or evidence that automatic real-event promotion diverges from the verified policy. | CLOSED |
| AEB-TV-001 | TV-first AEB HMI | CHAT_PORTFOLIO / PR #468 | Functional baseline exists; polish remains. | M06 | COVERED | User/WIP priority | Complete v2.0.1 polish, TCL test, then close legacy PR path. | P2 |
| AEB-PR-001 | Legacy PR/branch hygiene | open PR/branch inventory | Many old branches/PRs are likely superseded. | M60 | BACKLOG_ONLY | Needs batch review | Close/archive only after evidence that each is superseded by main. | P2 |
| AEB-OPS-001 | GitHub Actions deploy pipeline to mercurio-edge | M60 follow-up after manual UI deploy 2026-09-26 | Manual deploy path is proven; reusable GitHub→runtime deployment is not yet implemented. Desired contract: manual workflow_dispatch, file allowlist, dedicated SSH secret with host-key pinning, pre-deploy backup, hash/API verification, no automatic restart, explicit rollback. | M60 | BACKLOG_ONLY | Security/runtime access design | Implement only when reducing repeated manual deploy friction justifies a dedicated execution workstream. | P2 |
| AEB-ENER-001 | Whole-house energy monitoring truth | M51 + ENERGY_STATE_RECONCILIATION | Monitoring baseline verified. | M51 | CLOSED | — | — | CLOSED |
| AEB-ENER-002 | SolarEdge local resilience | ENERGY roadmap / CHAT_PORTFOLIO | Local Modbus follow-up remains. | M52 | COVERED | Physical/UI verification | Verify SetApp Modbus TCP status/port/device ID without changing config. | P2 |
| AEB-ENER-003 | Billing reconciliation + load allocation | ENERGY_INTELLIGENCE_ROADMAP | Not yet executed as a complete accounting baseline. | — | NEW_CHAT_REQUIRED | Billing/contract period data | Reconcile one billing period, then map measured loads and residual. | P1 |
| AEB-ENER-004 | Normalized scorecard / avoided kWh and EUR | ENERGY_INTELLIGENCE_ROADMAP | Depends on trustworthy accounting baseline. | — | BACKLOG_ONLY | AEB-ENER-003 | Define normalized scorecard after reconciliation/load allocation. | P2 |
| AEB-SOLAR-001 | Decision-grade solar gain calibration | May runtime audit | Residual calibration item, not a current blocker. | — | BACKLOG_ONLY | Representative conditions/data | Revisit only if it materially improves control decisions. | P3 |
| AEB-DHW-001 | Autonomous ACS/EHW policy | autonomy strategy + closed safe writer | Safe writer exists; governed production policy is not yet closed. | — | NEW_CHAT_REQUIRED | Policy bounds + tariff/comfort inputs | Define inputs, limits, reason codes and shadow-mode gate before live actuation. | P1 |
| AEB-DISP-001 | Multi-load dispatch | autonomy strategy | Not yet justified before DHW/accounting closure. | — | BACKLOG_ONLY | AEB-DHW-001 + AEB-ENER-003 | Design dispatch contract only after dependencies are stable. | P2 |
| AEB-PLAN-001 | Governed predictive planner | autonomy strategy | Promotion beyond dry-run/shadow remains future work. | — | BACKLOG_ONLY | Dispatch contract | Define promotion gates after dispatch is closed. | P2 |
| AEB-WIN-001 | Real opening states | autonomy strategy / CHAT_PORTFOLIO | Existing workstream covers wired reed/tamper. | M10 | COVERED | Physical implementation | Continue via M10 only. | P2 |
| AEB-GAR-001 | Garage I/O / main door | autonomy gap / CHAT_PORTFOLIO | Existing workstream covers smart I/O pilot. | M54 | COVERED | Physical I/O matrix | Continue via M54 only. | P2 |
| AEB-CO2-001 | First-wave CO2 sensing | autonomy gap | Deferred sensor expansion. | — | BACKLOG_ONLY | WIP/ROI | Activate only when control decisions require it. | P3 |
| AEB-VMC-001 | VMC physical flow / efficiency baseline | open questions q004 / CHAT_PORTFOLIO | Physical remediation and baseline are already covered. | M16 | COVERED | Plenum sealing/insulation | Complete physical baseline in M16. | P2 |
| AEB-HEAT-001 | Radiant balancing | CHAT_PORTFOLIO | Waiting for heating season evidence. | M01 | COVERED | Heating season | Capture 48 h evidence in representative conditions. | P2 |
| AEB-HEAT-002 | Zone demand monitoring | CHAT_PORTFOLIO | Existing workstream covers thermostat-to-actuator truth. | M36 | COVERED | Physical wiring audit | Audit zone wiring and measure signals. | P2 |
| AEB-DATA-001 | Long-term data layer | CHAT_PORTFOLIO | Architecture/schema first; no runtime DB yet. | L29 | COVERED | WIP/ROI | Create architecture + schema only when prioritized. | P3 |
| AEB-DT-001 | Digital Twin v1 baseline | M30 / PR #467 | Spec v1 adopted and baseline merged. | M30 | CLOSED | — | Do not reopen M30. | CLOSED |
| AEB-DT-002 | Building/room geometry residuals q001-q003 | data/open_questions.yaml | Non-blocking residual model questions. | — | BACKLOG_ONLY | Evidence collection | Resolve opportunistically in relevant workstreams. | P3 |
| AEB-DT-003 | PDC curve/hydraulic schema q005 | data/open_questions.yaml | Still decision-relevant but not standalone execution yet. | — | BACKLOG_ONLY | Physical/runtime evidence | Fold into heating/PDC work when required. | P2 |
| AEB-DT-004 | ACS bounds / legionella q006 | data/open_questions.yaml | Dependency of autonomous DHW policy. | — | BACKLOG_ONLY | AEB-DHW-001 | Resolve inside AEB-DHW-001, not in M30. | P1 |
| AEB-DT-005 | Electricity tariff/contract q007 | data/open_questions.yaml | Dependency of energy accounting/optimization. | — | BACKLOG_ONLY | AEB-ENER-003 | Resolve inside AEB-ENER-003. | P1 |
| AEB-DT-006 | Sensor physical positions/calibration q008 | data/open_questions.yaml | Useful metadata, not current blocker. | — | BACKLOG_ONLY | Evidence collection | Resolve during sensor maintenance/installation. | P3 |
| AEB-DT-007 | Window geometry/solar q009 | data/open_questions.yaml | Useful for solar modelling, not current blocker. | — | BACKLOG_ONLY | Evidence collection | Resolve when solar calibration becomes active. | P3 |
| AEB-DT-008 | Room use profile q010 | data/open_questions.yaml | Useful contextual model, not current blocker. | — | BACKLOG_ONLY | Evidence collection | Resolve when predictive control needs it. | P3 |
| AEB-DT-009 | VMC serial / Toshiba nameplate evidence q011-q012 | data/open_questions.yaml / CHAT_PORTFOLIO | Existing evidence-store workstream can close these. | M49 | COVERED | Original evidence/images | Continue via M49. | P4 |
| AEB-DOM-001 | DomesticOps implementation | M09 handoff | Design brief closed; implementation intentionally deferred. | — | BACKLOG_ONLY | WIP/ROI | Start a new execution workstream only if reprioritized. | P4 |
| AEB-AI-001 | AI task scaffolding T2-T4 | AI/TASKS.md | Quality gates, entity map and supervisor handoff completed. | — | CLOSED | — | — | CLOSED |

## 2026-09-20 security closeout

The May STEP111 finding required rotation/revocation of the Home Assistant long-lived token associated with the AEB ops workspace.

Evidence collected on 2026-09-20:

- Home Assistant UI showed three active long-lived tokens: `Codex DS-XPS` (recent), `eab_ds-work`, and legacy `codex-aeb-runtime`.
- The legacy `codex-aeb-runtime` token was explicitly deleted/revoked by the user.
- The repository ignores `.env` and documents placeholder-only developer environment variables.
- Scheduled-backup tooling was already changed in June so WhatIf output must not echo token/secret values.
- No secret value was copied into this backlog or the repository.

Result: `AEB-SEC-001 = CLOSED`. Any later authentication failure is treated as an operational regression and does not reopen the historical exposure unless evidence shows a new security issue.


## 2026-09-22 runtime secret hygiene closeout

This follow-up was executed inside owner chat `M60 — AEB Control Room`; there is no separate physical M61 chat. The transient M61 label is retained only as a historical alias and must not be reused as a new chat code.

Evidence verified on 2026-09-22:

- Home Assistant API authentication passed against `/api/config` on runtime version `2026.4.4`.
- SSH access passed to `mercurio-edge` as `dscomparin`.
- Container `homeassistant` was running and the bind mount `/opt/data/homeassistant -> /config` matched the developer/runtime contract.
- `/config/secrets.yaml` existed and contained all four required keys: `ehw_modbus_host`, `ehw_modbus_port`, `ehw_modbus_slave`, and `mirai_modbus_host`.
- Secret hygiene gate passed with zero tracked findings; all AEB quality gates and `git diff --check` passed.
- PR #480 merged the repository changes to `main` at `bcf47da0144cceaf76cb8d82abe9d648efba3c85`.
- No deploy, restart, runtime permission change, or credential rotation was performed.

Residual review: `/config/secrets.yaml` was observed as `root:root` mode `744`. This is non-blocking for the closed AEB-SEC-001 outcome and should be handled only as a separate hardening review if prioritized.

Result: `AEB-SEC-001 = CLOSED`. The next P1 execution workstream remains `AEB-ENER-003 — Billing reconciliation + load allocation`.

## 2026-09-24 M64 AC DRY closeout

M64 introduced governed automatic DRY selection for humidity-only demand while preserving COOL priority for thermal or combined demand.

Closeout evidence:

- Implementation merged through PR #479 at `29b8f56df557340c4590d1fc4655d9e2af0b7024`.
- Surgical runtime deploy was limited to the three authorized package files; backup: `/config/backups/aeb_m64_dry_20260924_090205/`.
- Pre/post configuration checks, deployed hashes, rollback guard, structural matrix, and reversible DRY-to-COOL actuation passed.
- The deployment audit was published through PR #487 and merged at `16d72baad854f9b6b8cf2cfa4dcc68973058ac92`.
- `CHAT_PORTFOLIO` records M64 as `ARCHIVED` with the deployment audit as SSOT.
- Observation of the next real humidity-only event is useful operational follow-up but is non-blocking for archival.

Result: `AEB-AC-001 = CLOSED` and M64 is `ARCHIVIABILE`.


## 2026-09-26 M60 dashboard UI deploy closeout

The M60 micro-follow-up for AEB dashboard observability and compact climate navigation was deployed successfully to the Home Assistant runtime.

Evidence reported after deployment:

- Runtime target: `dscomparin@mercurio-edge`; container `homeassistant` running with bind `/opt/data/homeassistant -> /config`.
- Home Assistant API remained available with HTTP 200.
- Deployed files were limited to `/config/lovelace/01_eclss_casa.yaml` and `/config/lovelace/02_air_loop.yaml`.
- Runtime hashes matched the corresponding source blobs from remote `main` at `ee1bcfd7660f6217c016ef9412b49a3aa78fbe42`.
- Backup completed under `/config/backups/aeb_m60_ui_20260926_113902/`; backup hashes matched the pre-deploy runtime versions.
- YAML validation passed.
- `01_eclss_casa.yaml` contains the three-column climate navigation.
- `02_air_loop.yaml` contains requested AC mode/reason, Auto DRY, and branch electrical state observability.
- No Home Assistant restart or server-side reload was performed; UI refresh is sufficient for YAML dashboard changes.
- No packages, automations, secrets, or other runtime files were modified.

Result: the dashboard micro-task is CLOSED/ARCHIVABLE. A reusable GitHub Actions deployment path is tracked separately as `AEB-OPS-001` and does not block current AEB execution.
