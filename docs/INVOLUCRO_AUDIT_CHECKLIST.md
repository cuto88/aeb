# Involucro Audit Checklist

## Objective

- validare il comportamento reale dell'involucro prima di stringere il monitoraggio solar gain;
- distinguere:
  - carico termico locale stanza
  - carico termico globale casa
  - scarico naturale utile
  - bisogno reale di schermatura o AC

## FACT

- il modello involucro esiste gia' in:
  - [manuale_involucro_casa.md](C:\2_OPS\aeb\docs\logic\core\manuale_involucro_casa.md)
  - [spec_involucro_room_model.md](C:\2_OPS\aeb\docs\logic\core\spec_involucro_room_model.md)
  - [envelope_involucro_plancia.yaml](C:\2_OPS\aeb\lovelace\envelope_involucro_plancia.yaml)

## Scope

- audit read-first
- nessuna automazione nuova
- nessuna modifica soglie durante la finestra di osservazione

## Runtime Windows

### 1. Morning Baseline

- casa chiusa
- sole basso o non ancora dominante
- impianti in stato noto

Goal:
- identificare baseline stanza-per-stanza
- verificare se esistono gia' differenze sistematiche tra stanze

### 2. Solar Loading Window

- fascia con ingresso sole utile o sospetto
- impianti termici/AC in stato noto
- finestre/scuri in stato noto

Goal:
- capire quali stanze anticipano la salita
- separare problema locale da media casa

### 3. Late Afternoon / Pre-Cooling

- casa potenzialmente carica
- esterno in possibile transizione

Goal:
- capire se l'involucro e' gia' troppo carico
- preparare decisione night flush vs keep closed

### 4. Night Flush Window

- esterno piu' fresco o in raffreddamento
- stato finestre noto

Goal:
- verificare se la casa scarica davvero
- distinguere "fuori migliore" da "fuori davvero utile"

## Required Entities

### Globali

- `sensor.t_in_med`
- `sensor.t_out`
- `sensor.ur_out`
- `sensor.pv_power_now`
- `binary_sensor.casa_chiusa`
- `switch.heating_master`
- `switch.ac_giorno`
- `switch.ac_notte`

### Stanze

- `sensor.t_in_giorno`
- `sensor.t_in_notte1`
- `sensor.t_in_notte2`
- `sensor.t_in_bagno`

### Involucro runtime

- `sensor.envelope_giorno_rise_rate_cph`
- `sensor.envelope_notte1_rise_rate_cph`
- `sensor.envelope_notte2_rise_rate_cph`
- `sensor.envelope_bagno_rise_rate_cph`
- `sensor.envelope_giorno_overheating_risk`
- `sensor.envelope_notte1_overheating_risk`
- `sensor.envelope_notte2_overheating_risk`
- `sensor.envelope_bagno_overheating_risk`
- `binary_sensor.envelope_giorno_shade_recommended`
- `binary_sensor.envelope_notte1_shade_recommended`
- `binary_sensor.envelope_notte2_shade_recommended`
- `binary_sensor.envelope_bagno_shade_recommended`
- `sensor.envelope_worst_room_name`
- `sensor.envelope_worst_room_overheating_risk`
- `sensor.envelope_house_passive_gain_state`
- `sensor.envelope_house_night_flush_potential`
- `sensor.envelope_recommended_action`

### Trend esterni

- `sensor.envelope_t_out_rise_rate_cph`
- `sensor.envelope_t_out_drop_rate_cph`
- `sensor.envelope_delta_t_in_out_trend`
- `sensor.envelope_outdoor_cooling_window_state`
- `sensor.envelope_time_to_cool_window`
- `sensor.envelope_thermal_rebound_risk`

## Validation Questions

### Room Priority

- quale stanza sale per prima?
- quale stanza sale di piu'?
- quale stanza resta piu' calda della media casa?

### Global Envelope Behavior

- la media casa nasconde un problema locale?
- il problema e' localizzato o sistemico?
- l'azione consigliata globale e' coerente con la stanza peggiore?

### External Cooling Usefulness

- fuori e' davvero utile o solo momentaneamente piu' basso?
- il trend esterno apre o chiude la finestra di raffrescamento?
- il sistema anticipa correttamente il rischio rebound?

### Solar Gain Separation

- la stanza calda sta salendo per sole, per inerzia accumulata o per impianto?
- il consiglio di schermatura arriva prima del superamento soglia, non dopo?

## Pass / Hold / Fail Criteria

### PASS

- `worst_room_name` coincide con la stanza fisicamente piu' critica
- `recommended_action` e' coerente con il contesto osservato
- i trend esterni non contraddicono l'azione suggerita
- le stanze reagiscono in modo leggibile e non casuale

### HOLD

- i segnali sono vivi ma non ancora abbastanza chiari
- una o piu' stanze richiedono soglie dedicate
- i trend esterni sembrano promettenti ma ancora instabili

### FAIL

- la media casa maschera sistematicamente la stanza peggiore
- l'azione consigliata e' in ritardo rispetto al comportamento reale
- il sistema confonde apporto impianto e comportamento passivo
- il night flush viene suggerito in una finestra esterna penalizzante

## Logging Minimum

Per ogni finestra audit annotare:

- timestamp inizio/fine
- stato finestre/scuri
- stato heating / AC
- meteo osservato
- stanza peggiore osservata
- azione che il sistema suggerisce
- esito reale percepito

## RISK

- bagno puo' essere rumoroso per usi transitori
- `t_in_med` puo' sembrare buona mentre una stanza e' gia' fuori banda
- senza finestre/scuri in stato noto il giudizio su night flush/shading degrada

## NEXT STEP

- usare questa checklist per 2-3 finestre reali prima di stringere il modello solar gain
- dopo il primo pass, aprire un audit dedicato solo su:
  - stanze sensibili
  - soglie di schermatura
  - finestra utile di night flush
