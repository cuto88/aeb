# Disaster Recovery AEB

## Obiettivo

Proteggere la parte piu` costosa del lavoro AEB: runtime Home Assistant, configurazione, `.storage`, credenziali operative fuori Git e percorso di restore. GitHub protegge il codice e la documentazione; non protegge da solo il runtime vivo.

## Cosa protegge GitHub

- `packages/`
- `lovelace/`
- `docs/`
- `ops/`
- script, policy, runbook e gate
- storico revisioni e diff verificabili

## Cosa GitHub non protegge

- `.storage/`
- `home-assistant_v2.db`
- `secrets.yaml`
- chiavi SSH e bundle credenziali locali
- stato reale delle integrazioni cloud
- cache, log e dati runtime non versionati
- falsa convinzione che il repo coincida con il runtime attivo

## RPO e RTO minimi

- RPO repo: 0 se il commit e il push sono stati eseguiti.
- RPO runtime: massimo 24 ore per snapshot completo, meno se c`e` stato un deploy o una modifica auth.
- RTO repo ok / runtime rotto: 30-60 minuti.
- RTO host HA rotto: 1-4 ore, dipende dal ripristino dell`host e della bind mount.

## Asset critici

- `configuration.yaml`
- `packages/`
- `lovelace/`
- `custom_components/`
- `.storage/`
- `home-assistant_v2.db`
- `secrets.yaml` locale fuori Git
- chiave SSH operativa per il target HA
- backup partial rollback prodotto da `ops/deploy_safe.ps1`

## Pre-mortem operativo

| Failure mode | Cause probabile | Segnale precoce | Contromisura minima |
| --- | --- | --- | --- |
| Host HA guasto | crash host, disco pieno, rete fuori uso, container non parte | API HA non risponde, SSH non entra, container down | restore host, poi restore bind mount e verifica servizio |
| Configurazione runtime corrotta | deploy incompleto, merge sbagliato, file YAML invalido | `ha core check` fallisce, entita` sparite, log con errori YAML | ripristina ultimo snapshot valido e rilancia check |
| `.storage` persa o incoerente | reboot/crash, restore parziale, auth/integration drift | dashboard vuote, entita` mancanti, re-auth richiesto | restore `.storage` da snapshot recente, poi verifica integrazioni |
| Credenziali/chiavi locali non recuperabili | ACL Windows, file spostati, secret non documentati | `Permission denied`, chiavi non leggibili, re-auth impossibile | conserva copia fuori Git con ACL pulite e verifica accesso periodico |
| Backup non ripristinabile | backup incompleto, nessun manifest, path sbagliato | restore fallisce o manca un file critico | `verify_backup_freshness.ps1`, manifest e drill mensile |
| Restore non documentato | fix ad hoc, operazioni manuali non scritte | nessuno sa ricostruire ordine e priorita` | runbook unico con ordine di restore e checklist finale |
| Falsa sicurezza da GitHub | runtime vive solo in Git, `.storage` ignorata, credenziali fuori repo | commit pulito ma HA non parte | backup runtime separato e restore test regolare |

## Procedura P0 / P1 / P2

### P0

- congelare nuove modifiche
- verificare ultimo backup runtime con `ops/verify_backup_freshness.ps1`
- se il runtime e` rotto, ripristinare l`ultimo snapshot valido
- eseguire `ops/validate.ps1`
- solo dopo, riaprire nuove modifiche

### P1

- prima di ogni deploy o modifica auth, fare snapshot runtime
- usare il backup parziale di `ops/deploy_safe.ps1` solo come rollback di breve raggio
- non considerarlo un sostituto del DR completo

### P2

- eseguire restore drill mensile
- verificare che backup, manifest e runbook siano utilizzabili senza eccezioni manuali
- controllare che `.storage` e credenziali siano ancora recuperabili

