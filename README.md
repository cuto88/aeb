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
