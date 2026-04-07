# AEB
Repository Home Assistant per Casa Mercurio, rinominato `aeb`.
Struttura base: packages/, docs/logic/, lovelace/.
packages/ contiene automazioni e logica per domini HA.
docs/logic/ ospita solo documentazione (nessun YAML runtime, automazioni o script): entry point `docs/logic/README.md`.
lovelace/ conserva le dashboard YAML; docs/ e tools/ restano solo locali.
ops/ include gli script di manutenzione: usa ops/repo_sync_and_gates.ps1 per sincronizzare verso Z:\config (con validation), ops/deploy_safe.ps1 per il deploy sicuro e ops/validate.ps1 come entrypoint unico dei controlli; gli script di hygiene/check sono di supporto.
Lo script copia solo packages, docs/logic e lovelace in modalità mirror con esclusioni temporanee.

Fonti di verità rapide: `docs/logic/core/README_sensori_clima.md` (mappa entità), `docs/logic/core/regole_core_logiche.md` (regole core), `docs/logic/core/prompt_codex_master.md` (governance prompt).

Per dettagli tecnici e note climatizzazione leggi README_ClimaSystem.md.

## Current AEB checkpoint (2026-03-23)
- Heating / AC / VMC: runtime real and already integrated in ClimateOps.
- DHW / EHW read-feedback chain: closed and runtime-validated.
- DHW / EHW writer path: formalized, gated, safe-by-default, dry-run validated and live validated for one reversible setpoint write on register `1104`.
- DHW UI / plancia: present in `lovelace/climate_casa_unified_plancia.yaml` as operator-facing observability/control block.
- Broader orchestration still not enabled:
  - no planner-driven DHW actuation
  - no multi-load dispatch closure
  - no expanded DHW production policy rollout

## Audit baseline
- Step 0 AEB/Passivhaus maturity snapshot: `docs/audits/STEP0_AEB_PASSIVHAUS_MATURITY_2026-02-21.md`
- Step 1 runtime authority audit (Legacy vs ClimateOps): `docs/audits/STEP1_RUNTIME_AUTHORITY_2026-02-21.md`
- Step 2 runtime evidence closure: `docs/audits/STEP2_RUNTIME_EVIDENCE_2026-02-21.md`
- Step 2-bis runtime evidence update (writer per evento): `docs/audits/STEP2BIS_RUNTIME_EVIDENCE_UPDATE_2026-02-21.md`
- Runtime status current (post stabilization): `docs/audits/STATUS_RUNTIME_CURRENT_2026-02-23.md`
- Step 3 runtime evidence post-deploy: `docs/audits/STEP3_RUNTIME_EVIDENCE_POST_DEPLOY_2026-02-24.md`
- WIP tracker (audit stream): `docs/audits/WIP_RUNTIME_TRACKER_2026-02-24.md`
- Step 6 thermostat TEMP LDR threshold fix: `docs/audits/STEP6_THERMOSTAT_TEMP_LDR_THRESHOLD_2026-02-25.md`
- Step 7 AEB execution plan: `docs/audits/STEP7_AEB_EXECUTION_PLAN_2026-02-25.md`
- Step 7.1 forecast input contracts: `docs/audits/STEP7_1_FORECAST_INPUT_CONTRACTS_2026-02-25.md`
- Step 7.2 tariff/grid policy: `docs/audits/STEP7_2_TARIFF_GRID_POLICY_2026-02-25.md`
- Step 7.3 multi-load hierarchy: `docs/audits/STEP7_3_MULTI_LOAD_HIERARCHY_2026-02-25.md`
- Step 7.4 KPI closure: `docs/audits/STEP7_4_KPI_CLOSURE_2026-02-25.md`
- Step 7 post-PR runtime checklist: `docs/audits/STEP7_POST_PR_RUNTIME_CHECKLIST_2026-02-25.md`
- Step 7 post-deploy runtime verification: `docs/audits/STEP7_POST_DEPLOY_RUNTIME_2026-02-25.md`
- Step 8 tuning baseline: `docs/audits/STEP8_TUNING_BASELINE_2026-02-25.md`
- Step 8 runtime post strict gates: `docs/audits/STEP8_RUNTIME_POST_STRICT_GATES_2026-02-25.md`
- Step 8 hardening plan: `docs/audits/STEP8_HARDENING_PLAN_2026-02-25.md`
- Step 8 runtime audit 24h: `docs/audits/STEP8_RUNTIME_AUDIT_24H_2026-02-26.md`
- Step 8 runtime closure: `docs/audits/STEP8_RUNTIME_CLOSURE_2026-02-26.md`
- Step 8 gates policy: `docs/audits/STEP8_GATES_POLICY_2026-02-27.md`
- Step 9 project closure: `docs/audits/STEP9_PROJECT_CLOSURE_2026-02-27.md`
- Delta audit status: `docs/audits/DELTA_AUDIT_STATUS_2026-02-25.md`
- Step 32 EHW + MIRAI runtime audit: `docs/audits/STEP32_EHW_MIRAI_RUNTIME_AUDIT_2026-03-08.md`
- Step 33 general audit status: `docs/audits/STEP33_GENERAL_AUDIT_STATUS_2026-03-13.md`
- Step 34 runtime refresh audit: `docs/audits/STEP34_RUNTIME_REFRESH_AUDIT_2026-03-13.md`
- Step 35 ClimateOps SwitchBot timeout hardening: `docs/audits/STEP35_CLIMATEOPS_SWITCHBOT_TIMEOUT_HARDENING_2026-03-13.md`
- Step 36 SwitchBot timeout fix deploy verification: `docs/audits/STEP36_SWITCHBOT_TIMEOUT_FIX_DEPLOY_VERIFICATION_2026-03-13.md`
- Step 37 runtime refresh follow-up: `docs/audits/STEP37_RUNTIME_REFRESH_FOLLOWUP_2026-03-21.md`
- Step 38 DHW derived chain closure: `docs/audits/STEP38_DHW_DERIVED_CHAIN_CLOSURE_2026-03-22.md`
- Step 39 HA Core auth path closure: `docs/audits/STEP39_HA_CORE_AUTH_PATH_CLOSURE_2026-03-23.md`
- Step 40 DHW writer validation pass: `docs/audits/STEP40_DHW_WRITER_VALIDATION_PASS_2026-03-23.md`
- Step 41 DHW writer dry-run deploy pass: `docs/audits/STEP41_DHW_WRITER_DRYRUN_DEPLOY_PASS_2026-03-23.md`
- Step 42 DHW formalized live writer pass: `docs/audits/STEP42_DHW_FORMALIZED_LIVE_WRITER_PASS_2026-03-23.md`
- Step 43 AEB DHW writer consolidation checkpoint: `docs/audits/STEP43_AEB_DHW_WRITER_CONSOLIDATION_2026-03-23.md`
- Step 45 AEB MVP first live pass and measurement layer: `docs/audits/STEP45_AEB_MVP_FIRST_LIVE_PASS_AND_MEASUREMENT_LAYER_2026-03-31.md`
- Step 46 post-live MVP observation audit: `docs/audits/STEP46_POST_LIVE_MVP_OBSERVATION_AUDIT_2026-04-03.md`
- Step 47 post-deploy runtime audit: `docs/audits/STEP47_POST_DEPLOY_RUNTIME_AUDIT_2026-04-06.md`
- Step 48 solar gain advisory scaffold: `docs/audits/STEP48_SOLAR_GAIN_ADVISORY_SCAFFOLD_2026-04-06.md`
- Step 49 open items and closure sequence: `docs/audits/STEP49_OPEN_ITEMS_AND_CLOSURE_SEQUENCE_2026-04-07.md`
- Step 50 MIRAI runtime truth advisory: `docs/audits/STEP50_MIRAI_RUNTIME_TRUTH_ADVISORY_2026-04-07.md`
- Step 51 MIRAI manual run window plan: `docs/audits/STEP51_MIRAI_MANUAL_RUN_WINDOW_PLAN_2026-04-07.md`

## Quality gates (ops)
Per eseguire i controlli locali:
- `powershell -NoProfile -ExecutionPolicy Bypass -File ops\validate.ps1`
- `powershell -NoProfile -ExecutionPolicy Bypass -File ops\validate.ps1 -HaCheck` (include anche `ha core check`)
- `powershell -NoProfile -ExecutionPolicy Bypass -File ops\deploy_safe.ps1`
CI usa `ops/gates_run_ci.ps1` (read-only, senza hygiene mutante e senza `ha core check`).
Locale usa `ops/validate.ps1`, che esegue `ops/gates_run.ps1` e opzionalmente `ha core check` con `-HaCheck`.

Compatibilità comandi/alias esistenti:
- `ops/gates_run.ps1` resta disponibile.
- Alias PowerShell `gates`/`ha-gates` ora reindirizzati a `ops/validate.ps1`.

Per evitare falsi positivi e cartelle di backup/quarantena, il lint YAML gira solo sui file tracciati da Git.

## Accesso SSH runtime HA
- Endpoint: `root@192.168.178.84` porta `2222`
- Chiave primaria: `C:\Users\randalab\.ssh\ha_ed25519` (fallback `ha_fallback_ed25519`)
- Path config runtime: `/homeassistant`

## Notifiche Telegram
Canale tecnico HA Mercurio:
- naming target: `telegram_ha_mercurio`
- service runtime attuale: `notify.telegram_davide` (entity_id storico mantenuto dal registry HA)

Canale personale:
- naming target: `personale_davide`
- configurato su bot separato (puo` usare anche lo stesso `chat_id` del canale tecnico)
- service runtime attuale: `notify.personale_davide`

## Archivi opzionali
Il package opzionale `notify_google_speaker.yaml` è stato archiviato in
`_archive/legacy_optional/notify_google_speaker.yaml` perché non è richiesto a runtime.
I backup storici pesanti e le aree di quarantena non operative sono stati spostati fuori repo in
`C:\2_OPS\_repo_archives\aeb\` per ridurre rumore nel worktree e mantenere il repository focalizzato
sul runtime attivo e sulla documentazione tecnica.
