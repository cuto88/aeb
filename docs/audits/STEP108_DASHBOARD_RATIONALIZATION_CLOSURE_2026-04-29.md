# STEP108 — Dashboard rationalization closure (2026-04-29)

## FACT

- La sidebar ufficiale e` stata stabilizzata con taxonomy coerente:
  - `1 ECLSS Casa`
  - `2 Air Loop`
  - `3 Heating Loop`
  - `4 Cooling Loop`
  - `5 PV Array`
  - `6 Power Runtime`
  - `7 DHW / ACS`
  - `8 MIRAI Plant`
  - `9 Fieldbus`
  - `10 Envelope`
  - `11 Observability`

## FACT

- Le plance hanno ora ruoli separati e non concorrenti:
  - `1` overview operativa
  - `2/3/4` drill-down clima
  - `6` sintesi energia
  - `7/8` drill-down macchina
  - `9` raw / forensic fieldbus
  - `10` building physics
  - `11` observability / fault board

## FACT

- Le plance legacy restano nascoste.
- Le entita` mancanti segnalate durante il refactor sono state corrette o rimosse.
- Il recovery incident Lovelace e` stato corretto e documentato.

## DECISIONE

- Blocco `dashboard rationalization`: `CLOSED`
- Nuove modifiche UI non sono piu` necessarie per struttura o naming.
- Prossimi lavori vanno considerati:
  - implementativi hardware
  - runtime / observability
  - o piccoli affinamenti puntuali, non piu` refactor sistemico

## VERIFICA

- Quality gates locali: `PASS`
- Quality gates GitHub: `PASS`

