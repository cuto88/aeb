# Cleanup Hard Step 1 — Remove obsolete planner bridge

## Scope
Ricerca delle entità legacy richieste:
- `sensor.climateops_mode_suggested`
- `sensor.climateops_planner_mode`
- `sensor.climateops_arbiter_mode`

## Risultato ricerca
Ricerca globale eseguita con:

```bash
rg -n "sensor\.climateops_mode_suggested|sensor\.climateops_planner_mode|sensor\.climateops_arbiter_mode" .
```

Nessuna occorrenza trovata.

## Bridge templates
In `packages/cm_naming_bridge.yaml` non sono presenti bridge template verso le tre entità legacy sopra indicate.
Quindi non è stata necessaria alcuna rimozione in questo step.

## Verifica dipendenza `sensor.cm_system_mode_suggested`
`cm_system_mode_suggested` usa esclusivamente `sensor.vmc_vel_target` nella logica template.

## Check configuration / restart
Tentativi eseguiti nell'ambiente corrente:

```bash
python3 -m homeassistant --script check_config -c .
# -> No module named homeassistant

ha core restart
# -> command not found: ha
```

In questo container non è disponibile runtime Home Assistant/CLI Supervisor, quindi check config e restart non sono eseguibili localmente.
