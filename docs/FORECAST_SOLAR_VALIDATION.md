# Mercurio — Forecast.Solar validated configuration

**Status:** DONE_VERIFIED  
**Scope:** Home Assistant `forecast_solar` integration for Casa Mercurio PV forecast  
**Validation date:** 2026-08-20  
**Runtime:** `mercurio-edge` / container `homeassistant`

## 1. Validated plant parameters

The active Forecast.Solar configuration for `Casa` is validated with:

- latitude: `45.6533706`
- longitude: `12.2959606`
- Home Assistant azimuth: `255°`
- roof tilt / declination: `17°`
- total module peak power stored by the HA UI: `6000 W`
- effective API peak power: `6.0 kWp`

Physical PV evidence used for the power value:

- inverter: SolarEdge `SE6000H-RW000BNN4`, nominal `6.0 kW AC`
- modules: 15 × SunPower `SPR-MAX3-400`
- module field: `15 × 400 Wp = 6000 Wp = 6.0 kWp DC`

## 2. Home Assistant to Forecast.Solar conversions

Home Assistant stores the azimuth using the geographic convention:

- `0° = North`
- `90° = East`
- `180° = South`
- `270° = West`

The Forecast.Solar coordinator converts the stored azimuth before the API request:

`api_azimuth = ha_azimuth - 180`

Therefore:

`255° HA -> 75° Forecast.Solar API`

The module peak power field is stored in **watts**, while the coordinator converts it to kWp:

`api_kwp = modules_power / 1000`

Therefore the correct stored value is:

`6000 W -> 6.0 kWp API`

Do not store `6` in `modules_power`: this is interpreted as `6 W` and becomes `0.006 kWp` at the API boundary.

## 3. Root cause of the forecast anomaly

The integration originally had `modules_power = 6`.

The coordinator correctly converted this value as:

`6 / 1000 = 0.006 kWp`

This caused Forecast.Solar values approximately 1000 times too low, including values around:

- power now: `1-2 W`
- today energy: about `0.014 kWh`
- tomorrow energy: about `0.010 kWh`

The upstream Forecast.Solar API was not the root cause. A direct request using the physical plant values returned plausible results.

## 4. Post-fix validation evidence

After correcting only `modules_power` from `6` to `6000 W`, the effective coordinator request became `6.0 kWp`.

Validation samples on 2026-08-20:

| Metric | Home Assistant | Direct Forecast.Solar API | Difference |
| --- | ---: | ---: | ---: |
| Current power | 891 W | 901 W | -1.1% |
| Energy today | 11.630 kWh | 12.616 kWh | -7.8% |
| Energy tomorrow | 9.007 kWh | 9.104 kWh | -1.1% |

The current power and next-day forecast are effectively aligned. The remaining difference for today's accumulated estimate is compatible with different refresh/snapshot times and no longer shows the previous ×1000 scale error.

Direct API request used for validation:

`/estimate/45.6533706/12.2959606/17/75/6.0`

The API returned HTTP `200`, `success`, timezone `Europe/Rome`, and a location approximately 8 m from the configured coordinates.

## 5. Forecast.Solar entities retained in Home Assistant

The integration exposes the forecast entities under the existing entity IDs, including:

- `sensor.power_production_now`
- `sensor.energy_current_hour`
- `sensor.energy_next_hour`
- `sensor.energy_production_today`
- `sensor.energy_production_today_remaining`
- `sensor.energy_production_tomorrow`
- `sensor.power_highest_peak_time_today`
- `sensor.power_highest_peak_time_tomorrow`

The optional +1 h / +12 h / +24 h power forecast entities may remain disabled by default according to the official integration behavior.

## 6. Operational decision

Forecast.Solar configuration is considered **validated** for use as a predictive input.

Canonical configuration values:

`45.6533706 / 12.2959606 / HA azimuth 255° / tilt 17° / modules_power 6000 W`

Equivalent Forecast.Solar API plane:

`17 / 75 / 6.0`

Future automations must consume the validated forecast entities without changing these plant parameters unless new physical evidence shows that the PV array geometry or installed module power has changed.

## 7. Provenance

- operational workstation: Codex workstation
- runtime target: `mercurio-edge`, Home Assistant container `homeassistant`
- access used during validation: Home Assistant authenticated UI, LAN/SSH, Tailscale, direct Forecast.Solar API, SolarEdge authenticated browser session
- legacy runtime: not contacted
- file deploy to HA runtime: no
- runtime modification: yes, limited to Forecast.Solar configuration options
- repository publication: this document records the validated result in the AEB technical SSOT
