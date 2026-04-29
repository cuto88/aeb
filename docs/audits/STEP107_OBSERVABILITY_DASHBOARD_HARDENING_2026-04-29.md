# STEP107 — Observability dashboard hardening (2026-04-29)

## FACT

- `11 Observability` era gia` utile, ma la lettura di:
  - sensori `unknown/unavailable`
  - dipendenza wireless / batteria
  risultava ancora troppo implicita.

## DECISIONE

- Rafforzata la sezione `Unavailable / unknown` con:
  - `Critical runtime`
  - `Battery / radio sensors missing`
- Rafforzata la sezione `Battery / radio risk` con:
  - `Battery telemetry` con `last-updated`
  - `Wireless dependency map` con `last-updated`

## DECISIONE

- `11 Observability` ora copre in modo piu` leggibile:
  - runtime critico
  - stale / unavailable
  - rischio sensori radio / batteria
  - differenza tra source fisica e proxy

## VERIFICA

- `ops/gates_run_ci.ps1` => `ALL GATES PASSED`

