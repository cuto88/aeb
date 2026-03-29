# Runtime Hardware Profiles

## Stato corrente

Dal `2026-03-29` i transport `Modbus` di `Mirai` ed `EHW` sono esclusi dal
caricamento standard di Home Assistant per evitare bootstrap lenti quando
l'hardware non e` presente o non raggiungibile.

File esclusi dal runtime normale:
- `ops/disabled_runtime/mirai_modbus.transport.yaml`
- `ops/disabled_runtime/ehw_modbus.transport.yaml`

Restano invece attivi i package logici/template che tollerano sensori raw
assenti tramite `availability` o fallback.

## Come riattivare

1. Copiare il transport richiesto dentro `packages/`:
   - `ops/disabled_runtime/mirai_modbus.transport.yaml` -> `packages/mirai_modbus.yaml`
   - `ops/disabled_runtime/ehw_modbus.transport.yaml` -> blocco `modbus:` in `packages/ehw_modbus.yaml`
2. Eseguire `ha core check`
3. Riavviare Home Assistant

## Sensori TEMP ESP32/LDR

I sensori LDR/ESP32 dei termostati TEMP risultano smontati. I binding default
degli `input_text.climateops_temp_thermostat_*` sono lasciati vuoti per evitare
dipendenze runtime inutili. Quando l'hardware tornera` disponibile, reimpostare
manualmente gli `entity_id` in plancia heating.
