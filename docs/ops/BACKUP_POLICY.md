# Backup Policy AEB

## Cosa va salvato

- Repo AEB: GitHub e commit regolari.
- Runtime HA: snapshot del path `/config` con manifest.
- `.storage/`: snapshot separato o incluso nello snapshot DR.
- Secrets fuori Git: `secrets.yaml` e chiavi operative, ma sempre fuori dal repository.
- Offsite: copia cifrata o su storage separato per il restore worst-case.
- Recorder history: il DB `home-assistant_v2.db*` resta fuori dal snapshot DR quotidiano per tenere il job sostenibile; conserva export separati solo se servono davvero.

Default operativo consigliato per il job DR:

- root backup esterno al repo: `C:\2_OPS\_repo_archives\aeb\_dr_backups`
- task schedulato: `ops/dr_backup_task.ps1`

## Frequenze consigliate

- Repo: ad ogni change approvato e pushato.
- Runtime HA: prima di ogni deploy e almeno una volta al giorno.
- `.storage/`: prima di re-auth integration, update cloud o modifiche auth, e almeno giornalmente se il runtime cambia spesso.
- Secrets: ogni volta che cambia una chiave o una credenziale, con copia fuori Git.
- Offsite: almeno una volta al giorno o dopo un deploy ad alto rischio.
- Recorder DB: solo backup dedicato separato, non nel giro quotidiano DR.

## Retention minima

- ultimi 7 snapshot runtime giornalieri
- ultimi 4 snapshot settimanali
- ultimi 3 snapshot mensili
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
