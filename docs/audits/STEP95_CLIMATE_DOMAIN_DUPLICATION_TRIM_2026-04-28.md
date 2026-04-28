# STEP95 — Climate domain dashboard duplication trim (2026-04-28)

## FACT

- `1 Clima Casa` oggi contiene gia`:
  - overview VMC
  - overview AC
  - overview Heating
  - KPI ambientali sintetici
  - stato zone principali
- `2 VMC`, `3 Riscaldamento`, `4 AC` non sono ridondanti in blocco:
  - restano i drill-down di dominio
  - contengono dettaglio che `Clima Casa` non deve riassorbire

## IPOTESI (confidenza alta)

- Eliminare `2/3/4` riporterebbe `Clima Casa` verso una plancia troppo densa.
- Il problema reale non e` l'esistenza delle plance dominio, ma una parte di duplicazione superficiale con l'overview.

## DECISIONE

- `2 VMC`, `3 Riscaldamento`, `4 AC` restano **visibili** e **mantenute**.
- Si taglia solo il superfluo piu` evidente, lasciando i drill-down intatti.

## Tagli applicati

### `2 VMC`

- rinominato il blocco iniziale da `Stato generale` a `Runtime VMC`
- rimossi i tile `AC giorno` / `AC notte` dalle sezioni zona
  - motivo: il controllo AC ha gia` overview in `Clima Casa` e drill-down proprio in `4 AC`
  - nella plancia VMC resta la correlazione tramite:
    - `binary_sensor.clima_ac_from_vmc_request`
    - logica freecooling / boost / velocita`

### `4 AC`

- rimossa la sezione `KPI clima`
  - motivo: duplicava quasi integralmente i KPI ambientali gia` presenti in `Clima Casa`
  - il drill-down AC resta focalizzato su:
    - stato macchina
    - giorno / notte
    - fan mode
    - finestre e zone

## Non modificato in questo step

### `3 Riscaldamento`

- resta invariata come drill-down principale
- oggi contiene ancora:
  - setpoint
  - zone incluse
  - KPI diagnostici
  - runtime/cicli
  - debug
  - remap legacy
- quindi non e` ancora riducibile senza perdere funzione reale

## Esito architetturale

- `1 Clima Casa` = overview operativa
- `2 VMC` = ventilazione / boost / freecooling / trigger
- `3 Riscaldamento` = setpoint / runtime / debug heating
- `4 AC` = stato AC e dettaglio zone

La gerarchia migliora senza comprimere tutto nella dashboard principale.
