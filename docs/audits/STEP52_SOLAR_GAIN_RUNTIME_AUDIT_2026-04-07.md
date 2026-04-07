# STEP52 Solar gain runtime audit (2026-04-07)

## Scope
- Auditare il comportamento reale del modulo advisory `solar_gain` nella giornata di martedi` 2026-04-07.
- Verificare se oggi sia stato osservato un guadagno solare utile.
- Identificare eventuali blocker runtime che invalidano la lettura advisory.

## Evidence source
- Runtime recorder copiato in sola lettura da:
  - `/homeassistant/home-assistant_v2.db`
  - `/homeassistant/home-assistant_v2.db-wal`
  - `/homeassistant/home-assistant_v2.db-shm`
- Copia locale di audit:
  - `tmp/audit_2026-04-07/`
- Finestra analizzata:
  - locale Europe/Rome `2026-04-07 00:00:00 -> 2026-04-07 23:59:59`
  - UTC `2026-04-06 22:00:00 -> 2026-04-07 21:59:59`

## Findings

### 1. Sole reale presente e intenso
- `sensor.pv_power_now` ha superato la soglia advisory `1200 W` dalle `10:45` alle `18:15`.
- Picco giornaliero PV: `3718.28 W` alle `14:15`.
- Quadro: giornata effettivamente utile per un audit solar-gain.

### 2. Risposta termica indoor coerente con guadagno passivo
- `sensor.t_in_med` minimo: `21.35 C` alle `07:50`.
- `sensor.t_in_med` massimo: `23.50 C` alle `18:22`.
- Delta indoor giornata: `+2.15 C`.
- Nella fascia di sole forte:
  - `12:00` -> `t_in_med 21.68 C`
  - `16:00` -> `t_in_med 22.83 C`
  - `18:00` -> `t_in_med 23.27 C`
- Interpretazione: oggi c'e` stato un guadagno passivo reale e misurabile.

### 3. Heating non spiega il riscaldamento principale diurno
- `switch.heating_master` risulta `on` solo dalle `17:00` alle `17:31` circa (`0.511 h` totali).
- L'aumento indoor era gia` in corso molto prima dell'accensione heating.
- Interpretazione: il grosso del rise diurno non e` attribuibile al riscaldamento attivo.

### 4. Il modulo advisory non ha osservato correttamente la giornata
- `sensor.solar_gain_overheating_reason` e` rimasto `inputs_not_ready` per tutta la giornata analizzata.
- `binary_sensor.solar_gain_advisory_inputs_ready` compare solo alle `19:07` come `unknown` e alle `19:08` come `off`.
- `sensor.solar_gain_passive_index` compare solo alle `19:07/19:08` e resta a `0`.
- `binary_sensor.solar_gain_passive_candidate` compare una sola volta alle `19:07` direttamente `off`.
- `binary_sensor.close_shutters_recommended` compare una sola volta alle `19:07` direttamente `off`.
- `sensor.solar_gain_passive_candidate_hours_today = 0.0`
- `sensor.close_shutters_recommended_hours_today = 0.0`

### 5. Root cause runtime piu` probabile
- `binary_sensor.windows_all_closed` non ha alcuna `states_meta` nel recorder analizzato.
- `switch.ac_giorno` e `switch.ac_notte` compaiono alle `19:07` direttamente come `unknown`.
- Il template `solar_gain_advisory_inputs_ready` dipende esplicitamente da:
  - `binary_sensor.windows_all_closed`
  - `switch.ac_giorno`
  - `switch.ac_notte`
- Con questi input mancanti/unknown, il modulo resta strutturalmente in `inputs_not_ready`.

## Conclusion
- **Guadagno solare reale oggi: SI**
- **Modulo advisory utilizzabile oggi come evidenza operativa: NO**

Il giorno 2026-04-07 mostra una firma coerente con guadagno passivo:
- sole forte e prolungato
- indoor in salita di oltre `2 C`
- heating quasi assente nella fase principale di accumulo

Ma il pacchetto `solar_gain_advisory` non puo` essere considerato calibrato/operativo, perche' oggi non ha avuto input runtime validi abbastanza per classificare la giornata.

## Minimal corrective actions
1. Ripristinare o riallineare l'input finestra usato dal modulo:
   - `binary_sensor.windows_all_closed`
   - in alternativa, aggiornare il package verso l'entita` reale disponibile.
2. Ripristinare gli entity AC attesi dal modulo oppure cambiare il package verso gli entity proxy effettivamente stabili.
3. Dopo il fix, rieseguire audit su una nuova giornata soleggiata prima di qualsiasi automazione su `cover`.

## Package references
- `packages/solar_gain_advisory.yaml`
- current operator view: `lovelace/climate_casa_unified_plancia.yaml` (`Passive House`)
- historical note: the first standalone Solar Gain dashboard was later removed after consolidation into `Passive House`
- `docs/audits/STEP48_SOLAR_GAIN_ADVISORY_SCAFFOLD_2026-04-06.md`
