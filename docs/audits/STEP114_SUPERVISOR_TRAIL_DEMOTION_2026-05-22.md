# STEP114 - Supervisor trail demotion to historical provenance (2026-05-22)

## Scope
- Demotare `CURRENT_SUPERVISOR_STATUS.md` da possibile blocco corrente a snapshot storico di provenienza.
- Nessun cambio runtime.
- Nessuna modifica a secret, bridge o hardware backlog.

## FACT

- Esiste ora un entrypoint corrente piu` nuovo e piu` autorevole:
  - `CURRENT_RUNTIME_STATUS_2026-05-22.md`
- Quel file sintetizza il burn-in chiuso, il bridge chiuso, il drift source-side chiuso e i residui ancora aperti.
- `CURRENT_SUPERVISOR_STATUS.md` rimane utile come fotografia storica del 2026-05-15, ma il suo warning sul dirty-worktree non rappresenta piu` il quadro corrente del trail operativo.
- Il valore residuo del report e` quindi forense/provenance, non di blocco operativo.

## IPOTESI

- Confidenza alta: un report superseded da un entrypoint corrente piu` nuovo va trattato come storico, non come stato vigente.
- Confidenza alta: la manutenzione del trail rende il quadro piu` leggibile senza alterare alcuna logica runtime.

## DECISIONE

- Tenere `CURRENT_SUPERVISOR_STATUS.md` come archivio storico.
- Non usarlo piu` come riferimento corrente per la postura del progetto.
- Considerare il warning dirty-worktree come nota di provenienza, non come blocker attuale.

## Residuo

- Restano aperti solo i residui realmente correnti:
  - `Security / secrets hygiene`
  - `Solar Gain` calibrativo
  - `runtime verify pending` post-reload
