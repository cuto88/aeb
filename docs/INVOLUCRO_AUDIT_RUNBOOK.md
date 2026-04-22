# Involucro Audit Runbook

## Goal

- eseguire audit involucro rapido, ripetibile, stanza-per-stanza

## Sequence

1. Aprire la plancia [envelope_involucro_plancia.yaml](../lovelace/envelope_involucro_plancia.yaml).
2. Verificare stato noto di:
   - finestre
   - scuri / schermature se osservabili
   - heating
   - AC
3. Annotare:
   - `t_in_med`
   - `t_out`
   - `pv_power_now`
   - stanza peggiore
   - azione suggerita
4. Ripetere nelle 4 finestre:
   - baseline mattino
   - carico solare
   - tardo pomeriggio
   - night flush
5. Non cambiare soglie nel mezzo della stessa sessione audit.

## Minimum Output

- stanza peggiore per finestra
- rise rate peggiore
- delta stanza vs esterno
- trend esterno
- azione suggerita
- azione umana realmente scelta
- esito dopo 30-60 minuti

## Do Not Do

- non usare subito AC per "ripulire" la lettura se l'obiettivo e' audit involucro
- non cambiare contemporaneamente finestre, schermature e setpoint senza annotarlo
- non concludere sul solar gain se il comportamento e' chiaramente contaminato da impianto
