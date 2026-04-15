# AGENTS.md

## Session Bootstrap (Casa Mercurio)

- Ambiente Home Assistant runtime: `root@192.168.178.84`
- Porta SSH: `2222`
- Accesso primario: chiave SSH locale `C:\Users\randalab\.ssh\ha_ed25519`
- Fallback: `C:\Users\randalab\.ssh\ha_fallback_ed25519`
- Percorso config HA da usare come default: `/homeassistant`
- Nota: se `/homeassistant` non contiene `configuration.yaml`, provare `/config`

## Workspace Tooling (`C:\2_OPS`)

- Riferimento workspace globale: `C:\2_OPS\AGENT.md`
- Shell preferita: `pwsh`
- Workspace root condiviso: `C:\2_OPS`
- Helper di navigazione disponibili nel profilo PowerShell:
  - `repo` / `cgit` per saltare tra repository noti
  - `ops` / `cops` per saltare tra cartelle di `C:\2_OPS`
- Tool CLI disponibili e preferibili quando utili:
  - `fd`, `bat`, `jq`, `yq`, `eza`, `delta`, `zoxide`, `lazygit`
- Guida comandi condivisa:
  - `C:\2_OPS\01_docs\powershell-command-reference.md`

## Uso operativo del tooling

- Per ricerca file, preferire `fd` o `rg --files`.
- Per lettura file, preferire `bat` o `Get-Content` a seconda del contesto.
- Per JSON/YAML, preferire `jq` e `yq` invece di parsing manuale fragile.
- Prima di assumere convenzioni globali di shell o PATH, verificare `C:\2_OPS\AGENT.md`.

## Git operativo in questo repo

- Questo repository usa `.git` puntato a `.git-local`.
- In questo ambiente i comandi Git mutanti dentro `.git-local` possono fallire nel sandbox con sintomi tipo:
  - `index.lock` che resta presente
  - creazione file OK ma delete/unlink KO dentro `.git-local`
  - `unable to unlink`, `failed to insert into database`, `Permission denied` su `.git-local/objects`
- Regola operativa: per `git add`, `git commit`, `git merge`, `git rebase`, `git stash`, `git gc` e in generale per ogni comando Git che scrive in `.git-local`, preferire esecuzione fuori sandbox.
- I comandi Git read-only possono restare in sandbox.
- Prima di considerare il lock come unico problema, ricordare che su questo repo il blocco osservato puo` essere del sandbox su `.git-local`, non solo un vero problema NTFS/ACL.
- Se compare `index.lock`, usare prima il cleanup stale lock gia` documentato; se il problema persiste, rieseguire il comando Git mutante fuori sandbox invece di forzare modifiche al layout `.git-local`.

## Comandi SSH rapidi (read-only)

- Test connessione:
  - `ssh -p 2222 -i C:\Users\randalab\.ssh\ha_ed25519 root@192.168.178.84 "hostname && whoami"`
  - `ssh -p 2222 -i C:\Users\randalab\.ssh\ha_fallback_ed25519 root@192.168.178.84 "hostname && whoami"`
- Verifica file deployato:
  - `ssh -p 2222 -i C:\Users\randalab\.ssh\ha_ed25519 root@192.168.178.84 "sed -n '1,220p' /homeassistant/packages/climateops/actuators/system_actuator.yaml"`
- Verifica tracce recenti (automation ClimateOps):
  - `ssh -p 2222 -i C:\Users\randalab\.ssh\ha_ed25519 root@192.168.178.84 "grep -n \"climateops_system_actuate\" /homeassistant/.storage/trace.saved_traces | tail -n 20"`
- Verifica eventi AC recenti (logbook/trace export locale se disponibile):
  - esportare da UI trace/logbook e salvare in `docs/runtime_evidence/<date>/`

## Regola operativa

- Per audit runtime post-deploy, preferire sempre evidenza evento-level con correlazione `context_id` tra:
  - `automation.climateops_system_actuate`
  - `script.ac_giorno_apply` / `script.ac_notte_apply`
  - stato `switch.ac_giorno` / `switch.ac_notte`

## Progress visibility (sempre attiva)

- Durante attivita` operative, inviare aggiornamenti brevi e frequenti sullo stato lavori.
- Frequenza minima: un aggiornamento ogni 60 secondi quando un task e` in corso inserendo l'ora locale.
- Se un comando/tool dura oltre 60 secondi, inviare almeno un messaggio intermedio "in corso".
- Ogni update deve includere:
  - stato: `in corso` / `completato` / `bloccato`
  - azione corrente
  - prossimo passo immediato
- In caso di timeout o blocco, comunicarlo subito con causa tecnica e recovery plan.
