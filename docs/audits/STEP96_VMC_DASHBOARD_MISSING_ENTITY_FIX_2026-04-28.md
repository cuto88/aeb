# STEP96 — VMC dashboard missing entity fix (2026-04-28)

## FACT

- `2 VMC` mostrava entita` mancanti nella sezione finestre.
- La causa era un mismatch di naming:
  - la plancia puntava a `binary_sensor.windows_*`
  - il runtime/UI reale usa gli helper:
    - `input_boolean.vent_finestra_*_aperta`

## IPOTESI (confidenza alta)

- Il problema era limitato alla plancia VMC.
- Le entita` termiche e i sensori principali del dominio risultano coerenti nel repo.

## DECISIONE

- Riallineati i riferimenti di `2 VMC` alle entita` finestra canoniche gia` usate in:
  - `1 Clima Casa`
  - `4 AC`
  - `packages/climate_ventilation_windows.yaml`

## Correzioni applicate

- `binary_sensor.windows_giorno1` -> `input_boolean.vent_finestra_giorno1_aperta`
- `binary_sensor.windows_giorno2` -> `input_boolean.vent_finestra_giorno2_aperta`
- `binary_sensor.windows_notte1` -> `input_boolean.vent_finestra_notte1_aperta`
- `binary_sensor.windows_notte2` -> `input_boolean.vent_finestra_notte2_aperta`
- `binary_sensor.windows_notte3` -> `input_boolean.vent_finestra_notte3_aperta`

## File toccati

- `lovelace/climate_ventilation_plancia_v2.yaml`
- `docs/audits/README.md`

## Esito atteso

- `2 VMC` non deve piu` mostrare card mancanti per le finestre di zona.
