# Plancia Involucro Casa

Spec funzionale iniziale della plancia dedicata al comportamento termico passivo della casa.

## Scopo
- Rendere leggibile in un solo punto cosa sta succedendo stanza per stanza.
- Separare i consigli su involucro / finestre / ombreggiamento dai moduli HVAC classici.
- Dare supporto a decisioni umane prima di eventuali automazioni.

## Obiettivi della plancia
- Mostrare se il sole e` ancora utile o sta diventando eccessivo.
- Evidenziare la stanza peggiore e le stanze che stanno salendo piu` rapidamente.
- Rendere chiaro se conviene:
  - lasciare entrare il sole
  - chiudere scuri
  - aprire per night flush
  - tenere tutto chiuso
  - considerare AC come ultima misura

## Struttura consigliata

### 1. Header stato casa
Card sintetica con:
- `sensor.envelope_recommended_action`
- `sensor.envelope_house_passive_gain_state`
- `sensor.envelope_house_night_flush_potential`
- `binary_sensor.envelope_house_ac_justified`
- `sensor.envelope_worst_room_name`
- `sensor.envelope_worst_room_overheating_risk`

Questa sezione deve rispondere subito alla domanda:
- "Qual e` l'azione giusta adesso?"

### 2. Contesto esterno
Card trend con:
- `sensor.t_out`
- `sensor.ur_out`
- `sensor.envelope_t_out_rise_rate_cph`
- `sensor.envelope_t_out_drop_rate_cph`
- `sensor.envelope_outdoor_cooling_window_state`
- `sensor.envelope_time_to_cool_window`
- `sensor.envelope_thermal_rebound_risk`
- `sensor.pv_power_now`

Questa sezione serve a distinguere:
- esterno favorevole adesso
- esterno che sta migliorando
- esterno che sembra buono ma rischia rebound

### 3. Tabella stanze
Una card per ogni stanza Fase 1:
- `giorno`
- `notte1`
- `notte2`
- `bagno`

Ogni riga/card stanza dovrebbe esporre:
- temperatura corrente
- rise rate
- delta vs esterno
- delta vs media casa
- solar gain score
- overheating risk
- shade recommended
- night flush candidate
- stato finestre stanza o gruppo stanza

### 4. Sezione azioni consigliate
Lista operativa leggibile, non solo sensori grezzi.

Esempi di messaggi desiderati:
- `Lascia entrare sole in zona giorno`
- `Prepara schermatura zona giorno`
- `Chiudi scuri in zona notte1`
- `Apri finestre notte per scarico termico`
- `Tieni chiuso: esterno ancora penalizzante`
- `AC giustificata solo se comfort non recuperabile`

### 5. Storico breve
Trend 6h / 12h di:
- temperatura esterna
- media casa
- stanze principali
- rise rate stanza peggiore
- PV power

Questa parte serve a validare se il consiglio attuale e` coerente con la dinamica, non solo con l'istantanea.

## Principi UX
- Prima il consiglio, poi i dettagli.
- Distinguere bene `problema locale` da `problema casa`.
- Usare colori prudenziali:
  - neutro per stato utile
  - ambra per attenzione
  - rosso per eccesso / surriscaldamento
  - azzurro per finestra night flush favorevole
- Evitare una plancia troppo tecnica per l'uso quotidiano: servono messaggi chiari e motivati.

## Relazione con le altre plance
- Non deve duplicare la plancia clima unificata.
- Deve essere dedicata a involucro, guadagno solare, ombreggiamento e ventilazione passiva.
- Puo` poi essere linkata dalla plancia clima unificata come vista specializzata.

## Fasi consigliate

### Fase 1
- header stato casa
- contesto esterno
- tabella stanze

### Fase 2
- messaggi operativi piu` leggibili
- storico breve
- evidenza stanza peggiore / stanze critiche

### Fase 3
- supporto stagionale
- differenza tra scenario giorno / sera / notte
- eventuale sezione "perche'" del consiglio

## Riferimenti
- [manuale_involucro_casa.md](manuale_involucro_casa.md)
- [spec_involucro_room_model.md](spec_involucro_room_model.md)
