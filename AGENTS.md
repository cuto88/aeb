# AGENTS.md

## Session Bootstrap (Casa Mercurio)

- Runtime HA corrente verificato 2026-05-26: `http://192.168.178.110:8123`
- Tipo runtime corrente: Home Assistant Core in Docker/Core, non HA OS/Supervised.
- Percorso config HA corrente da usare come default: `/config`
- Endpoint storico pre-cutoff: `root@192.168.178.84:2222`, path `/homeassistant`.
- Nota operativa: non usare piu` `.84:2222` come default dopo cutoff; trattarlo solo come riferimento storico.
- SSH nuovo operativo: `dscomparin@192.168.178.110:22`, host `mercurio-edge`.
- Chiave attiva verificata: `C:\Users\randalab\.codex\memories\ha_keys\ha_ed25519.20260517_073034_121.temp`
- Container HA: `homeassistant`.
- Bind mount config: `/opt/data/homeassistant` -> `/config`.
- Le chiavi HA storiche non risultano autorizzate per `root` sul nuovo host Docker.
- Accesso primario storico: `C:\2_OPS\secrets\ha\ha_ed25519`
- Fallback storico: `C:\2_OPS\secrets\ha\ha_fallback_ed25519`
- Override runtime: `HA_SSH_KEY_PATH`
- Per deploy file sul runtime Docker, preferire SSH al Linux host o accesso diretto al bind mount Docker che contiene `/config`.
- Nota drift runtime 2026-05-26: patch chirurgiche applicate su runtime monolitico `climate_heating.yaml` / `climate_ventilation.yaml`; non fare deploy ampio dei package split senza riconciliazione.

## Workspace Tooling (`C:\2_OPS`)

- Riferimento workspace globale: `C:\2_OPS\AGENTS.md`
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
- Per lettura file, scegliere `bat` o `Get-Content` in base a quello che e` piu` rapido nel caso specifico.
- Per JSON/YAML, preferire `jq` e `yq` invece di parsing manuale fragile quando la trasformazione non e` banale.
- Prima di assumere convenzioni globali di shell o PATH, verificare `C:\2_OPS\AGENTS.md` solo se serve davvero al task.

## Git operativo in questo repo

- Stato operativo 2026-04-22: Git locale disattivato in questo workspace.
- Source of truth operativo: repository remoto GitHub `cuto88/aeb`.
- Motivo: questo workspace usava `.git` puntato a `.git-local`, ma i comandi Git mutanti dentro `.git-local` falliscono nel sandbox con sintomi tipo:
  - `index.lock` che resta presente
  - creazione file OK ma delete/unlink KO dentro `.git-local`
  - `unable to unlink`, `failed to insert into database`, `Permission denied` su `.git-local/objects`
- Decisione: non usare Git locale per `add`, `commit`, `merge`, `rebase`, `stash`, `gc` o push.
- Pubblicazione modifiche: usare GitHub connector/app o una working copy fresca esterna a questo workspace.
- `.git-local` puo` restare come stato storico recuperabile, ma non e` piu` il backend operativo del workspace.
- Per ripristinare Git locale in futuro, creare una nuova clone pulita o riattivare esplicitamente il puntatore `.git` solo fuori dal sandbox.

## Comandi SSH rapidi storici (read-only)

- Test connessione vecchio runtime HA OS/Supervised:
  - `ssh -p 2222 -i C:\2_OPS\secrets\ha\ha_ed25519 root@192.168.178.84 "hostname && whoami"`
  - `ssh -p 2222 -i C:\2_OPS\secrets\ha\ha_fallback_ed25519 root@192.168.178.84 "hostname && whoami"`
- Verifica file deployato vecchio runtime:
  - `ssh -p 2222 -i C:\2_OPS\secrets\ha\ha_ed25519 root@192.168.178.84 "sed -n '1,220p' /homeassistant/packages/climateops/actuators/system_actuator.yaml"`
- Verifica tracce recenti vecchio runtime (automation ClimateOps):
  - `ssh -p 2222 -i C:\2_OPS\secrets\ha\ha_ed25519 root@192.168.178.84 "grep -n \"climateops_system_actuate\" /homeassistant/.storage/trace.saved_traces | tail -n 20"`
- Verifica eventi AC recenti (logbook/trace export locale se disponibile):
  - esportare da UI trace/logbook e salvare in `docs/runtime_evidence/<date>/`

## Regola operativa

- Per audit runtime post-deploy, preferire sempre evidenza evento-level con correlazione `context_id` tra:
  - `automation.climateops_system_actuate`
  - `script.ac_giorno_apply` / `script.ac_notte_apply`
  - stato `switch.ac_giorno` / `switch.ac_notte`
- Requisito di provenienza operativa: ogni audit, cutover, disaster recovery, backup, restore,
  migrazione, verifica infrastrutturale o deploy deve dichiarare esplicitamente:
  - macchina operativa usata;
  - runtime target verificato o toccato;
  - stato della macchina legacy, se rilevante;
  - modalita` di accesso usata: LAN, Tailscale, SSH, HA API, GitHub Actions o simili;
  - deploy eseguito: si`/no;
  - modifiche runtime eseguite: si`/no;
  - commit o run GitHub Actions rilevanti, se presenti.
- Quality gates:
  - non modificare un gate per nascondere o silenziare un problema reale;
  - se un gate fallisce, diagnosticare prima se il problema e` nel contenuto, nella policy o nel gate;
  - correggere i contenuti quando la documentazione punta a file del repo con link non portabili o rotti;
  - usare riferimenti testuali, non link Markdown, per file locali/non versionati o per path esterni al repo;
  - modificare un gate solo per rendere la policy piu` precisa e difendibile, non per aggirare un problema;
  - dopo modifiche a gate o documentazione che impattano il controllo, rieseguire `ops/gates_run_ci.ps1` se il contesto lo consente.

## Progress visibility (quando serve)

- Durante attivita` operative lunghe, inviare aggiornamenti brevi e utili sullo stato lavori.
- Se un comando/tool dura a lungo, inviare almeno un messaggio intermedio "in corso" quando serve a mantenere il contesto.
- Ogni update, quando emesso, deve includere:
  - stato: `in corso` / `completato` / `bloccato`
  - azione corrente
  - prossimo passo immediato
- In caso di timeout o blocco, comunicarlo subito con causa tecnica e recovery plan.
