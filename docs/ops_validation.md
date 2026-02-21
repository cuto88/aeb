# Ops validation (VMC + AC)

## Checklist
- Comando standard locale:
  - `pwsh -NoProfile -ExecutionPolicy Bypass -File ops/validate.ps1`
- Con check Home Assistant esplicito:
  - `pwsh -NoProfile -ExecutionPolicy Bypass -File ops/validate.ps1 -HaCheck` (esegue anche `ha core check`)
- CI:
  - `pwsh -NoProfile -ExecutionPolicy Bypass -File ops/gates_run_ci.ps1` (read-only, senza step mutanti locali e senza `ha core check`)
- Verifica in UI: gli switch AC/VMC non devono essere richiamati se già nello stato target (logbook più pulito).

## Compatibilità alias/comandi
- Legacy compatibile: `ops/gates_run.ps1` resta disponibile.
- Reindirizzamento consigliato:
  - alias/funzioni `gates` o `ha-gates` -> `ops/validate.ps1`
  - per includere il check HA: `gates -HaCheck` (se alias PowerShell caricato)

## Rollback
- `git log -1 --oneline` (per trovare l'hash)
- `git revert <hash>`
- Se revert fallisce per conflitti: `git revert --abort`
- Ripeti: `pwsh -NoProfile -ExecutionPolicy Bypass -File ops/validate.ps1 -HaCheck`

## Stabilizzazione attuatori (VMC + AC)

- State guard: azioni bloccate se stato target già applicato.
- Debounce VMC: 20s su sensor.vmc_vel_target per prevenire flapping.
- AC guard centralizzato: script ac_apply_targets con confronto stato desiderato vs attuale.
- KPI churn:
  - counter.vmc_churn_suppressed → azioni VMC evitate
  - counter.ac_churn_suppressed → azioni AC evitate

Incremento dei counter = sistema stabile (azioni inutili soppresse).
