# Backup Policy AEB

## Cosa va salvato

- Repo AEB: GitHub e commit regolari.
- Runtime HA: snapshot del path `/config` con manifest.
- `.storage/`: snapshot separato o incluso nello snapshot DR.
- Secrets fuori Git: `secrets.yaml` e chiavi operative, ma sempre fuori dal repository.
- Offsite: copia cifrata o su storage separato per il restore worst-case.
- Recorder history: il DB `home-assistant_v2.db*` resta fuori dal snapshot DR quotidiano per tenere il job sostenibile; conserva export separati solo se servono davvero.

Default operativo consigliato per il job DR:

- root backup esterno al repo, configurato per macchina e non hardcoded
- task schedulato: `ops/dr_backup_task.ps1`

## Frequenze minime

- Repo: continuo tramite commit e push Git dopo ogni change approvato.
- Runtime HA: giornaliero e prima di ogni deploy autorizzato.
- `.storage/`: incluso nel backup runtime giornaliero.
- Secrets bundle: manuale dopo ogni modifica a secret, token o chiavi.
- Offsite: giornaliero o subito dopo una modifica critica.
- Restore drill: mensile.
- Recorder DB: solo backup dedicato separato, non nel giro quotidiano DR.

## Retention minima

- ultimi 7 snapshot runtime giornalieri
- ultimi 4 snapshot settimanali
- ultimi 3 snapshot mensili
- almeno 1 copia offsite cifrata dell'ultimo snapshot valido
- almeno 1 secrets bundle corrente e 1 precedente, entrambi protetti
- ultimo backup parziale da deploy per rollback rapido

## Restore drill mensile

- verificare che `ops/backup_runtime_snapshot.ps1` generi un backup completo
- verificare che `ops/verify_backup_freshness.ps1` trovi un backup recente
- simulare il ripristino su una copia di test o su un runtime fermo
- registrare esito e gap nel repo

## Cosa non copre il deploy safe

`ops/deploy_safe.ps1` e` utile come backup parziale pre-deploy, ma non sostituisce:

- snapshot runtime completo
- backup `.storage`
- backup credenziali fuori Git
- restore drill reale
