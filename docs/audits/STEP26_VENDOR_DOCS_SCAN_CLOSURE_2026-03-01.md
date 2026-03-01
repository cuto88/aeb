# STEP26 — Vendor docs scan + closure (2026-03-01)

## Scope

Consolidare la documentazione vendor appena aggiunta (`docs/vendor/mirai`, `docs/vendor/ehw`) e registrare una scansione runtime rapida di controllo prima della chiusura.

## Vendor docs utili (confermati)

### MIRAI

- `docs/vendor/mirai/manuale_pdc.md`
- `docs/vendor/mirai/pdc_registers_review.md`
- `docs/vendor/mirai/pdc_io_map.json`
- `docs/vendor/mirai/home_assistant_entities.yaml`

Valore operativo:
- parametri bus RS-485/RTU confermati (`9600`, `8E1`, `address 1`, `timeout 1000`)
- tassonomia I/O e punti `C4xx` utile per supervisione/cablaggio
- assenza mappa completa `C4xx -> registro Modbus` numerico (limite noto)

### EHW

- `docs/vendor/ehw/ehw.json`
- `docs/vendor/ehw/docs/modbus_map.md`
- `docs/vendor/ehw/exports/modbus_map.csv`
- `docs/vendor/ehw/homeassistant/modbus_solar.yaml`

Valore operativo:
- registri vendor consolidati: `1020, 1076, 1082, 1088, 1089, 1104, 1106, 1109, 2019..2024`
- tabella di riferimento pronta per allineamento runtime/plance
- esempio HA disponibile (con assunzioni dichiarate)

## Scan runtime eseguiti in questa fase

Evidenze salvate:
- `tmp/mirai_scan_now_20260301_162207.csv`
- `tmp/mirai_scan_now_short_20260301_163246.csv`
- `tmp/ip_mapping_scan_20260301_163218.json`

Esito sintetico:
- profilo `host 192.168.178.190, unit 3` risponde sui registri Mirai attesi (`1003/1208/1209`) e su subset registri EHW
- profilo `host 192.168.178.191, unit 1` risponde sui registri EHW (`56/57/60`) e anche su registri Mirai
- quadro attuale da trattare come multi-profilo gateway; nessun cutover IP/unit applicato in questo step

## Aggiornamenti documentazione core

Aggiornati:
- `docs/logic/core/README_sensori_mirai.md`
- `docs/logic/core/README_sensori_ehw.md`

Contenuto aggiunto:
- riferimenti espliciti ai nuovi file vendor
- limiti noti della documentazione Mirai (assenza mapping numerico completo)

## Decisione di chiusura

- Chiusura tecnica della fase documentale: **OK**
- Chiusura tecnica scansione rapida pre-cutover: **OK**
- Nessuna inversione IP/unit eseguita in questo step.
