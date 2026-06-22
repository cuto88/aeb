# P1 Scheduled Backup Pass

Date: 2026-06-22

## Contesto

P1 e` stato implementato e validato: AEB / Home Assistant dispone ora di un backup
remoto runtime automatico giornaliero eseguito da DS-WORK, senza deploy e senza
modifiche al runtime Home Assistant.

## Provenance

| Campo | Valore |
| --- | --- |
| Operator machine | `DS-WORK` |
| Runtime target | `mercurio-edge` |
| Legacy machine status | `DS-01 powered off` |
| Access mode | `Windows Task Scheduler + local filesystem + Tailscale + SSH` |
| Deploy | `none` |
| Runtime changes | `none` |
| GitHub Actions | `PASS` on `a73c1dd` |

## Task schedulato

| Campo | Valore |
| --- | --- |
| Task name | `CasaMercurio-DR-PeriodicBackup` |
| Stato | `Ready` |
| Duplicati | `none` |
| Orario | `13:15` |
| NextRunTime after first run | `23/06/2026 13:15:00` |

Il task esegue il backup remoto runtime Home Assistant e la verifica freshness nello
stesso passaggio.

## Primo run automatico

| Campo | Valore |
| --- | --- |
| LastRunTime | `22/06/2026 13:15:00` |
| LastTaskResult | `0` |
| Snapshot generated | `ha_runtime_snapshot_20260622_131501` |

## Backup freshness post-run

```
BACKUP_VERIFY_OK latest=ha_runtime_snapshot_20260622_131501 age_hours=1.38 items=2599 root=C:\2_OPS\_repo_archives\aeb\_dr_backups
```

## Verdetto operativo

PASS.

AEB dispone ora di un backup remoto runtime Home Assistant automatico giornaliero da
DS-WORK alle 13:15.

## Rischi residui

- DS-WORK deve essere acceso alle 13:15.
- Retention e pruning non sono ancora automatici.
- Il backup ordinario esclude intenzionalmente `.storage` e `secrets.yaml`.
- Il restore drill e` gia` stato validato su uno snapshot precedente e non va ripetuto a
  ogni run.
- Il monitoraggio notifiche / alert non e` ancora implementato.

## Prossimi step consigliati

1. Mantenere DS-WORK acceso alla finestra schedulata o introdurre un controllo di
   disponibilita` dedicato.
2. Definire retention/pruning come step separato, con preview prima dell`attivazione.
3. Aggiungere monitoraggio notifiche/alert per il task schedulato.
4. Conservare questo audit come chiusura formale del P1 backup schedulato.
