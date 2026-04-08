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
Indice completo e organizzato:
- `docs/audits/README.md`

Entry point consigliati:
- baseline storica: `docs/audits/STEP0_AEB_PASSIVHAUS_MATURITY_2026-02-21.md`
- stato runtime sintetico corrente: `docs/audits/CURRENT_RUNTIME_STATUS_2026-04-08.md`
- quadro operativo recente: `docs/audits/STEP49_OPEN_ITEMS_AND_CLOSURE_SEQUENCE_2026-04-07.md`
- ultimo audit runtime esteso: `docs/audits/STEP47_POST_DEPLOY_RUNTIME_AUDIT_2026-04-06.md`

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
