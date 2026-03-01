# STEP22 EHW Vendor Modbus Extraction (2026-03-01)
Date: 2026-03-01
Source: `docs/vendor/ehw/Ecohotwater.pdf`
Method: direct PDF stream decompression (`FlateDecode`) + text token reconstruction (no external OCR/tooling).

## Registri emersi dal manuale (multi-lingua coerente)

| Registro | Significato estratto dal manuale |
|---|---|
| 1020 | OUT5 / parametro uscita (contesto tabella parametri) |
| 1255 | Indirizzo Modbus (`Address Modbus`) |
| 1082 | Differential/Delta T start circolatore/pompa solare |
| 1088 | Setpoint valvola scarico solare |
| 1089 | Stop point pompa/circolatore solare |
| 1104 | Setpoint temperatura acqua calda |
| 1106 | Delta temperatura su setpoint ACS |
| 1109 | Ritardo partenza riscaldatore elettrico |
| 2019 | Sonda ingresso aria (`Inlet temp sensor`) |
| 2020 | Sonda acqua parte alta (`Water tank top`) |
| 2021 | Sonda acqua parte bassa (`Water tank bottom`) |
| 2022 | Sonda batteria alettata (`Finned coil`) |
| 2023 | Sonda aspirazione (`Suction`) |
| 2024 | Sonda uscita aria/solare (`Outlet / Solar`) |

## Allineamento con mapping attuale

`packages/ehw_modbus.yaml` e` gia` allineato ai blocchi principali emersi:
- Setpoint ACS basato su 1104/1105 (A/B addressing workaround locale).
- Sonde T01..T06 mappate nel range 2018..2024 con selezione `doc_1_based/doc_0_based`.
- Alias semantici presenti per 2019..2024 (`inlet`, `tank top`, `tank bottom`, `finned coil`, `suction`, `outlet solar`).

## Note operative

- L'estrazione conferma che i registri `2019..2024` e `1104` sono fondamentali per la diagnostica runtime.
- Persistono da validare in campo:
  - coerenza finale `addressing` (0-based vs 1-based),
  - stabilita` lettura durante cicli attivi,
  - assenza mismatch transaction_id lato stack Modbus.
