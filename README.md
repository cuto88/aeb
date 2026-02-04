# Casa Mercurio Codex 2025
Configurazione Home Assistant modulare per la casa Mercurio.
Struttura base: packages/, docs/logic/, lovelace/.
packages/ contiene automazioni e logica per domini HA.
docs/logic/ ospita solo documentazione (nessun YAML runtime, automazioni o script): entry point `docs/logic/README.md`.
lovelace/ conserva le dashboard YAML; docs/ e tools/ restano solo locali.
ops/ include gli script di manutenzione: usa ops/repo_sync_and_gates.ps1 per sincronizzare verso Z:\config (con gates), ops/deploy_safe.ps1 per il deploy sicuro e ops/gates_run.ps1 per i soli controlli; gli script di hygiene/check sono di supporto.
Lo script copia solo packages, docs/logic e lovelace in modalità mirror con esclusioni temporanee.

Fonti di verità rapide: `docs/logic/core/README_sensori_clima.md` (mappa entità), `docs/logic/core/regole_core_logiche.md` (regole core), `docs/logic/core/prompt_codex_master.md` (governance prompt).

Per dettagli tecnici e note climatizzazione leggi README_ClimaSystem.md.

## Quality gates (ops)
Per eseguire i controlli locali:
- `powershell -NoProfile -ExecutionPolicy Bypass -File ops\gates_run.ps1`
- `powershell -NoProfile -ExecutionPolicy Bypass -File ops\deploy_safe.ps1`
CI uses ops/gates_run_ci.ps1 (read-only). Local development uses ops/gates_run.ps1 (mutating).

Per evitare falsi positivi e cartelle di backup/quarantena, il lint YAML gira solo sui file tracciati da Git.

## Notifiche Telegram
Nel package `packages/notify_telegram.yaml` è definita la notifica `notify.telegram_davide`
per inviare messaggi alla chat principale senza hardcodare l'ID del bot nelle automazioni.

## Archivi opzionali
Il package opzionale `notify_google_speaker.yaml` è stato archiviato in
`_archive/legacy_optional/notify_google_speaker.yaml` perché non è richiesto a runtime.
