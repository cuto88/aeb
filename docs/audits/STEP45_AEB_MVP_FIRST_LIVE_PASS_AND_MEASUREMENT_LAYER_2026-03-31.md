# STEP45 AEB MVP first live pass and measurement layer (2026-03-31)

## Scope
- Consolidare il primo pass live conservativo riuscito di AEB MVP.
- Introdurre un layer minimo di misura/osservabilita` prima di qualunque espansione.
- Nessuna modifica a planner, multi-load o logiche AC.

## Runtime fact - first live pass
- readiness favorevole:
  - `binary_sensor.climateops_aeb_mvp_live_retry_ready = on`
  - `binary_sensor.climateops_heating_conflict_real = off`
  - `sensor.grid_direction = export`
  - `sensor.grid_power_w = -3616.15`
- pass live osservato:
  - `sensor.climateops_aeb_mvp_mode = dhw_boost_live`
  - `input_text.climateops_aeb_mvp_last_action = LIVE_REQUEST:action=boost|target_c=46.0|actual_c=45.0|reason=ok`
  - `input_text.climateops_dhw_write_result = LIVE_WRITE_SENT:hub=ehw_modbus|addr=1104|raw=153|target_c=46.0|expected_c=45.9`
  - `sensor.ehw_setpoint_raw_a = 153`
  - `sensor.ehw_setpoint_raw_calc = 153`
  - `sensor.ehw_setpoint = 45.9`
  - `sensor.climateops_dhw_actual_feedback = 45.9`
- restore safe posture riuscito:
  - `climateops_cutover_dhw = off`
  - `climateops_dhw_write_enable = off`
  - `climateops_dhw_dry_run = on`
  - `climateops_aeb_mvp_enable = off`
  - `climateops_aeb_mvp_dry_run = on`

## Measurement layer added
Patch minima in `packages/climateops_aeb_mvp.yaml`:
- `counter.climateops_aeb_mvp_live_requests_total`
- `counter.climateops_aeb_mvp_holds_total`
- `sensor.climateops_aeb_mvp_last_outcome`
- `sensor.climateops_aeb_mvp_target_actual_delta_c`

Support automations:
- incremento contatore live request quando `input_text.climateops_aeb_mvp_last_action` entra in `LIVE_REQUEST:*`
- incremento contatore hold quando `sensor.climateops_aeb_mvp_reason` entra in uno stato di blocco runtime mentre MVP e` abilitato

UI:
- blocco AEB nella plancia unificata aggiornato con:
  - `Last outcome`
  - `Target-actual delta`
  - `Live requests total`
  - `Holds total`

## Why this is enough for now
- rende misurabile il comportamento reale MVP senza cambiare l'autorita` di dispatch
- consente una breve observation phase su:
  - frequenza live request
  - frequenza hold
  - coerenza target vs actual
- mantiene perimetro stretto e reversibile

## Out of scope kept out
- nessuna espansione AC
- nessun planner actuation
- nessun multi-load dispatch
- nessun redesign ClimateOps
