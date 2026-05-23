# STEP6 Thermostat TEMP LDR threshold remap (2026-02-25)

## Obiettivo
Correggere la lettura dei termostati ESP32 basati su LDR (`thermostat_giorno_temp`, `thermostat_notte_temp`) che potevano risultare ON/OFF invertiti o instabili vicino alla soglia.

## Root cause
Il mapping TEMP usava principalmente una sorgente binaria (`binary_sensor.*_richiesta_calore`), mentre i sensori reali sono analogici (Volt da LDR) e possono oscillare vicino al punto di commutazione.

## Fix applicato
File principale:
- `packages/climateops/overrides/thermostat_indicators_temp.yaml`

Modifiche:
- aggiunti sorgenti raw configurabili:
  - `input_text.climateops_temp_thermostat_giorno_raw_entity`
  - `input_text.climateops_temp_thermostat_notte_raw_entity`
- aggiunti helper di tuning:
  - `input_number.climateops_temp_thermostat_giorno_threshold_v` (default `3.00`)
  - `input_number.climateops_temp_thermostat_notte_threshold_v` (default `3.00`)
  - `input_number.climateops_temp_thermostat_hysteresis_v` (default `0.10`)
- aggiornata logica template:
  - ON sopra soglia, OFF sotto soglia, con isteresi simmetrica;
  - fallback a sorgente binaria legacy se `ldr_raw` non disponibile.

## Aggiornamenti plancia
File:
- `lovelace/03_heating_loop.yaml`

Aggiunti controlli in sezione "Termostati (stato reale)":
- entity raw camera1/camera2 (`input_text.*_raw_entity`)
- soglia Volt camera1/camera2
- isteresi Volt globale

## Documentazione aggiornata
- `docs/logic/heating/plancia.md`
- `docs/logic/heating/README.md`
- `docs/logic/core/README_sensori_clima.md`

## Note operative
- Target iniziale consigliato: soglia circa `3.00V`.
- Se presente flicker vicino soglia: aumentare `input_number.climateops_temp_thermostat_hysteresis_v` (es. `0.15-0.20V`).
- Verificare in runtime correlando:
  - `sensor.ldr_*_ldr_raw`
  - `binary_sensor.thermostat_*_temp`
  - stato reale termostato locale.
