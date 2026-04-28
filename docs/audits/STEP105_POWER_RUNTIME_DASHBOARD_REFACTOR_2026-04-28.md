# STEP105 — Power Runtime dashboard refactor (2026-04-28)

## FACT

- `6 Power Runtime` era ancora troppo densa e mescolava:
  - sintesi energia locale
  - host `ds-01`
  - diagnostica EHW
  - trend

## FACT

- La presenza della diagnostica EHW in `6` duplicava impropriamente il ruolo di:
  - `7 DHW / ACS`
  - `9 Fieldbus`

## IPOTESI (confidenza alta)

- `6` deve restare una plancia di sintesi:
  - quote
  - potenze
  - consumi
  - KPI
  - host locale

## DECISIONE

- Sezione `Stato attuale` -> `Runtime energia`
- Aggiunta nota iniziale con ruolo della plancia e rimandi a:
  - `7 DHW / ACS`
  - `8 MIRAI Plant`
  - `9 Fieldbus`
- Rimosso il blocco `EHW diagnostica mapping`
- Riordinato il blocco potenze:
  - rete/SDM120
  - direzione flusso
  - carichi locali
- `ds-01 / Home Assistant host` rinominato `Host locale ds-01`
- Sezione `Andamento 24h` -> `Trend e KPI`

## DECISIONE

- `6 Power Runtime` resta visibile in sidebar
- ruolo reso piu` netto:
  - sintesi energia locale
  - non drill-down macchina

## VERIFICA

- `ops/gates_run_ci.ps1` => `ALL GATES PASSED`
