# STEP94 — Involucro / Passive House consolidation (2026-04-28)

## FACT

- La struttura dashboard `1–10` e` stata mantenuta tutta visibile.
- Esisteva una sovrapposizione forte tra:
  - `1 Clima Casa > Passive House`
  - `10 Involucro`
- `Passive House` dentro `Clima Casa` replicava:
  - runtime involucro
  - solar gain
  - shading
  - trend
  - tarature
- `10 Involucro` era gia` la plancia tecnica completa del dominio.

## IPOTESI (confidenza alta)

- La duplicazione non aggiungeva valore operativo.
- La main dashboard deve offrire una sintesi leggibile, non una seconda plancia completa dello stesso dominio.
- Il dominio involucro ha senso se separato in:
  - `summary` in `Clima Casa`
  - `full drill-down` in `10 Involucro`

## DECISIONE

- `Passive House` dentro `Clima Casa` resta visibile, ma viene ridotta a **sintesi operativa**.
- `10 Involucro` resta la **plancia completa** del dominio.
- Le tarature e la diagnostica estesa non restano nella main dashboard.

## Modifiche applicate

### `Clima Casa > Passive House`

- mantenuto un blocco `Stato rapido`
- sostituiti i blocchi estesi con:
  - `Sintesi involucro`
  - `Trend e accesso`
- rimossi dalla main dashboard:
  - shading manuale dettagliato
  - observed metrics estese
  - thresholds / tarature
  - doppio set di history graphs

### Accesso al drill-down

- aggiunto pulsante:
  - `Apri 10 Involucro`
- path di navigazione:
  - `/10-involucro/involucro`

## Effetto architetturale

- `1 Clima Casa` = overview reale
- `10 Involucro` = dominio tecnico completo
- meno overlap
- meno rischio di mantenere due viste incoerenti sullo stesso sottosistema

## File toccati

- `lovelace/climate_casa_unified_plancia.yaml`
- `docs/audits/README.md`

## Verifica attesa

- `Passive House` deve risultare piu` corta e leggibile
- `10 Involucro` resta la sede completa per:
  - zone
  - shading
  - thermal context
  - detailed envelope diagnostics
