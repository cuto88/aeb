# STEP101 — HA recovery mode fix: Lovelace dashboard indentation (2026-04-28)

## FACT

- Dopo il rename tassonomico dashboard, Home Assistant e` entrato in recovery mode.
- I log HA mostrano:
  - `Invalid config for 'lovelace'`
  - dashboard `01..10` interpretate come opzioni invalide sotto `0-lovelace`
- Causa tecnica:
  - errata indentazione YAML in `configuration.yaml`
  - i dashboard custom erano annidati sotto:
    - `lovelace -> dashboards -> 0-lovelace`
  - invece di essere sibling di `0-lovelace`

## DECISIONE

- Corretta l'indentazione di:
  - `01-clima-casa`
  - `02-vmc`
  - `03-riscaldamento`
  - `04-ac`
  - `05-fv-solaredge`
  - `06-consumi`
  - `07-ehw-acs`
  - `08-mirai`
  - `09-modbus`
  - `10-involucro`
- Nessun rollback dei titoli/tassonomia.
- Si corregge il file, non il modello dashboard.

## File toccati

- `configuration.yaml`
- `docs/audits/README.md`

## Esito atteso

- `ha core check` pulito lato `lovelace`
- frontend fuori da recovery mode
- sidebar con titoli rinominati correttamente applicati
