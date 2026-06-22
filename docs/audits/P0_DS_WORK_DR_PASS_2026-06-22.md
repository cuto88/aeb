# P0 DS-WORK + Disaster Recovery Pass

Date: 2026-06-22

## Verdetto operativo

Il progetto AEB e` ora operativo da DS-WORK.

DS-01 non e` piu` critica per operare su AEB. Puo` essere spenta per un test controllato.
Resta consigliato un restore drill minimo. La replica su DS-XPS resta opzionale.
La conferma finale va data dopo il test con DS-01 spenta.

## Stato validato

| Area | Esito | Evidenza sintetica |
| --- | --- | --- |
| DS-WORK clone/gates | PASS | clone operativo e quality gates superati |
| GitHub Actions / Quality Gates | PASS | pipeline e gate di qualita` validati |
| HA API via Tailscale | PASS | accesso API verificato |
| HA SSH via Tailscale | PASS | accesso SSH verificato |
| Container `homeassistant` via SSH | PASS | container visibile da host remoto |
| Backup locale repo/config | PASS | snapshot locale creato e validato |
| Backup runtime remoto Home Assistant | PASS | snapshot remoto creato e validato |
| Freshness backup remoto | PASS | verifica freshness positiva |
| Deploy verso Home Assistant | NON ESEGUITO | nessun deploy durante la verifica |
| Modifiche runtime HA | NON ESEGUITE | nessuna modifica runtime durante la verifica |

## Commit rilevanti

- `b67dbfe` - `ops: add portability and disaster recovery MVP`
- `84524f6` - `chore: fix gitattributes comment syntax`
- `9a18ad8` - `ci: remove missing vmc helper gate`
- `3f86c8f` - `ops: harden remote DR backup exclusions`

## Backup validati

- Backup locale repo/config: `C:\2_OPS\aeb\_dr_backups\ha_runtime_snapshot_20260622_110941`
- Backup remoto runtime HA root: `C:\2_OPS\_repo_archives\aeb\_dr_backups`
- Snapshot remoto validato: `ha_runtime_snapshot_20260622_121348`
- Freshness output validato: `BACKUP_VERIFY_OK latest=ha_runtime_snapshot_20260622_121348 age_hours=0.01 items=2599 root=C:\2_OPS\_repo_archives\aeb\_dr_backups`

## Esclusioni backup runtime remoto

La snapshot remota ordinaria esclude:

- `backup`
- `backups`
- `_codex_backups`
- `_ha_runtime_backups`
- `_dr_backups`
- `home-assistant_v2.db`
- `home-assistant_v2.db-*`
- `home-assistant_v2.db.corrupt.*`
- `.git`
- `.git-local`
- `.cache`
- `.tmp`
- `media`
- `tts`
- `www`

In aggiunta:

- `.storage` e` esclusa se `CopiedStorage` e` false
- `secrets.yaml` e` escluso se `CopiedSecrets` e` false

## Stato DS-01

DS-01 puo` essere spenta per un test controllato.
Non va dichiarata dismessa definitivamente.
La validazione conclusiva resta legata a un test minimo con DS-01 spenta.

## Rischi residui

- il restore drill minimo non e` ancora stato eseguito su DS-01 spenta
- la replica su DS-XPS resta opzionale e non ancora usata come conferma finale
- la disponibilita` operativa dipende ancora da Tailscale, chiavi SSH e known_hosts corretti
- un backup valido non sostituisce un test di restore completo

## Prossimo test consigliato

Eseguire il controllo minimo con DS-01 spenta:

1. confermare che l`accesso SSH/Tailscale da DS-WORK continua a funzionare
2. confermare che il container `homeassistant` e` raggiungibile via SSH
3. verificare che la freshness del backup remoto resti entro soglia
4. registrare l`esito come conferma finale del cutover operativo

## Comandi minimi

Verifica freshness backup:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File ops/verify_backup_freshness.ps1 -BackupRoot "C:\2_OPS\_repo_archives\aeb\_dr_backups" -MaxAgeHours 24
```

Verifica SSH/container:

```powershell
ssh -T -o UserKnownHostsFile="$env:HA_SSH_KNOWN_HOSTS" -i "$env:HA_SSH_KEY_PATH" dscomparin@mercurio-edge.taild4ceba.ts.net "docker exec homeassistant sh -lc 'hostname && whoami'"
```

## Note operative

- nessun deploy e` stato eseguito durante questa verifica
- nessuna modifica runtime Home Assistant e` stata eseguita
- questa nota chiude formalmente il blocco P0 DS-WORK + Disaster Recovery sul piano documentale, non il test di spegnimento DS-01
