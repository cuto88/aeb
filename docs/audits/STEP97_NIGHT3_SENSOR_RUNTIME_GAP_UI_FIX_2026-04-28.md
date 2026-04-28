# STEP97 — Night3 sensor runtime gap UI fix (2026-04-28)

## FACT

- Verifica completa su `2 VMC` contro `core.entity_registry` di Home Assistant:
  - tutte le entita` della plancia risultano registrate
  - **tranne**:
    - `sensor.t_in_notte3`
    - `sensor.ur_in_notte3`
- Lo stesso gap era presente anche in `4 AC`.

## IPOTESI (confidenza alta)

- La camera 3 oggi ha finestra integrata nel modello runtime, ma non sensori T/UR effettivamente caricati nel runtime HA.
- Lasciare i riferimenti in plancia produce solo card rotte, senza aggiungere informazione.

## DECISIONE

- Rimossi i riferimenti a:
  - `sensor.t_in_notte3`
  - `sensor.ur_in_notte3`
- mantenuta la presenza di `camera3` dove ha senso realmente:
  - finestra / stato apertura

## Plance corrette

- `2 VMC`
  - rimossi i tile T/UR camera3
  - mantenuto `input_boolean.vent_finestra_notte3_aperta`
- `4 AC`
  - rimossi T/UR dalla card `Notte 3`
  - mantenuta la finestra

## File toccati

- `lovelace/climate_ventilation_plancia_v2.yaml`
- `lovelace/climate_ac_plancia_v2.yaml`
- `docs/audits/README.md`

## Esito atteso

- nessuna card rotta per `camera3` in `2 VMC`
- nessuna card rotta per `Notte 3` in `4 AC`
