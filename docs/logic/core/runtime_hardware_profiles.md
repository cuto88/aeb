# Runtime Hardware Profiles

## Stato corrente

Dal `2026-03-29` i transport `Modbus` di `Mirai` ed `EHW` sono esclusi dal
caricamento standard di Home Assistant per evitare bootstrap lenti quando
l'hardware non e` presente o non raggiungibile.

Nota di campo `2026-03-30`:
- il bus RS-485 condiviso `MIRAI + SDM120` e` attestato sul path TCP `192.168.178.191:502`
- parametri seriali operativi condivisi: `9600 8E1`
- indirizzi validati:
  - `MIRAI` -> `slave 1`
  - `SDM120` -> `slave 2`
- cablaggio corretto lato SDM120:
  - bianco/arancio = `A` / positivo
  - arancio = `B` / negativo
  - bianco/verde = `GND`
- un errore precedente di cablaggio sul ramo SDM120 impediva la risposta Modbus; corretto il wiring, il contatore e` tornato leggibile sul path di MIRAI.
- package dedicato attivo in repo: `packages/sdm120_modbus.yaml`
- transport raw SDM120 integrato nell'hub `mirai` in `packages/mirai_modbus.yaml` perche' Home Assistant non carica due hub Modbus separati sullo stesso `host:port`
- registri confermati lato SDM120 via `FC4`:
  - `0` tensione
  - `6` corrente
  - `12` potenza attiva
  - `18` potenza apparente
  - `30` power factor
  - `70` frequenza
  - `72` energia importata
- decoding validato: IEEE754 `float32` big-endian (`>f`, 2 registri, nessuno `swap`)
- layer canonico additivo promosso su alias:
  - `sensor.grid_power_w`
  - `sensor.grid_direction`
  - `sensor.grid_energy_import_kwh`
  - `sensor.grid_voltage_v`
  - `sensor.grid_current_a`
- il dual meter legacy resta in runtime solo per compatibilita` transitoria

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

In aggiunta, dal `2026-03-29` sono disabilitate a livello `config_entries`
anche le due integrazioni `ESPHome` legacy:
- `LDR Camera1` (`ldr_camera1`, `192.168.178.24`)
- `LDR Camera2` (`ldr_camera2`, `192.168.178.25`)

Questo evita tentativi di riconnessione al boot e warning ripetuti quando i
nodi fisici non sono presenti.

## Meteo

Dal `2026-03-29` e` lasciata attiva una sola integrazione `met` per `Home`.
Una seconda entry duplicata di onboarding e` disabilitata nel runtime per
evitare l'errore:

- `Platform met does not generate unique IDs. ID home already exists`

Se il meteo dovesse essere ricreato in futuro, verificare che resti una sola
entry `met` con `track_home: true`.
