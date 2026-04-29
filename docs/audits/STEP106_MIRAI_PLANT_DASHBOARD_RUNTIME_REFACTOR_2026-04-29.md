# STEP106 — MIRAI Plant dashboard runtime refactor (2026-04-29)

## FACT

- `8 MIRAI Plant` era corretta come contenuto ma la testata iniziale era troppo monolitica.
- Nello stesso blocco finivano insieme:
  - stato macchina
  - corroborazione runtime
  - segnali probe / raw candidati

## IPOTESI (confidenza alta)

- La leggibilita` migliora se la testata distingue chiaramente:
  - stato macchina
  - corroborazione
  - segnali probe/raw

## DECISIONE

- Sezione `Stato generale` -> `Runtime macchina`
- Aggiunta nota iniziale di ruolo:
  - `8 MIRAI Plant` = drill-down macchina
  - `9 Fieldbus` = raw bus / forensic
- Separata la testata in tre card:
  - `Stato macchina`
  - `Corroborazione`
  - `Probe e raw candidati`
- In `Diagnostica rapida` aggiunta `sensor.mirai_power_w`
- In `History 24h` aggiunta `sensor.mirai_power_w`

## DECISIONE

- Nessuna modifica logica runtime
- Solo miglioramento UX / leggibilita`

## VERIFICA

- `ops/gates_run_ci.ps1` => `ALL GATES PASSED`
