# P0 Portability and Disaster Recovery MVP

Date: 2026-06-20

## Scope

This change set is limited to developer-machine portability, disaster recovery documentation,
runtime backup tooling, restore guidance, and non-destructive verification. It does not modify
Home Assistant runtime files, `packages/`, `lovelace/`, climate logic, or deployment behavior.

## Pre-mortem operativo

| Failure mode | Cause probabili | Segnali precoci | Contromisure minime |
| --- | --- | --- | --- |
| DS-01 spento prima della migrazione | credenziali, working tree e procedure restano solo sulla macchina legacy | clone pulito diverso dal runtime, file locali non inventariati, nessun accesso SSH alternativo | mantenere DS-01 acceso finche` DS-WORK e DS-XPS non superano setup, validate e test accesso |
| Clone DS-WORK non validabile | dipendenze mancanti, gate non portabili, path assoluti | `ops/validate.ps1` fallisce subito o richiede cartelle esterne | documentare prerequisiti, eseguire portability check e correggere i gate senza indebolirli |
| Chiavi SSH disponibili solo su DS-01 | chiavi non trasferite in modo sicuro o ACL legate alla macchina | `Permission denied`, file chiave assente, known host non verificato | distribuire una chiave autorizzata per macchina e un file known_hosts verificato, entrambi fuori Git |
| Deploy da clone pulito sovrascrive runtime | drift repo/runtime, target implicito, fetch/merge dentro deploy | diff inattesi, working tree o HEAD cambiano durante deploy | vietare deploy finche` drift non e` riconciliato; aggiungere in seguito dry-run e target SSH esplicito |
| Backup runtime incompleto | `.storage` o secrets esclusi senza evidenza, source errata | manifest privo degli asset attesi, item count anomalo | manifest obbligatorio, flag espliciti, verifica freshness e restore drill |
| Restore non testato | runbook teorico, backup mai aperto su ambiente isolato | tempi e ordine di recovery sconosciuti | drill mensile su copia o runtime di test, con esito registrato |
| Path assoluti non portabili | fallback DS-01, profili personali, default `Z:\` | portability check segnala script attivi | spostare endpoint e credenziali nel contratto `.env`; mantenere i path storici solo nei documenti |
| Tailscale non verificato dai client | Tailscale presente solo su `mercurio-edge` o MagicDNS non disponibile | hostname tailnet non risolve, porte 22/8123 non raggiungibili | usare LAN finche` DS-WORK e DS-XPS non verificano API e SSH via tailnet |

## Audit iniziale

- Branch locale: `main`.
- HEAD locale osservato: `6279965`.
- Working tree preesistente: cinque file modificati, inclusi quattro file sotto `packages/`.
- I file runtime e di logica preesistenti non sono inclusi nello scope di questa modifica.
- Documenti DR, restore e backup policy gia` presenti: aggiornamento, non duplicazione.
- Script backup e freshness gia` presenti: hardening, non duplicazione.

## Risultati finali

### File creati

- `docs/ops/DEV_MACHINE_SETUP.md`
- `docs/security/dev-machine.env.example`
- `ops/check_portability.ps1`
- questo report

### File aggiornati

- `README.md`
- `docs/audits/HOME_ASSISTANT_PROJECT_AUDIT_2026-05-13.md`
- `docs/ops/DISASTER_RECOVERY.md`
- `docs/ops/RESTORE_RUNBOOK.md`
- `docs/ops/BACKUP_POLICY.md`
- `ops/backup_runtime_snapshot.ps1`
- `ops/verify_backup_freshness.ps1`

`.gitignore` non e` stato modificato: esclude gia` `.env`, `_dr_backups/`,
`_ha_runtime_backups/`, `secrets_bundle*`, `*.secret.*`, log, database e archivi DR.

### Gap chiusi

- contratto documentato per una developer machine non DS-01
- template `.env` senza valori reali
- distinzione esplicita tra GitHub, runtime, `.storage`, secrets, chiavi e offsite
- scenari restore per runtime rotto, host rotto, DS-01 perso, chiavi mancanti e rollback
- frequenze e retention minime formalizzate
- backup con source obbligatoria, dry-run, manifest e README restore
- copia backup non distruttiva: rimosso l'uso di `robocopy /MIR`
- freshness check con output e exit code machine-readable
- link non portabili del gate documentale convertiti in riferimenti testuali

### Path legacy trovati

Il portability check ha trovato 44 riferimenti bloccanti negli script OPS attivi. Le
famiglie principali sono:

- fallback chiavi e `known_hosts` sotto path personali o workspace legacy
- default `Z:\` in deploy e task backup
- ACL specifica `DS-01`
- path assoluti in audit runner, field runner e script di verifica post-deploy

I riferimenti nei documenti e audit storici sono classificati separatamente e non causano
da soli exit code `1`.

### Gap ancora aperti

- `ops/deploy_safe.ps1` non ha un dry-run reale e contiene target/path legacy
- vari runner OPS non usano ancora esclusivamente il contratto env
- `ops/dr_backup_task.ps1` contiene source e backup root non portabili
- manca un backup runtime reale recente sotto il root testato
- DS-WORK e DS-XPS non hanno ancora completato clone, validate, API e SSH
- Tailscale non e` ancora verificato dai due client
- drift tra working tree, GitHub e runtime deve essere riconciliato prima del deploy

### Validazione

- parsing PowerShell dei tre script: PASS
- dry-run backup su fixture locale: PASS, nessun file scritto
- `ops/check_portability.ps1`: FAIL atteso, 44 riferimenti in script attivi
- `ops/verify_backup_freshness.ps1 -BackupRoot .\_dr_backups -MaxAgeHours 24`:
  FAIL atteso, backup root assente
- `ops/validate.ps1`: PASS
- `git diff --check`: PASS

### Vincoli rispettati

- nessun accesso o modifica al runtime Home Assistant
- nessun deploy o riavvio
- nessuna cancellazione
- nessuna modifica a `packages/` o `lovelace/` da parte di questo task
- nessun commit

## P0.2 Pre-mortem portability OPS

Baseline: `ops/check_portability.ps1` rileva 44 riferimenti bloccanti in 12 script attivi.

### Script a rischio

- `deploy_safe.ps1` e `dr_backup_task.ps1`: default `Z:\`, chiavi e known hosts locali
- `ha_ssh.ps1`, audit runner e phase runner: fallback a path personali/workspace
- `ha_secure_key.ps1`: ACL esplicita legata al gruppo DS-01
- `ehw_field_test_runner.py` e `mirai_autowatch.py`: ACL e opzioni SSH hardcoded
- `profile.ps1`: repo root fisso

### Classificazione

- Storico/documentale: riferimenti sotto `docs/`, `README.md` e `AGENTS.md`; non devono
  bloccare il checker.
- Fallback operativo legacy: catene di chiavi sotto profilo utente, workspace e `.tmp`.
- Default pericoloso: `Z:\` come source o target implicito.
- Path macchina-specifico: `C:\2_OPS`, profilo utente nominativo e principal ACL DS-01.
- Falsi positivi: nessuno tra i 44 blocker iniziali; sono tutti in script OPS attivi.

### Rischio compatibilita` DS-01

Rimuovere i fallback puo` far fallire prima gli script su DS-01 se le variabili richieste
non sono caricate. Questo e` intenzionale: un errore esplicito e` piu` sicuro della selezione
silenziosa di una chiave, share o known-hosts non portabile.

### Contromisura minima

- mantenere parametri espliciti dove gia` esistono
- usare `HA_SSH_KEY_PATH`, `HA_SSH_KNOWN_HOSTS`, `HA_SSH_HOST_LAN` e parametri CLI
- derivare repo root da `$PSScriptRoot` o dal file Python corrente
- richiedere source/target espliciti al posto di `Z:\`
- non modificare il comportamento runtime oltre alla risoluzione della configurazione locale

### Esito P0.2

- blocker iniziali: 44 in 12 script OPS attivi
- blocker finali: 0
- riferimenti storici/documentali: 66, ignorati correttamente dal checker
- `ops/check_portability.ps1`: PASS
- i fallback impliciti sono stati sostituiti da parametri o variabili del contratto env
- il checker stampa per default solo blocker raggruppati e sintesi; `-Detailed` mostra i
  riferimenti storici
- parsing PowerShell degli script modificati: PASS
- compilazione sintattica dei due runner Python: PASS
- `ops/validate.ps1`: PASS

Script OPS modificati in P0.2:

- `aeb_runtime_audit_snapshot.ps1`
- `deploy_safe.ps1`
- `dr_backup_task.ps1`
- `ehw_field_test_runner.py`
- `ha_secure_key.ps1`
- `ha_ssh.ps1`
- `involucro_audit_snapshot.ps1`
- `mirai_autowatch.py`
- `phase1_runtime_truth_check.ps1`
- `phase2_postdeploy_verify.ps1`
- `phase4_daily_runtime_report.ps1`
- `profile.ps1`
- `check_portability.ps1`
