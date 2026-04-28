# STEP99 — AC dashboard lavanderia runtime gap fix (2026-04-28)

## FACT

- Nella plancia `4 AC`, sotto `Lavanderia`, comparivano 3 entita` non trovate.
- Verifica contro `core.entity_registry` di Home Assistant:
  - `sensor.t_in_lavanderia` -> missing
  - `sensor.ur_in_lavanderia` -> missing
  - `input_boolean.vent_finestra_lavanderia_aperta` -> missing

## IPOTESI (confidenza alta)

- La card `Lavanderia` era un residuo di modello UI non supportato dal runtime attuale.
- Mantenerla visibile non aggiunge valore operativo e produce solo rumore.

## DECISIONE

- Rimossa la card `Lavanderia` da `4 AC`.
- Nessun cambio alla logica clima.
- Nessuna assunzione di nuovi sensori/helper non esistenti.

## File toccati

- `lovelace/climate_ac_plancia_v2.yaml`
- `docs/audits/README.md`

## Esito atteso

- nessuna card rotta in `4 AC` sotto la sezione notte/zone
