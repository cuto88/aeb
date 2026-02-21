# Cleanup Hard Step 2 — Legacy disabled automations audit

## Scope
Rimozione definitiva delle automazioni legacy disabilitate richieste:
- `automation.heating_drive_master`
- `automation.vmc_apply_speed`
- `automation.ac_controller_priority`

Vincoli rispettati:
- nessuna rinomina `entity_id`
- nessuna modifica a `ehw_modbus`
- nessuna modifica a `lovelace/*`
- nessun cambio logica funzionale

## Risultato
Nel repository corrente non erano presenti blocchi YAML attivi/disattivati corrispondenti ai tre `entity_id` richiesti.

Verifica eseguita:
```bash
rg -n "heating_drive_master|vmc_apply_speed|ac_controller_priority" .
```
Esito: **zero match**.

## Home Assistant validation
Tentativi eseguiti nell'ambiente corrente:

1. Check configuration via Python module:
```bash
python3 -m homeassistant --script check_config -c .
```
Esito: fallito (modulo `homeassistant` non installato nell'ambiente).

2. Check/restart via HA CLI:
```bash
ha core check
ha core restart
```
Esito: fallito (CLI `ha` non disponibile nell'ambiente).

## Repairs screenshot
Non disponibile in questo ambiente: non è presente un'istanza Home Assistant raggiungibile via browser/container per acquisire uno screenshot della pagina Repairs.
