# Spec Involucro Room Model

Specifica tecnica iniziale per portare il modello involucro da manuale concettuale a future entita` runtime.

## Scopo
- Definire naming coerente delle entita` stanza-per-stanza.
- Separare KPI locali da KPI globali.
- Fissare un ordine di implementazione prudente.

## Stanze incluse nella Fase 1
- `giorno`
- `notte1`
- `notte2`
- `bagno`

Nota:
- `giorno`, `notte1`, `notte2` sono il perimetro minimo consigliato.
- `bagno` va mantenuto in spec ma trattato con cautela, perche' l'umidita` e gli usi transitori possono contaminarne l'interpretazione termica.

## Sorgenti canoniche

### Temperatura stanza
- `sensor.t_in_giorno`
- `sensor.t_in_notte1`
- `sensor.t_in_notte2`
- `sensor.t_in_bagno`

### Contesto globale
- `sensor.t_in_med`
- `sensor.t_out`
- `sensor.ur_out`
- `sensor.pv_power_now`
- `binary_sensor.casa_chiusa`
- `switch.heating_master`
- `switch.ac_giorno`
- `switch.ac_notte`

### Aperture aggregate
- `binary_sensor.windows_giorno_any`
- `binary_sensor.windows_notte_any`
- `binary_sensor.windows_bagno_any`

## Naming standard proposto

### Derivate stanza
Per ogni stanza `<room>`:
- `sensor.envelope_<room>_rise_rate_cph`
- `sensor.envelope_<room>_delta_vs_outdoor_c`
- `sensor.envelope_<room>_delta_vs_house_avg_c`
- `sensor.envelope_<room>_solar_gain_score`
- `sensor.envelope_<room>_overheating_risk`
- `binary_sensor.envelope_<room>_shade_recommended`
- `binary_sensor.envelope_<room>_night_flush_candidate`

Esempi:
- `sensor.envelope_giorno_rise_rate_cph`
- `sensor.envelope_notte1_overheating_risk`
- `binary_sensor.envelope_giorno_shade_recommended`

### Sintesi casa
- `sensor.envelope_worst_room_name`
- `sensor.envelope_worst_room_overheating_risk`
- `sensor.envelope_house_passive_gain_state`
- `sensor.envelope_house_night_flush_potential`
- `binary_sensor.envelope_house_ac_justified`
- `sensor.envelope_recommended_action`

### Trend esterni
- `sensor.envelope_t_out_rise_rate_cph`
- `sensor.envelope_t_out_drop_rate_cph`
- `sensor.envelope_delta_t_in_out_trend`
- `sensor.envelope_outdoor_cooling_window_state`
- `sensor.envelope_time_to_cool_window`
- `sensor.envelope_thermal_rebound_risk`

## Semantica minima delle entita`

### `sensor.envelope_<room>_rise_rate_cph`
- velocita` di salita della temperatura stanza
- unita`: `C/h`
- utile per capire se il sole sta caricando l'ambiente

### `sensor.envelope_<room>_delta_vs_outdoor_c`
- differenza tra stanza e temperatura esterna
- utile per capire se la stanza puo` scaricare calore

### `sensor.envelope_<room>_delta_vs_house_avg_c`
- differenza tra stanza e media casa
- utile per individuare stanze piu` esposte o piu` lente

### `sensor.envelope_<room>_solar_gain_score`
- score locale di guadagno solare utile/eccessivo
- non ancora booleano: deve restare graduato

### `sensor.envelope_<room>_overheating_risk`
- indice locale di rischio surriscaldamento
- base per la scelta della stanza peggiore

### `binary_sensor.envelope_<room>_shade_recommended`
- suggerimento locale di schermatura
- scatta quando la stanza e` gia` in zona di attenzione e continua a salire

### `binary_sensor.envelope_<room>_night_flush_candidate`
- indica se quella stanza puo` beneficiare di apertura in finestra serale/notturna

## KPI globali

### `sensor.envelope_worst_room_name`
- nome della stanza con rischio piu` alto nel momento corrente

### `sensor.envelope_worst_room_overheating_risk`
- valore del rischio massimo tra le stanze considerate

### `sensor.envelope_house_passive_gain_state`
Valori suggeriti:
- `useful`
- `neutral`
- `excess`
- `idle`

### `sensor.envelope_house_night_flush_potential`
Valori suggeriti:
- `high`
- `medium`
- `low`
- `none`

### `binary_sensor.envelope_house_ac_justified`
- `on` solo quando involucro e ventilazione naturale non bastano piu`

### `sensor.envelope_recommended_action`
Valori suggeriti:
- `let_sun_in`
- `prepare_shading`
- `shade_now`
- `prepare_night_flush`
- `open_for_night_flush`
- `keep_closed`
- `ac_justified`

## Regole di aggregazione iniziali
- La casa non deve mediare ciecamente le stanze.
- La decisione globale deve partire almeno da:
  - stanza peggiore
  - numero di stanze in attenzione
  - trend esterno
- Se una sola stanza e` molto esposta, il sistema deve poter dare consiglio locale senza trattarlo come problema dell'intera casa.

## Ordine di implementazione consigliato

### Fase 1. Derivate stanza
- rise rate per stanza
- delta stanza vs esterno
- delta stanza vs media casa

### Fase 2. Score locali
- solar gain score stanza
- overheating risk stanza
- shade recommended stanza

### Fase 3. Trend esterni
- rise/drop rate esterno
- stato finestra termica utile
- rischio rebound

### Fase 4. Aggregazione casa
- worst room
- recommended action
- AC justified

### Fase 5. Plancia dedicata
- vista involucro separata dalla plancia clima unificata
- header stato casa
- tabella stanza-per-stanza
- trend esterni e storico breve

## Vincoli progettuali
- Nessuna automazione attiva in questa fase.
- Le entita` devono essere osservabili e spiegabili prima di essere usate per attuazione.
- Le stanze devono restare comparabili tra loro: stessa semantica, naming uniforme, stessa scala dei punteggi quando possibile.

## Riferimenti
- [manuale_involucro_casa.md](manuale_involucro_casa.md)
- [plancia_involucro.md](plancia_involucro.md)
- [README_sensori_clima.md](README_sensori_clima.md)
- [regole_core_logiche.md](regole_core_logiche.md)
