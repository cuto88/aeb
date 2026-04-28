# STEP93 - Dashboard naming and order normalization (2026-04-28)

## Scopo
Ridurre il caos percepito in sidebar e nei titoli interni delle plance rendendo coerenti:
- naming;
- numerazione;
- ordine logico;
- relazione tra dashboard visibile e file sorgente.

## FACT
La situazione precedente era confusa perché:
- alcuni titoli in sidebar non coincidevano con i titoli interni;
- alcune plance usavano ancora naming `v2`, altre numeri storici, altre nomi dominio puri;
- l'ordine visibile non rifletteva bene la tassonomia target.

## DECISIONE
La tassonomia visibile viene normalizzata così:

1. `1 Clima Casa`
2. `2 VMC`
3. `3 Riscaldamento`
4. `4 AC`
5. `5 FV SolarEdge`
6. `6 Consumi`
7. `7 EHW ACS`
8. `8 Mirai`
9. `9 Modbus`
10. `10 Involucro`

## Plance legacy

## DECISIONE
Le plance legacy non spariscono, ma vengono esplicitamente rinominate e nascoste:
- `2 VMC (legacy)`
- `4 AC (legacy)`

Questo evita che restino "plance fantasma" con naming ambiguo.

## File allineati

## FACT
Sono stati riallineati:
- titoli sidebar in `configuration.yaml`
- titoli top-level e/o `views.title` dei file Lovelace visibili

## Obiettivo operativo

## DECISIONE
Da ora:
- la sidebar deve raccontare una sequenza leggibile;
- il titolo che vedi entrando nella plancia deve corrispondere alla voce di menu;
- il numero iniziale identifica la posizione architetturale, non la storia del file.
