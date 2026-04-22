# Involucro / Solar Gain Handoff

## Current Decision

- priorita' attuale: audit `involucro`
- audit `solar gain`: rimandato di alcuni giorni

## Why

- il solar gain va letto sopra un modello involucro gia' credibile
- oggi dobbiamo ancora consolidare:
  - stanza peggiore reale
  - rise rate stanza-per-stanza
  - utilita' reale del night flush
  - qualita' dei trend esterni
  - differenza tra carico solare, inerzia accumulata e interferenza impianto

## FACT

- base documentale gia' pronta:
  - [manuale_involucro_casa.md](logic/core/manuale_involucro_casa.md)
  - [spec_involucro_room_model.md](logic/core/spec_involucro_room_model.md)
  - [plancia_involucro.md](logic/core/plancia_involucro.md)
  - [INVOLUCRO_AUDIT_CHECKLIST.md](INVOLUCRO_AUDIT_CHECKLIST.md)
  - [INVOLUCRO_AUDIT_RUNBOOK.md](INVOLUCRO_AUDIT_RUNBOOK.md)

## Next 2-4 Days

Raccogliere almeno queste finestre:

1. giornata mite / baseline
2. giornata con carico solare evidente
3. sera utile per night flush
4. se possibile una finestra con esterno non utile, per confronto

Per ogni finestra annotare:

- `t_in_med`
- `t_out`
- stanza peggiore osservata
- rise rate peggiore
- stato finestre
- stato schermature/scuri se noto
- stato heating / AC
- `recommended_action`
- esito reale dopo 30-60 minuti

## Do Not Conclude Yet

Non chiudere ancora il modello solar gain se non sono chiari:

- quali stanze anticipano il surriscaldamento
- se la media casa maschera problemi locali
- quando fuori diventa davvero utile
- quanto la casa scarica davvero di notte

## Ready To Start Solar Gain When

Aprire il fronte `solar gain` solo quando:

- la stanza peggiore e' coerente per piu' finestre runtime
- i trend esterni risultano leggibili e utili
- il night flush e' stato osservato almeno una volta in modo chiaro
- la differenza tra carico passivo e influenza impianto e' abbastanza pulita

## Expected Next Step

Dopo il pass involucro:

- audit dedicato `solar gain`
- focus su:
  - quando il sole e' utile
  - quando diventa eccessivo
  - quando schermare
  - quando il night flush basta
  - quando l'AC e' davvero giustificata

## RISK

- partire troppo presto col solar gain produce soglie sbagliate
- una lettura troppo centrata su `t_in_med` puo' nascondere stanze critiche
- night flush e shading rischiano di essere valutati male senza 2-4 giorni di osservazione
