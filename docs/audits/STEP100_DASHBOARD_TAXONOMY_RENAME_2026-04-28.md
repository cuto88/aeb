# STEP100 — Dashboard taxonomy rename (2026-04-28)

## FACT

- La struttura dashboard `1–10` era ormai ordinata, ma alcuni titoli restavano:
  - troppo generici (`Clima Casa`, `Consumi`)
  - troppo eterogenei tra loro
  - poco allineati a una tassonomia tecnica unica

## IPOTESI (confidenza alta)

- Una nomenclatura ispirata a domini/loop tecnici ha senso.
- Un naming troppo "space-tech puro" peggiorerebbe la leggibilita`.
- La soluzione corretta e` una tassonomia **ibrida**:
  - tecnica
  - coerente
  - ancora leggibile in uso quotidiano

## DECISIONE

- Introdotta una nomenclatura dashboard piu` sistemistica:
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

## Razionale

- `ECLSS Casa`
  - overview di tutti i sottosistemi clima/comfort/servizi ambiente
- `Air Loop`
  - VMC, freecooling, boost, flussi aria
- `Heating Loop`
  - dominio riscaldamento
- `Cooling Loop`
  - dominio AC
- `PV Array`
  - dominio fotovoltaico
- `Power Runtime`
  - consumi e runtime energetico
- `DHW / ACS`
  - acqua calda sanitaria
- `MIRAI Plant`
  - macchina/impianto MIRAI
- `Fieldbus`
  - plancia bus/forensic
- `Envelope`
  - involucro e fisica edificio

## File toccati

- `configuration.yaml`
- `lovelace/01_eclss_casa.yaml`
- `lovelace/02_air_loop.yaml`
- `lovelace/03_heating_loop.yaml`
- `lovelace/04_cooling_loop.yaml`
- `lovelace/05_pv_array.yaml`
- `lovelace/06_power_runtime.yaml`
- `lovelace/07_dhw_acs.yaml`
- `lovelace/08_mirai_plant.yaml`
- `lovelace/09_fieldbus.yaml`
- `lovelace/10_envelope.yaml`
- `docs/audits/README.md`

## Esito atteso

- sidebar piu` coerente
- ruoli dashboard piu` leggibili
- tassonomia piu` stabile per evoluzioni future
