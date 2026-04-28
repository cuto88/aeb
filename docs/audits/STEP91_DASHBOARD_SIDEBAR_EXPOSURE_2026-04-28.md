# STEP91 - Dashboard sidebar exposure (2026-04-28)

## Scopo
Rendere visibili in sidebar le plance che stiamo attivamente rifattorizzando o usando come drill-down reali, evitando l'ambiguità tra file modificati e dashboard non accessibili dalla UI.

## FACT
Alcune dashboard Lovelace esistevano e venivano aggiornate correttamente, ma non erano visibili perché in `configuration.yaml` avevano `show_in_sidebar: false`.

Questo creava un problema operativo:
- refactor reale sui file;
- deploy fatto;
- nessun riscontro immediato dalla UI laterale.

## DECISIONE
Le seguenti plance vengono esposte in sidebar:

- `2-heating` -> `2 Riscaldamento`
- `3-ac` -> `3 Clima`
- `7-ehw` -> `7 EHW ACS`
- `8-mirai` -> `8 Mirai`

## Boundary

## FACT
Non sono state toccate:
- le plance `v2`
- le plance che restano candidate a consolidamento ma non ancora confermate come entrypoint frequenti

## DECISIONE
Questa modifica serve solo a riallineare:
- refactor effettivo
- accessibilità UI
- feedback operativo immediato
