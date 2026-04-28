# STEP104 — Technical dashboard role separation (2026-04-28)

## FACT

- `7 DHW / ACS` e `8 MIRAI Plant` sono plance macchina tecniche ma leggibili.
- `9 Fieldbus` conteneva una quota eccessiva di semantica gia` presente nelle plance macchina:
  - stato macchina MIRAI
  - sonde semantiche / snapshot gia` tradotti
  - lettura ACS/EHW piu` operativa che raw

## FACT

- Questo generava una duplicazione di ruolo:
  - `7`/`8` come drill-down macchina
  - `9` come pseudo-drill-down macchina parallelo

## IPOTESI (confidenza alta)

- La struttura corretta e`:
  - `7 DHW / ACS` = macchina ACS/EHW
  - `8 MIRAI Plant` = macchina MIRAI
  - `9 Fieldbus` = readiness bus, mapping, raw registers, forensic

## DECISIONE

- `7 DHW / ACS`
  - sezione `Status` rinominata `Runtime`
  - sezione `Debug` rinominata `Diagnostica`
  - aggiunta nota esplicita che `9 Fieldbus` va usata solo per livello raw / basso livello

- `9 Fieldbus`
  - vista `SDM120` -> `SDM120 raw`
  - vista `MIRAI` -> `MIRAI raw`
  - vista `EHW` -> `EHW raw`
  - introdotte note di ruolo in ciascuna vista
  - rimossa semantica macchina non necessaria dalla vista MIRAI raw
  - ridotta la vista EHW raw a readiness/mapping + registri

## DECISIONE

- Sidebar invariata
- Gerarchia resa piu` chiara:
  - `6 Power Runtime` = energia sintetica
  - `7 DHW / ACS` = macchina ACS
  - `8 MIRAI Plant` = macchina MIRAI
  - `9 Fieldbus` = raw / forensic

## VERIFICA

- `ops/gates_run_ci.ps1` => `ALL GATES PASSED`
