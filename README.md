# AEB
Repository Home Assistant per Casa Mercurio, rinominato `aeb`.
Struttura base: packages/, docs/logic/, lovelace/.
packages/ contiene automazioni e logica per domini HA.
docs/logic/ ospita solo documentazione (nessun YAML runtime, automazioni o script): entry point `docs/logic/README.md`.
lovelace/ conserva le dashboard YAML; docs/ e tools/ restano solo locali.
ops/ include gli script di manutenzione. `ops/validate.ps1` e` l'entrypoint dei controlli;
il deploy resta un'azione separata e bloccata finche` portability, drift e dry-run non sono chiusi.
Lo script di deploy corrente copia solo runtime HA: packages, lovelace, custom_components, themes e i YAML root ammessi. docs/ e tools/ restano locali; eventuali docs presenti su runtime sono residui storici da pulire con azione esplicita.

Fonti di verità rapide: `docs/logic/core/README_sensori_clima.md` (mappa entità), `docs/logic/core/regole_core_logiche.md` (regole core), `docs/logic/core/prompt_codex_master.md` (governance prompt), `docs/strategy/AEB_100_AUTONOMY_OBJECTIVE.md` (obiettivo strategico autonomia 100%).

Per dettagli tecnici e note climatizzazione leggi README_ClimaSystem.md.
Per la roadmap strategica di autonomia progressiva leggi `docs/strategy/AEB_100_AUTONOMY_OBJECTIVE.md`.

## Current AEB checkpoint (2026-05-22)
- Daily burn-in: closed and stable on the latest runtime evidence.
- Heating / AC / VMC: runtime real and already integrated in ClimateOps.
- DHW / EHW read-feedback chain: closed and runtime-validated.
- DHW / EHW writer path: formalized, gated, safe-by-default, dry-run validated and live validated for one reversible setpoint write on register `1104`.
- DHW UI / plancia: present in `lovelace/01_eclss_casa.yaml` as operator-facing observability/control block.
- Source/runtime naming drift: closed on source and runtime sides.
- VMC delta UR tuning: hysteresis helper plus thermal veto applied in source to reduce unnecessary `vel_2` persistence; runtime verify remains pending until reload.
- Broader orchestration still not enabled:
  - no planner-driven DHW actuation
  - no multi-load dispatch closure
  - no expanded DHW production policy rollout

## Audit baseline
Indice completo e organizzato:
- `docs/audits/README.md`

Entry point consigliati:
- baseline storica: `docs/audits/STEP0_AEB_PASSIVHAUS_MATURITY_2026-02-21.md`
- stato runtime sintetico corrente: `docs/audits/CURRENT_RUNTIME_STATUS_2026-05-23.md`
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

## Portability / Disaster Recovery

- Setup nuova macchina: `docs/ops/DEV_MACHINE_SETUP.md`
- Contratto env locale: `docs/security/dev-machine.env.example`
- Disaster Recovery: `docs/ops/DISASTER_RECOVERY.md`
- Restore runbook: `docs/ops/RESTORE_RUNBOOK.md`
- Backup policy: `docs/ops/BACKUP_POLICY.md`

Comandi principali:

```powershell
pwsh -NoProfile -File .\ops\check_portability.ps1
pwsh -NoProfile -File .\ops\backup_runtime_snapshot.ps1 -Source <HA_CONFIG_SOURCE> -DestinationRoot .\_dr_backups -DryRun
pwsh -NoProfile -File .\ops\verify_backup_freshness.ps1 -BackupRoot .\_dr_backups -MaxAgeHours 24
pwsh -NoProfile -File .\ops\validate.ps1
```

Il backup pre-deploy di `ops/deploy_safe.ps1` e` solo un rollback parziale. Nessun deploy
e` consentito se portability o validate falliscono.

## Accesso runtime HA
- Runtime corrente verificato il 2026-05-26: Home Assistant Core `2026.4.4` su `http://192.168.178.110:8123`, `config_dir=/config`.
- Il runtime attuale e` Docker/Core, non Home Assistant OS/Supervised: `/api/hassio/*` restituisce `404`.
- La Core API usa `HA_URL` e `HA_TOKEN` da `.env`; SSH non e` necessario per leggere stati, ma serve per deploy file se non esiste un bind mount accessibile.
- SSH vecchio storico: `root@192.168.178.84:2222`, config path `/homeassistant`. Questo endpoint non e` piu` quello operativo dopo cutoff.
- SSH nuovo operativo: `dscomparin@192.168.178.110:22`.
- Le chiavi HA e il file `known_hosts` sono asset locali fuori Git. Configurarli tramite
  `HA_SSH_KEY_PATH` e `HA_SSH_KNOWN_HOSTS`; non dipendere da path DS-01.
- Host remoto verificato: `mercurio-edge`.
- Container HA: `homeassistant`.
- Bind mount HA: `/opt/data/homeassistant` -> `/config`.
- L'utente operativo verificato e` `dscomparin`; ogni nuova workstation deve usare una
  credenziale autorizzata e verificata senza copiarla nel repository.
- Regola: per il runtime Docker, identificare il bind mount del container HA sul Linux host (`docker inspect <container>`) e deployare in `/config`, non `/homeassistant`.
- Nota drift runtime 2026-05-26: il runtime contiene ancora package monolitici `climate_heating.yaml` e `climate_ventilation.yaml`; il repo locale contiene anche file split `climate_*_templates.yaml`. Evitare deploy ampio finche` questo drift non e` riconciliato.

## Secrets contract
- Runtime env example: [docs/security/dev-machine.env.example](docs/security/dev-machine.env.example)
- Live `.env` resta locale e ignorato da Git; contiene solo valori runtime effettivi.
- I `!secret` richiesti dai package sono: `ehw_modbus_host`, `ehw_modbus_port`, `ehw_modbus_slave`, `mirai_modbus_host`.

## Notifiche Telegram
Canale tecnico HA Mercurio:
- naming target: `telegram_ha_mercurio`
- service runtime attuale: `notify.telegram_davide` (entity_id storico mantenuto dal registry HA)
- wrapper operativo: `script.telegram_ha_mercurio_send`

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

## Runtime checkpoint
- Current runtime checkpoint: docs/audits/CURRENT_RUNTIME_STATUS_2026-05-23.md
- VMC delta UR live verification: source contains hysteresis + thermal veto, and the runtime verify is closed after the live reload on 2026-05-23.
