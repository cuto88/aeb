# STEP124 — AC whole-home comfort control (2026-06-21)

## Esito

La selezione esclusiva giorno/notte e` stata sostituita da due richieste comfort
indipendenti. Il sistema puo` attuare:

- `COOL_DAY`
- `COOL_NIGHT`
- `COOL_BOTH`
- `IDLE`

## Regola comfort

Ogni macro-zona usa temperatura, umidita` relativa e dew point.

- temperatura ON: target casa + 0,5 °C;
- temperatura OFF: target casa;
- umidita` ON: UR > 62% e dew point > 16,5 °C;
- umidita` OFF: UR <= 58% o dew point <= 15,5 °C;
- protezione anti-sovraraffreddamento sul controllo umidita`;
- conferma richiesta: 5 minuti;
- lock minimi ON/OFF separati per split.

La zona notte usa il massimo dei sensori disponibili delle sole camere
`notte1` e `notte2`, per evitare che una stanza fuori comfort venga nascosta
dalla media. Il bagno e` intenzionalmente escluso: i picchi transitori di
temperatura e umidita` ne alterano eccessivamente la richiesta AC. Il bagno
resta gestito dalla logica VMC/boost dedicata.

## Target

`input_number.ac_cool_setpoint` e` il target ambiente. Il target inviato agli
split applica `input_number.ac_equipment_target_offset`, inizialmente 2 °C, per
compensare la differenza tra sensore ambiente e sensore interno dello split.

## Spegnimento manuale

Uno spegnimento con contesto utente:

1. spegne entrambi gli split;
2. attiva `input_boolean.ac_auto_pause`;
3. avvia `timer.ac_auto_pause_timeout` per 90 minuti;
4. impedisce riaccensioni automatiche durante la pausa.

`script.ac_resume_automatic` annulla anticipatamente la pausa.

## Runtime

- runtime: `mercurio-edge`, container `homeassistant`;
- check_config: PASS;
- riavvio container: PASS;
- stato post-deploy: `COMFORT_OK`;
- richieste giorno/notte: `off` / `off`;
- hierarchy/system mode: `IDLE` / `IDLE`;
- infografica `/local/ac_comfort_flow.svg`: HTTP 200;
- backup:
  - `/config/backups/ac_comfort_20260621_103417`
  - `/config/backups/ac_comfort_20260621_103848`

Gli errori startup per unique ID `cm_*` duplicati e i timeout Modbus EHW erano
gia` presenti e non sono stati introdotti da questo intervento.

