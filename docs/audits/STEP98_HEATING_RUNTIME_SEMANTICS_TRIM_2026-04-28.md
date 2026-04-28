# STEP98 — Heating dashboard runtime semantics trim (2026-04-28)

## FACT

- `3 Riscaldamento` non presentava entita` mancanti.
- Il problema residuo era di leggibilita`:
  - troppo overlap tra overview, diagnostica e debug
  - naming del relay fisico fuorviante rispetto alla semantica reale

## FACT

- `switch.4_ch_interruttore_3` non e` il comando diretto della pompa.
- Nel modello impiantistico corrente rappresenta il dominio:
  - `riduzione notturna termostati`

## DECISIONE

- Nessuna eliminazione della plancia `3 Riscaldamento`
- Nessun cambiamento di logica runtime
- Solo refactor UI di chiarezza

## Modifiche applicate

### Runtime

- `Heating – Stato generale` rinominato in:
  - `Heating – Runtime`
- nel blocco runtime mantenuti:
  - lock min ON/OFF
  - manuale
  - modalita` manuale
  - `switch.heating_master`
  - `switch.4_ch_interruttore_3`

### Naming semantico

- `switch.4_ch_interruttore_3`
  - da `Relay fisico`
  - a `Riduzione notturna termostati`

### Diagnostica / debug

- `Heating  KPI e diagnostica` rinominato in:
  - `Heating – Diagnostica`
- il blocco `Heating – Debug` e` stato ridotto:
  - rimossi indicatori gia` presenti in KPI/timeline
  - mantenuti solo segnali di supporto reale

## Esito architetturale

- `1 Clima Casa` resta overview
- `3 Riscaldamento` resta drill-down
- meno ridondanza interna
- semantica piu` aderente all'impianto reale
