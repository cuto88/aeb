# STEP87 - Dashboard baseline freeze (2026-04-28)

## Scopo
Congelare lo stato corrente delle plance Lovelace prima della razionalizzazione UI, in modo che il punto di partenza sia ripristinabile.

## FACT
È stato creato uno snapshot locale dei file Lovelace attivi in:

`lovelace/_baseline/2026-04-28_dashboard_freeze/`

Contenuto congelato:
- `climate_casa_unified_plancia.yaml`
- `climate_ventilation_plancia.yaml`
- `climate_ventilation_plancia_v2.yaml`
- `climate_ac_plancia.yaml`
- `climate_ac_plancia_v2.yaml`
- `climate_heating_plancia.yaml`
- `8_mirai_plancia.yaml`
- `ehw_plancia.yaml`
- `modbus_plancia.yaml`
- `consumi_mirai_ehw_plancia.yaml`
- `energy_pv_solaredge_plancia.yaml`
- `envelope_involucro_plancia.yaml`

## DECISIONE
Questa baseline diventa il punto di rollback UI per il refactor plance.

## Ripristino

## DECISIONE
Se una modifica UI peggiora la leggibilità o rompe il modello target, il ripristino si fa ricopiando dal freeze ai file attivi corrispondenti.

Esempio:

```powershell
Copy-Item lovelace\_baseline\2026-04-28_dashboard_freeze\climate_casa_unified_plancia.yaml lovelace\climate_casa_unified_plancia.yaml -Force
```

Poi redeploy del file su HA.

## Boundary

## FACT
Questa baseline è:
- locale al repo/workspace;
- sufficiente per rollback contenutistico Lovelace;
- indipendente da git locale, che in questo workspace non è backend operativo affidabile.

## DECISIONE
Ogni razionalizzazione dashboard successiva deve poter essere confrontata con questa baseline.
