# STEP23 EHW/MIRAI IP Mapping Verification (2026-03-01)
Date: 2026-03-01
Scope: verificare il dubbio di inversione IP tra Modbus EHW e Modbus Mirai.

## Baseline runtime config
- `mirai_modbus_host: 192.168.178.190`
- `ehw_modbus_host: 192.168.178.191`
- `ehw_modbus_slave: 1`

Sorgente: `/homeassistant/secrets.yaml` su runtime.

## Metodo di verifica
- Probe Modbus TCP diretti dal nodo HA (`root@192.168.178.84:2222`) con richieste raw socket.
- Test incrociato su entrambi host:
  - profilo EHW: `unit=1`, registri `56`, `1255`
  - profilo Mirai: `unit=3`, registri `1003`, `1208`

## Evidenza osservata
- `192.168.178.190`:
  - risponde ai probe Mirai (`unit=3`, `1003/1208`)
  - non risponde ai probe EHW (`unit=1`, `56/1255`)
- `192.168.178.191`:
  - risponde ai probe EHW (`unit=1`, `56/1255`)
  - non risponde ai probe Mirai (`unit=3`, `1003/1208`)
- Valore notevole:
  - su `192.168.178.191`, `reg1255` letto stabile a `1000` (parametro indirizzo Modbus da manuale EHW).

## Conclusione
- Nessuna inversione IP rilevata.
- Mapping corretto:
  - Mirai -> `192.168.178.190`
  - EHW -> `192.168.178.191`

## Nota operativa
- `binary_sensor.ehw_mapping_suspect` inizialmente risultava `on` per falsa positività della regola.
- Correzione applicata in `packages/ehw_modbus.yaml`:
  - `mapping_health` considera `ok` quando i registri chiave sono numerici (anche se `0`), non solo `>0`.
