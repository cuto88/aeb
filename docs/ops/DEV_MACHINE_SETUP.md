# Developer Machine Setup

Questa procedura prepara DS-WORK, DS-XPS o un'altra workstation Windows per clonare,
validare e ispezionare AEB senza dipendenze da DS-01.

## Prerequisiti

Installare e rendere disponibili nel `PATH`:

- Git
- PowerShell 7 (`pwsh`)
- Python 3
- `yamllint`
- OpenSSH client (`ssh`)
- `tar`

Verifica minima:

```powershell
git --version
pwsh --version
python --version
yamllint --version
ssh -V
tar --version
```

## Clone

```powershell
git clone https://github.com/cuto88/aeb.git
Set-Location .\aeb
git status --short
```

Il clone deve partire da un branch pulito. Non copiare `.git`, `.tmp`, `.ops_state`,
database, log o chiavi da DS-01.

## Configurazione locale

1. Copiare `docs/security/dev-machine.env.example` in `.env`.
2. Compilare i valori localmente.
3. Non committare `.env`, token, chiavi, `known_hosts` o bundle di secret.
4. Conservare la chiave SSH e il file `known_hosts` fuori dal repository.

Variabili richieste:

- `HA_URL`
- `HA_TOKEN`
- `HA_SSH_KEY_PATH`
- `HA_SSH_KNOWN_HOSTS`
- `HA_SSH_HOST_LAN`
- `HA_SSH_HOST_TAILSCALE`
- `HA_REMOTE_CONTAINER`
- `HA_REMOTE_PATH`

Tailscale e` un endpoint opzionale finche` API e SSH non sono verificati dalla macchina
client. L'endpoint LAN resta il fallback operativo.

Caricare le variabili nella sessione corrente senza stamparle:

```powershell
Get-Content .env | ForEach-Object {
  if ($_ -match '^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)\s*$') {
    $value = $matches[2].Trim().Trim('"').Trim("'")
    [Environment]::SetEnvironmentVariable($matches[1], $value, 'Process')
  }
}
```

## Test Home Assistant API

Caricare `.env` senza stampare i valori e interrogare solo `/api/config`:

```powershell
$headers = @{ Authorization = "Bearer $env:HA_TOKEN" }
Invoke-RestMethod -Uri "$($env:HA_URL.TrimEnd('/'))/api/config" -Headers $headers |
  Select-Object version, config_dir, location_name
```

Non aggiungere output contenenti token a log o report.

## Test SSH read-only

```powershell
ssh -T `
  -o BatchMode=yes `
  -o "UserKnownHostsFile=$env:HA_SSH_KNOWN_HOSTS" `
  -o StrictHostKeyChecking=yes `
  -i $env:HA_SSH_KEY_PATH `
  $env:HA_SSH_HOST_LAN `
  "hostname; docker ps --filter name=$env:HA_REMOTE_CONTAINER"
```

Il file `known_hosts` deve essere ottenuto e verificato tramite un canale fidato. Non
disabilitare `StrictHostKeyChecking`.

## Portability e validate

```powershell
pwsh -NoProfile -File .\ops\check_portability.ps1
pwsh -NoProfile -File .\ops\validate.ps1
```

Regola P0: nessun deploy se `check_portability.ps1` o `validate.ps1` non termina con
exit code `0`.

## Backup e verifica

Usare una sorgente HA esplicita e accessibile. Non assumere `Z:\`.

```powershell
pwsh -NoProfile -File .\ops\backup_runtime_snapshot.ps1 `
  -Source <HA_CONFIG_SOURCE> `
  -DestinationRoot .\_dr_backups `
  -IncludeStorage `
  -DryRun

pwsh -NoProfile -File .\ops\verify_backup_freshness.ps1 `
  -BackupRoot .\_dr_backups `
  -MaxAgeHours 24
```

## Blocco deploy corrente

Il deploy resta bloccato finche` non sono chiusi questi punti:

- aggiungere `DryRun` / `WhatIf` reale a `ops/deploy_safe.ps1`;
- rimuovere `Z:\` come target predefinito;
- evitare `fetch` e `merge` impliciti durante il deploy;
- supportare un target SSH esplicito tramite variabili;
- separare completamente validate, backup e deploy;
- riconciliare il drift tra GitHub, clone pulito e runtime.

## Known portability blockers closed on 2026-06-20

- rimossi fallback a profili utente, workspace legacy e copie chiave implicite
- rimossa ACL specifica DS-01 dagli helper chiave
- `HA_SSH_KEY_PATH` e `HA_SSH_KNOWN_HOSTS` sono ora obbligatori per gli script SSH
- `HA_SSH_HOST_LAN` configura il target operativo con fallback LAN documentato
- rimossi i default `Z:\` da deploy e job DR
- il profilo PowerShell deriva il repo root dalla posizione dello script
- i runner Python usano `scp` dal `PATH` e known-hosts esplicito

DS-01 resta compatibile caricando lo stesso contratto `.env` usato dalle nuove macchine.
