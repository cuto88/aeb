# STEP87 - Dashboard baseline freeze (2026-04-28)

## Scopo
Congelare lo stato corrente delle plance Lovelace prima della razionalizzazione UI, in modo che il punto di partenza sia ripristinabile.

## FACT
È stato creato uno snapshot locale dei file Lovelace attivi in:

`lovelace/_baseline/2026-04-28_dashboard_freeze/`

Contenuto congelato:
- `01_eclss_casa.yaml`
- `02_air_loop_legacy.yaml`
- `02_air_loop.yaml`
- `04_cooling_loop_legacy.yaml`
- `04_cooling_loop.yaml`
- `03_heating_loop.yaml`
- `08_mirai_plant.yaml`
- `07_dhw_acs.yaml`
- `09_fieldbus.yaml`
- `06_power_runtime.yaml`
- `05_pv_array.yaml`
- `10_envelope.yaml`

## DECISIONE
Questa baseline diventa il punto di rollback UI per il refactor plance.

## Ripristino

## DECISIONE
Se una modifica UI peggiora la leggibilità o rompe il modello target, il ripristino si fa ricopiando dal freeze ai file attivi corrispondenti.

Esempio:

```powershell
Copy-Item lovelace\_baseline\2026-04-28_dashboard_freeze\01_eclss_casa.yaml lovelace\01_eclss_casa.yaml -Force
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
