# Manuale Involucro Casa

Documento operativo per modellare come la casa reagisce a sole, ombreggiamento, finestre e raffrescamento attivo.

## Scopo
- Distinguere `guadagno solare utile` da `guadagno solare eccessivo`.
- Decidere quando conviene:
  - lasciare entrare il sole
  - schermare / chiudere scuri
  - aprire finestre per night flush
  - mantenere la casa chiusa
  - ricorrere ad AC
- Costruire un manuale pratico dell'involucro prima di eventuali automazioni.

## Obiettivo comfort iniziale
- Fascia comfort operativa consigliata: `23.5 - 24.5 C`
- Soglia attenzione: `24.5 C`
- Soglia surriscaldamento da evitare: `25.5 C`

Nota:
- queste soglie sono iniziali e vanno tarate stanza per stanza;
- il criterio non e` solo temperatura assoluta, ma `temperatura + velocita` di salita + contesto esterno`.

## Livelli di analisi

### 1. Livello stanza
Ogni stanza deve poter rispondere a quattro domande:
- il sole sta dando un guadagno utile?
- la stanza sta andando verso surriscaldamento?
- conviene schermare?
- conviene aprire per raffrescare quando fuori migliora?

### 2. Livello casa
La casa aggrega la situazione delle stanze e risponde a:
- qual e` la stanza peggiore?
- il problema e` locale o sistemico?
- conviene un'azione fisica locale o globale?
- l'AC e` davvero giustificata?

## Sensori di base

### Globali
- `sensor.t_out`
- `sensor.ur_out`
- `sensor.pv_power_now`
- `sensor.t_in_med`
- `binary_sensor.casa_chiusa`
- `switch.heating_master`
- `switch.ac_giorno`
- `switch.ac_notte`

### Per stanza
- `sensor.t_in_giorno`
- `sensor.t_in_notte1`
- `sensor.t_in_notte2`
- `sensor.t_in_bagno`

### Aperture / contesto locale
- `binary_sensor.windows_giorno_any`
- `binary_sensor.windows_notte_any`
- `binary_sensor.windows_bagno_any`
- eventuali entita` piu` granulari stanza-per-stanza quando disponibili

## KPI da costruire

### KPI locali per stanza
Per ogni stanza `giorno`, `notte1`, `notte2`, `bagno`:
- `room_temp_c`
- `room_rise_rate_cph`
- `room_delta_vs_outdoor_c`
- `room_delta_vs_house_avg_c`
- `room_solar_gain_useful`
- `room_overheating_risk`
- `room_shade_recommended`
- `room_night_flush_candidate`

Naming suggerito:
- `sensor.room_giorno_rise_rate_cph`
- `sensor.room_notte1_rise_rate_cph`
- `sensor.room_notte2_rise_rate_cph`
- `sensor.room_bagno_rise_rate_cph`
- `sensor.room_giorno_overheating_risk`
- `binary_sensor.room_giorno_shade_recommended`

### KPI globali casa
- `worst_room_overheating_risk`
- `worst_room_name`
- `house_passive_gain_state`
- `house_night_flush_potential`
- `house_ac_justified`
- `recommended_envelope_action`

## Stati decisionali da raggiungere

### Guardo il sole come utile
Condizioni tipiche:
- temperatura stanza sotto comfort alto
- salita lenta o moderata
- esterno non utile al raffrescamento immediato
- nessun segnale di eccesso

Azione:
- lasciare entrare il sole

### Guardo il sole come eccessivo
Condizioni tipiche:
- stanza gia` vicina o sopra `24.5 C`
- salita termica rapida
- sole forte/prolungato
- esterno non abbastanza fresco da scaricare

Azione:
- schermare / chiudere scuri

### Night flush utile
Condizioni tipiche:
- casa carica di calore nel tardo pomeriggio/sera
- esterno sensibilmente piu` fresco
- umidita` esterna accettabile
- niente pioggia / vento eccessivo / condizioni sfavorevoli

Azione:
- aprire finestre selettivamente

### AC giustificata
Condizioni tipiche:
- stanze sopra comfort
- sole non piu` gestibile con schermatura
- night flush non disponibile o insufficiente
- inerzia dell'involucro gia` troppo carica

Azione:
- AC come ultima misura

## Matrice decisionale iniziale

| Stato edificio | Segnale dominante | Azione consigliata |
| --- | --- | --- |
| Sole utile, casa ancora fresca | stanza < `24.5 C`, salita moderata | lasciare entrare il sole |
| Sole forte, stanza in salita rapida | stanza >= `24.5 C`, rise rate elevato | chiudere scuri / schermare |
| Casa calda ma sera favorevole | esterno piu` fresco, casa chiusa, umidita` ok | aprire per night flush |
| Casa calda e fuori non aiuta | esterno non abbastanza favorevole | tenere chiuso e limitare apporti |
| Comfort gia` perso | stanza/e oltre soglia alta e senza scarico utile | AC giustificata |

## Strategia di raccolta misure

### Fase 1. Identificare le stanze sensibili
- confrontare quali stanze salgono prima e di piu`
- verificare quali stanze mantengono piu` a lungo il calore
- usare `t_in_med` solo come sintesi, non come unica verita`

### Fase 2. Relazione sole -> temperatura
- correlare `pv_power_now` con velocita` di salita delle singole stanze
- osservare finestre temporali senza heating e senza AC
- distinguere stanze con carico solare diretto da quelle neutre

### Fase 3. Relazione sera/notte -> scarico termico
- misurare quali stanze scendono davvero con finestre aperte
- confrontare casa chiusa vs night flush
- capire quanto margine si recupera prima della mattina successiva

## Regole operative iniziali
- Non usare la media casa per decidere schermatura locale se una stanza e` chiaramente piu` esposta.
- La prima soglia utile per azione preventiva e` `24.5 C`, non `25.5 C`.
- La soglia `25.5 C` va trattata come limite da non inseguire in ritardo.
- L'AC non deve essere il primo correttivo del sole: prima involucro, poi ventilazione, poi AC.

## Deliverable futuri
- KPI stanza-per-stanza in runtime
- indice globale casa
- tabella stagionale primavera / estate / mezza stagione
- manuale operativo sintetico per uso umano
- eventuale automazione prudente solo dopo calibrazione

## Riferimenti
- [README_sensori_clima.md](README_sensori_clima.md)
- [regole_core_logiche.md](regole_core_logiche.md)
- [README_ClimaSystem.md](../../../README_ClimaSystem.md)
