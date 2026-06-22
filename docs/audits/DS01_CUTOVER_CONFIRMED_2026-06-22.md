# DS-01 Cutover Confirmed

Date: 2026-06-22

## Operational provenance

| Campo | Valore |
| --- | --- |
| Operator machine | `DS-WORK` |
| Runtime target | `mercurio-edge` |
| Legacy machine status | `DS-01 powered off` |
| Access mode | `Tailscale + SSH + HA API + GitHub Actions` |
| Deploy eseguito | `no` |
| Runtime changes eseguite | `no` |
| Commit / GitHub Actions rilevanti | commit `fb649b8`; GitHub Actions `docs: record DS-WORK DR pass audit`, `ops: harden remote DR backup exclusions`, `ci: remove missing vmc helper gate` |

## Contesto

DS-01 e` stata spenta. Il progetto AEB / Home Assistant e` stato verificato da DS-WORK
con esito positivo sui controlli operativi necessari per continuare a lavorare senza il
nodo legacy come dipendenza critica.

Questo documento registra il test reale di cutover e non modifica runtime, deploy o
configurazioni operative.

## Verifiche

| Verifica | Esito | Output essenziale |
| --- | --- | --- |
| Repo locale pulita | PASS | `git status --short` senza output |
| GitHub Actions `docs: record DS-WORK DR pass audit` | PASS | workflow completato con successo |
| GitHub Actions `ops: harden remote DR backup exclusions` | PASS | workflow completato con successo |
| GitHub Actions `ci: remove missing vmc helper gate` | PASS | workflow completato con successo |
| HA API via Tailscale | PASS | `API running.` |
| SSH via Tailscale + container | PASS | `dscomparin`, `mercurio-edge`, `homeassistant` |
| Backup freshness | PASS | `BACKUP_VERIFY_OK latest=ha_runtime_snapshot_20260622_121348 age_hours=0.28 items=2599 root=C:\2_OPS\_repo_archives\aeb\_dr_backups` |

## Output essenziali

### HA API via Tailscale

Comando eseguito:

```powershell
Invoke-RestMethod -Uri "$env:HA_URL/api/" -Headers $headers
```

Output:

```text
API running.
```

### SSH via Tailscale + container

Comando eseguito:

```powershell
pwsh -NoProfile -File .\ops\ha_ssh.ps1 -HaHost $env:HA_SSH_HOST_TAILSCALE -RemoteCommand "whoami; hostname; docker ps --filter name=homeassistant --format '{{.Names}}'"
```

Output:

```text
dscomparin
mercurio-edge
homeassistant
```

### Backup freshness

Comando eseguito:

```powershell
pwsh -NoProfile -File .\ops\verify_backup_freshness.ps1 -BackupRoot "C:\2_OPS\_repo_archives\aeb\_dr_backups" -MaxAgeHours 24
```

Output:

```text
BACKUP_VERIFY_OK latest=ha_runtime_snapshot_20260622_121348 age_hours=0.28 items=2599 root=C:\2_OPS\_repo_archives\aeb\_dr_backups
```

## Verdetto operativo

DS-01 non e` piu` nodo operativo critico per AEB.

DS-01 puo` restare spenta.

La dismissione definitiva dell`hardware non viene dichiarata qui come chiusura fisica
assoluta. Resta subordinata a un eventuale recupero o archiviazione di dati generici
non-AEB, se presenti.

## Cosa resta aperto

- nessun blocco operativo residuo su AEB / Home Assistant legato a DS-01
- eventuale valutazione separata per dati generici non-AEB eventualmente presenti su DS-01
- mantenere disponibile il restore drill minimo gia` consigliato in sede DR

## Prossimi step consigliati

1. Conservare questo audit come riferimento del cutover confermato.
2. Mantenere DS-01 spenta salvo necessita` di recupero dati non-AEB.
3. Continuare a usare DS-WORK come macchina operativa primaria per AEB.
4. Eseguire il restore drill minimo solo se serve una conferma ulteriore della catena DR.
