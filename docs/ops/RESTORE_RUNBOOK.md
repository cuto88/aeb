# Restore Runbook AEB

## Principio

Restore prima il controllo, poi la configurazione, poi lo stato runtime. GitHub da` il codice; il backup DR da` il resto.

## Ordine di restore

1. Ripristinare accesso all`host HA.
2. Ripristinare credenziali/chiavi operative se mancanti.
3. Ripristinare la config runtime (`configuration.yaml`, `packages/`, `lovelace/`, `custom_components/`, `themes/`, `www/`, `tts/`).
4. Ripristinare `.storage/` se il problema riguarda UI, integrazioni o auth.
5. Ripristinare `home-assistant_v2.db` se serve continuita` storica.
6. Validare con `ops/verify_backup_freshness.ps1` e `ops/validate.ps1`.

## Scenario: repo ok, runtime rotto

- prendere l`ultimo snapshot DR valido da `_dr_backups/` oppure da un percorso offsite
- copiare i file verso il bind mount runtime
- mantenere fuori Git tutto cio` che e` locale al runtime

Comandi base:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ops\backup_runtime_snapshot.ps1 -Source Z:\ -DestinationRoot .\_dr_backups -IncludeStorage -IncludeSecrets
powershell -NoProfile -ExecutionPolicy Bypass -File ops\verify_backup_freshness.ps1 -BackupRoot .\_dr_backups -MaxAgeHours 24
```

## Scenario: host HA rotto

- ricostruire prima l`host o il container Docker
- rimontare il path che ospita `/config`
- copiare lo snapshot DR nel bind mount corretto
- non assumere che il backup parziale di `deploy_safe.ps1` basti per la recovery completa

Esempio operativo:

```powershell
ssh dscomparin@192.168.178.110 "docker ps"
ssh dscomparin@192.168.178.110 "docker inspect homeassistant --format '{{json .Mounts}}'"
```

Poi ripristinare sul path effettivo della bind mount.

## Scenario: secrets o chiavi mancanti

- recuperare `secrets.yaml` da un backup fuori Git
- ricreare la chiave SSH operativa in un file con ACL pulita
- aggiornare `HA_SSH_KEY_PATH`
- verificare che nessun secret sia stato committato

Non mettere mai i secret nel repo per "far tornare tutto".

## Scenario: rollback post-deploy

- usare il backup creato da `ops/deploy_safe.ps1` come rollback corto
- se il rollback coinvolge `.storage`, passare al backup DR completo
- dopo il restore, eseguire `ops/validate.ps1`

## Checklist finale

- `http://<ha>:8123/api/config` risponde
- `configuration.yaml` presente nel runtime
- `packages/` e `lovelace/` presenti
- `.storage/` coerente con le integrazioni attese
- `ops/verify_backup_freshness.ps1` ritorna OK
- `ops/validate.ps1` ritorna OK
- almeno un accesso UI admin disponibile

