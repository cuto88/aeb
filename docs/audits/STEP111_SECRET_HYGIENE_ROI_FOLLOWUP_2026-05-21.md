# STEP111 - Secret hygiene ROI follow-up (2026-05-21)

## Scope
- Isolare il residuo di sicurezza a massimo ROI dopo la chiusura del burn-in giornaliero.
- Nessun cambio runtime.
- Nessuna rotazione segreti eseguita da questo step.

## FACT

- Il progetto contiene ancora un finding documentato ad alta severita` sul file `.env`.
- La scansione del trail documentale non ha mostrato una copia esplicita del token in chiaro fuori dal workspace runtime, ma il rischio operativo resta reale perche` `.env` e` usato direttamente dagli script di audit e supervisione.
- I riferimenti runtime al segreto sono concentrati in:
  - `ops/aeb_runtime_audit_snapshot.ps1`
  - `ops/involucro_audit_snapshot.ps1`
  - `ops/README.md`
  - `README.md`
- L'audit corrente del progetto classifica ancora la security posture come `OPEN` finche` il token non viene ruotato e il workspace non viene trattato come compromesso operativo.

## IPOTESI

- Confidenza alta: il vero ROI adesso non e` cercare altro drift runtime, ma togliere ambiguita` al rischio segreti.
- Confidenza alta: la documentazione deve dire chiaramente che il token in `.env` non e` un dettaglio tecnico innocuo ma un residuo di sicurezza da chiudere.

## DECISIONE

- Non spendere altro tempo su discovery hardware.
- Tenere aperto solo il fronte security hygiene.
- Usare questo step come nota di follow-up per il lavoro di rotazione/bonifica fuori dal runtime.

## Minimo da fare fuori da questo step

1. Ruotare il token Home Assistant.
2. Verificare che `.env` non sia copiato in backup o note operative.
3. Tenere il trail documentale su una formulazione esplicita e non allarmistica:
   - `workspace compromise risk`
   - `needs rotation`
   - `no runtime logic change`

## Residuo dopo questo step

- Il problema di sicurezza non e` risolto da questa nota.
- E` pero` ora isolato come unico residuo ad alto ROI ancora aperto insieme al drift source/runtime.
