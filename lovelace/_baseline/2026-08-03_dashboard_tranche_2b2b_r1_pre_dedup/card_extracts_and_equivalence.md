# Tranche 2B.2b-R1 — estratti e matrice pre-dedup

HEAD: `8a50458c63bd303e670fa75a17df9ef44b0a935c`

## Matrice di equivalenza

| ECLSS | Envelope | Entity ID | Tipo | Azioni / visibility / template / severity / soglie | Differenza | Esito |
|---|---|---|---|---|---|---|
| Stanza peggiore | Stanza peggiore | `sensor.envelope_worst_room_name` | tile | assenti in entrambe | nessuna | EQUIVALENTE |
| Rischio | Rischio peggiore | `sensor.envelope_worst_room_overheating_risk` | tile | nessuna azione, visibility, template, severity o soglia; ECLSS usa solo `color: red` | titolo e colore presentativi | EQUIVALENTE_CON_DIFFERENZE_PRESENTATIVE |
| Scuri consigliati | Scuri consigliati | `sensor.envelope_rooms_shade_recommended_count` | tile | assenti in entrambe | nessuna | EQUIVALENTE |
| Candidabili raffrescamento notturno | Candidabili raffrescamento notturno | `sensor.envelope_rooms_night_flush_candidate_count` | tile | assenti in entrambe | nessuna | EQUIVALENTE |
| Stanze schermate | Stanze | `sensor.envelope_shade_applied_rooms` | tile | assenti in entrambe | titolo presentativo; stessa lista di stanze | EQUIVALENTE_CON_DIFFERENZE_PRESENTATIVE |

L'ordine informativo differisce per collocazione: le prime quattro funzioni sono in `Sintesi`; la lista delle stanze schermate è in `Contesto`, accanto al KPI count. Non cambia la funzione delle card.

Il KPI distinto `sensor.envelope_shade_applied_rooms_count` è mantenuto e sarà visualizzato come `Numero stanze schermate`.

## Estratti ECLSS — cinque card di sintesi

```yaml
- type: tile
  entity: sensor.envelope_worst_room_name
  name: "Stanza peggiore"
- type: tile
  entity: sensor.envelope_worst_room_overheating_risk
  name: "Rischio"
  color: red
- type: tile
  entity: sensor.envelope_rooms_shade_recommended_count
  name: "Scuri consigliati"
- type: tile
  entity: sensor.envelope_rooms_night_flush_candidate_count
  name: "Candidabili raffrescamento notturno"
- type: tile
  entity: sensor.envelope_shade_applied_rooms
  name: "Stanze schermate"
```

## Estratti Envelope — equivalenti

```yaml
- type: tile
  entity: sensor.envelope_worst_room_name
  name: "Stanza peggiore"
- type: tile
  entity: sensor.envelope_worst_room_overheating_risk
  name: "Rischio peggiore"
- type: tile
  entity: sensor.envelope_rooms_shade_recommended_count
  name: "Scuri consigliati"
- type: tile
  entity: sensor.envelope_rooms_night_flush_candidate_count
  name: "Candidabili raffrescamento notturno"
- type: tile
  entity: sensor.envelope_shade_applied_rooms
  name: "Stanze"
```

## Estratti ECLSS — due trend

```yaml
- type: history-graph
  title: "Involucro 24h"
  hours_to_show: 24
  refresh_interval: 120
  entities:
    - entity: sensor.t_in_med
      name: "T interna"
    - entity: sensor.t_out
      name: "T esterna"
    - entity: sensor.envelope_giorno_rise_rate_cph
      name: "Giorno rise"
    - entity: sensor.envelope_notte1_rise_rate_cph
      name: "Notte1 rise"
    - entity: sensor.envelope_notte2_rise_rate_cph
      name: "Notte2 rise"
- type: history-graph
  title: "Solare e scuri 24h"
  hours_to_show: 24
  refresh_interval: 120
  entities:
    - entity: sensor.pv_power_now
      name: "PV proxy sole"
    - entity: sensor.envelope_house_night_flush_potential
      name: "Raffrescamento notturno"
    - entity: binary_sensor.close_shutters_recommended
      name: "Scuri"
    - entity: sensor.envelope_recommended_action
      name: "Azione tecnica"
    - entity: sensor.envelope_azione_consigliata
      name: "Azione"
```
