# STEP123 — AC humidity discomfort audit plan (2026-06-01)

## Obiettivo

Documentare il problema percepito di discomfort interno durante l'alternanza `ac_giorno` / `ac_notte` e definire un audit misurabile prima di cambiare la policy.

## Problema da risolvere

- Segnale utente: discomfort percepibile durante accensioni separate giorno/notte.
- Ipotesi principale: componente umidita` (UR/dew point) piu` impattante della sola temperatura.
- Rischio operativo: ottimizzare la temperatura senza controllare UR/dew point puo` peggiorare il comfort percepito.

## Strumentazione introdotta (solo misuratori)

Sono stati aggiunti misuratori senza cambiare logica attuativa:

- `binary_sensor.ac_ur_fuori_banda_comfort`
- `sensor.ac_ur_fuori_banda_ore_24h`
- `binary_sensor.ac_dew_point_alto`
- `sensor.ac_dew_point_alto_ore_24h`
- `binary_sensor.ac_day_night_target_mismatch`
- `sensor.ac_mismatch_giorno_notte_ore_24h`

Contesto associato gia` presente:

- `sensor.ac_giorno_cicli_on_oggi`
- `sensor.ac_notte_cicli_on_oggi`
- `sensor.ac_giorno_tempo_on_oggi`
- `sensor.ac_notte_tempo_on_oggi`

## Piano audit (prima fase)

Finestra iniziale: 7 giorni continui post-deploy (dal 2026-06-01).

Raccogliere ogni giorno:

1. ore fuori banda UR (`sensor.ac_ur_fuori_banda_ore_24h`)
2. ore dew point alto (`sensor.ac_dew_point_alto_ore_24h`)
3. ore mismatch target giorno/notte (`sensor.ac_mismatch_giorno_notte_ore_24h`)
4. cicli AC giorno/notte e tempo ON
5. correlazione qualitativa con comfort percepito (note utente)

## Criterio di uscita audit

Audit chiudibile quando:

- esiste baseline di 7 giorni con trend leggibile;
- e` chiaro se il discomfort correla a UR/dew point o a churn/switching;
- viene proposta una modifica policy minima con impatto stimato e metrica di verifica.

## Non-obiettivi di questo step

- Nessun tuning soglie DRY/COOL.
- Nessuna modifica isteresi.
- Nessun cambio di authority writer.

## Prossimo step atteso

A valle della baseline 7 giorni: proposta di tuning conservativo (una sola leva per volta), con verifica su 72h.
