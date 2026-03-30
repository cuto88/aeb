# STEP44 Forecast Runtime Closure (2026-03-30)

Date: 2026-03-30  
Scope: chiusura definitiva debito tecnico forecast AEB/ClimateOps.

## Problema osservato

Il layer policy forecast risultava in fallback:
- `binary_sensor.policy_forecast_inputs_ready = off`
- `sensor.policy_forecast_reason = UNAVAILABLE_FAILSAFE`

Cause principali:
- helper forecast puntati a entity id legacy non piu` pubblicati a runtime
- package ventilazione ancora dipendente da `weather.forecast_home`
- assenza di una UI attiva che rendesse evidente il problema

## Root cause consolidata

Authority runtime al 2026-03-30:
- forecast meteo orario: `weather.forecast_casa` (`met`)
- forecast FV disponibile: `sensor.energy_next_hour` (`forecast_solar`)
- `sensor.power_production_next_hour` presente ma `disabled_by: integration`

Entity id legacy/non affidabili nel runtime corrente:
- `sensor.pv_forecast_power_next_hour` non pubblicato upstream
- `sensor.weather_forecast_temperature_1h` non pubblicato upstream
- `weather.forecast_home` assente

## Fix applicati

- Aggiunta vista `AEB` nella dashboard attiva `lovelace/climate_casa_unified_plancia.yaml`
- Aggiunto `packages/climate_forecast_bridge.yaml`
- Corretto `packages/stub_ventilation_meteo.yaml` da `weather.forecast_home` a `weather.forecast_casa`
- Rafforzato `packages/climate_policy_energy.yaml` con candidatura esplicita di `sensor.power_production_next_hour`
- Aggiornata SOT in `docs/logic/core/README_sensori_clima.md`

## Contratto finale

Alias canonici consumati dal policy layer:
- `sensor.pv_forecast_power_next_hour`
- `sensor.weather_forecast_temperature_1h`

Authority bridge:
- PV: `sensor.power_production_next_hour` se disponibile, altrimenti `sensor.energy_next_hour` convertito in W
- Temperatura: `weather.forecast_casa` via `weather.get_forecasts` hourly

Fail-safe definitivo bridge PV:
- se l'upstream `forecast_solar` non ha ancora pubblicato stato dopo bootstrap/restart,
  il bridge pubblica `0 W` e marca `sensor.forecast_bridge_pv_source = fallback_zero_unavailable`
- obiettivo: evitare `unknown` nel policy layer e mantenere explainability esplicita

Explainability bridge:
- `sensor.forecast_bridge_pv_source`
- `sensor.forecast_bridge_temp_source`

## Verifica runtime post-fix

Esito confermato dopo deploy e restart Core:
- `binary_sensor.policy_forecast_inputs_ready = on`
- `sensor.policy_forecast_pv_next_hour_w = 3.0`
- `sensor.policy_forecast_temp_next_hour_c = 12.2`
- `sensor.policy_forecast_reason = READY_PV_AND_TEMP_PVNEXT_LOW`

## Esito

Forecast AEB riportato in stato operativo e osservabile da UI, con bridge esplicito e documentato.
