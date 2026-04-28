# STEP90 - Heating dashboard refactor (2026-04-28)

## Scopo
Ripulire la plancia `Heating` come domain drill-down, riducendo il peso del legacy TEMP/LDR e del tuning poco usato nella parte alta della vista.

## FACT
La plancia `Heating` era quella con il maggiore carico di:
- legacy osservazionale TEMP/LDR;
- tuning manuale;
- dettagli non utili al primo livello di diagnosi operativa.

## DECISIONE
La plancia viene rifocalizzata su:
- stato generale heating;
- setpoint e zone incluse;
- KPI e diagnostica runtime;
- trend e debug essenziali.

## Modifiche applicate

### Stato generale
- `glance` sostituito con `tile/grid` a 2 colonne
- mantenuti:
  - `Should run`
  - `Priorità`
  - `Reason`
  - `Failsafe`

### Manuale alto livello
- mantenuti:
  - logica attiva
  - lock min ON / min OFF
  - manuale attivo
  - modalità manuale
- rimosso:
  - `timer.heating_manual_timeout` dalla parte alta

### Termostati reali TEMP
- rimossa la lunga card entità legacy dalla parte centrale della plancia
- mantenuta solo nota markdown di stato:
  - LDR/TEMP smontati
  - remap possibile in futuro

### KPI e diagnostica
- mantenuti:
  - errori zona
  - stanze sotto target
  - finestre / soglie di contesto
- rimosso:
  - `sensor.heating_rooms_active`

### Runtime e cicli
- mantenuti:
  - minuti da ultimo cambio
  - ore ON oggi / ieri
- rimosso:
  - `input_number.heating_hours_on_daily` dalla plancia operativa

### Debug
- chiarita la coppia:
  - `switch.heating_master`
  - `switch.4_ch_interruttore_3`

### Legacy TEMP / remap
- i campi `input_text` / soglie LDR non sono persi
- vengono spostati in fondo, come sezione tecnica separata

## Esito

## FACT
La plancia `Heating` resta tecnica, ma meno dispersiva.

## DECISIONE
Il legacy TEMP non viene rimosso dal sistema:
- viene solo declassato fuori dal percorso operativo principale.

## Prossimo passo

## DECISIONE
Il prossimo nodo di razionalizzazione è decidere il destino delle plance:
- `climate_ventilation_plancia_v2.yaml`
- `climate_ac_plancia_v2.yaml`
