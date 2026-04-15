# STEP54 Involucro Last 7d Runtime Audit (2026-04-15)

## Scope
- Audit read-only del comportamento involucro sugli ultimi 7 giorni osservabili (`2026-04-08` -> `2026-04-15`).
- Focus:
  - media casa vs stanza peggiore
  - segnali di surriscaldamento locale
  - coerenza del fronte `night flush`
  - priorita` operativa tra audit involucro e solar gain

## Sources used
- History API Home Assistant read-only su:
  - `sensor.t_in_med`
  - `sensor.t_out_effective`
  - `sensor.t_in_giorno`
  - `sensor.t_in_notte1`
  - `sensor.t_in_notte2`
  - `sensor.t_in_bagno`
  - `sensor.envelope_worst_room_name`
  - `sensor.envelope_recommended_action`
  - `sensor.envelope_house_night_flush_potential`
  - `sensor.envelope_house_passive_gain_state`
  - `switch.heating_master`
  - `switch.ac_giorno`
  - `switch.ac_notte`
- Snapshot locale:
  - `docs/runtime_evidence/2026-04-10/involucro_audit_snapshot_night_flush_20260410_211049.md`
- Verifica fallback esterno:
  - `docs/runtime_evidence/2026-04-10/t_out_fallback_postdeploy_20260410_2014.md`

## FACT

### 1. La media casa resta moderata, ma non rappresenta bene la stanza peggiore
- `sensor.t_in_med` ha mostrato range giornalieri moderati:
  - `2026-04-08`: `21.98 -> 23.27`
  - `2026-04-09`: `22.12 -> 22.80`
  - `2026-04-10`: `21.77 -> 22.70`
  - `2026-04-11`: `21.60 -> 23.85`
  - `2026-04-12`: `22.05 -> 22.80`
  - `2026-04-13`: `21.82 -> 22.12`
  - `2026-04-14`: `21.73 -> 22.98`
  - `2026-04-15`: `21.75 -> 23.05`
- Il picco medio piu` alto del periodo e` `23.85` il `2026-04-11`.
- La media casa non racconta da sola il vero punto di stress termico stanza-per-stanza.

### 2. `notte2` e` la stanza peggiore dominante della settimana
- Distribuzione `sensor.envelope_worst_room_name` sull’intera finestra:
  - `notte2 = 89`
  - `bagno = 48`
  - `giorno = 40`
  - `notte1 = 33`
- Dominanza giornaliera:
  - `2026-04-08`: `notte2=14`
  - `2026-04-09`: `notte2=10`
  - `2026-04-10`: `notte2=11`
  - `2026-04-11`: `notte2=15`
  - `2026-04-12`: `notte2=12`
  - `2026-04-13`: `notte2=11`
  - `2026-04-15`: `notte2=11`
- Solo il `2026-04-14` `bagno` supera `notte2`.

### 3. `notte2` ha mostrato ripetutamente valori sopra il resto casa
- `sensor.t_in_notte2`:
  - `2026-04-08`: `22.10 -> 24.50`
  - `2026-04-09`: `22.20 -> 24.20`
  - `2026-04-10`: `21.80 -> 24.40`
  - `2026-04-11`: `21.60 -> 23.50`
  - `2026-04-12`: `22.30 -> 22.70`
  - `2026-04-13`: `22.20 -> 22.40`
  - `2026-04-14`: `22.10 -> 22.30`
  - `2026-04-15`: `22.10 -> 23.60`
- Questo pattern e` coerente con un hotspot locale stabile e non con sola variabilita` casuale.

### 4. `bagno` e` un secondo hotspot reale, non solo rumore
- `sensor.t_in_bagno`:
  - `2026-04-09`: max `24.10`
  - `2026-04-11`: max `25.60`
  - `2026-04-12`: max `24.80`
  - `2026-04-14`: max `25.90`
- Anche se il bagno puo` avere rumore da uso transitorio, le punte osservate sono troppo forti per essere ignorate come semplice disturbo.

### 5. Le azioni consigliate del sistema non sono bloccate su una sola postura
- Distribuzione `sensor.envelope_recommended_action`:
  - `keep_closed = 93`
  - `prepare_night_flush = 93`
  - `open_for_night_flush = 61`
- Distribuzione `sensor.envelope_house_night_flush_potential`:
  - `low = 93`
  - `none = 92`
  - `high = 61`
  - `medium = 7`
- Questo indica che il fronte involucro distingue piu` posture operative reali e non ripete una raccomandazione unica per tutta la settimana.

### 6. Lo snapshot del `2026-04-10` conferma la lettura stanza-peggiore
Dal file `involucro_audit_snapshot_night_flush_20260410_211049.md`:
- `sensor.t_in_med = 22.57`
- `sensor.t_out_effective = 16.8`
- `sensor.envelope_worst_room_name = notte2`
- `sensor.envelope_worst_room_overheating_risk = 50`
- `sensor.envelope_house_night_flush_potential = low`
- `sensor.envelope_recommended_action = prepare_night_flush`
- stanza `notte2 = 24.0`
- `sensor.t_out_effective.source = sensor.t_out`
- `sensor.t_out_effective.stale_flag = off`

### 7. Il fronte AC non e` informativo in questa finestra
- `switch.ac_giorno` e `switch.ac_notte` risultano sostanzialmente `unknown` nello storico osservato.
- L’analisi della settimana va quindi letta soprattutto come comportamento involucro + meteo + possibile interferenza heating, non come casa attivamente raffrescata.

## RISKS
- `t_in_med` puo` indurre una falsa sensazione di stabilita` mentre una stanza e` gia` in deriva termica.
- `notte2` rischia di restare sottovalutata se il criterio decisionale resta troppo centrato sulla media casa.
- `bagno` rischia la sottovalutazione opposta: puo` sembrare rumore transitorio quando in realta` contribuisce a picchi rilevanti.
- Senza traccia affidabile di finestre/scuri reali, la validazione del `night flush` resta parziale: il modello puo` essere coerente senza che l’effetto fisico sia ancora provato abbastanza.
- Il filone `solar gain` rischia soglie premature se si salta la chiusura del comportamento involucro stanza-per-stanza.

## DRIFT
- Nessun drift forte tra la teoria del modello involucro e la lettura runtime di questa settimana.
- Drift ancora presente tra:
  - disponibilita` di segnali involucro
  - disponibilita` di evidenza operatore su finestre/scuri/azioni umane reali
- Drift anche sul fronte AC:
  - gli switch AC non forniscono una base affidabile di interpretazione nella finestra osservata.

## JUDGEMENT

### Involucro room model
- `PASS / credible`
- Motivo:
  - il modello intercetta una stanza peggiore coerente e ripetuta
  - il problema osservato e` locale, non genericamente “media casa alta”

### Worst-room identification
- `PASS`
- Motivo:
  - `notte2` emerge con continuita`
  - `bagno` emerge come secondo hotspot reale

### Night flush advisory
- `PARTIAL / promising`
- Motivo:
  - il sistema differenzia `none`, `low`, `high`
  - le azioni consigliate (`keep_closed`, `prepare_night_flush`, `open_for_night_flush`) cambiano in modo plausibile
  - manca pero` ancora una chiusura forte su effetto fisico osservato con stato finestre reale ben annotato

### Solar gain readiness
- `HOLD`
- Motivo:
  - la settimana conferma che il vero problema resta ancora l’involucro stanza-per-stanza
  - non e` ancora prudente trattare `solar gain` come decision-grade o automation-grade

## PRIORITY
- `HIGH`
- Non per emergenza runtime, ma perche' il prossimo passo corretto va scelto bene:
  - consolidare involucro
  - non anticipare troppo solar gain

## NEXT ACTION
1. Aprire un mini-ciclo audit dedicato su `notte2` come stanza sentinella primaria.
2. Aprire un sotto-audit su `bagno` per distinguere picco locale reale vs uso transitorio.
3. Raccogliere 2-4 finestre con annotazione umana esplicita di:
   - finestre
   - scuri/schermature
   - heating / AC reali
   - azione umana realmente eseguita
   - esito dopo 30-60 minuti
4. Rinviare qualunque chiusura `solar gain` fino a quando il comportamento involucro e la finestra utile di `night flush` non risultano piu` difendibili.

## Conclusion
- Negli ultimi 7 giorni il comportamento involucro osservato e` compatibile con una casa che non soffre ancora di surriscaldamento medio-casa severo, ma che presenta hotspot locali chiari.
- `notte2` e` il principale punto debole dell’involucro nel periodo osservato.
- `bagno` va trattato come secondo punto critico, non come rumore da scartare a priori.
- Il modello involucro sta aiutando piu` del semplice `t_in_med`.
- Il fronte corretto oggi non e` “chiudere solar gain”, ma “chiudere meglio il comportamento involucro stanza-per-stanza”.
