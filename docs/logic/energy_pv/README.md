# Energy PV - Produzione fotovoltaica

## Titolo
Energy PV - osservabilita` produzione FV SolarEdge.

## Obiettivo
- Rendere stabile e leggibile la telemetria FV usata come base osservativa per energia, surplus e advisory passivi.
- Esporre una sorgente canonica `pv_*` con fallback chiaro quando la telemetria primaria SolarEdge non e` disponibile.

## Entrypoints
- YAML: `packages/energy_pv_solaredge.yaml`.
- Lovelace: `lovelace/energy_pv_solaredge_plancia.yaml`.

## KPI / Entita` principali
- Potenza FV canonica: `sensor.pv_power_now`.
- Energia FV: `sensor.pv_energy_daily`, `sensor.pv_energy_monthly`, `sensor.pv_energy_yearly`, `sensor.pv_energy_total`.
- Diagnostica sorgente: `sensor.pv_potenza_sorgente`.
- Fallback runtime: sorgente SolarEdge primaria con fallback LocalTuya quando necessario.

## Note operative
- Il modulo e` osservativo: non introduce attuazione.
- `sensor.pv_power_now` e` la sorgente da preferire nei moduli decisionali che hanno bisogno di un proxy affidabile del sole/produzione FV.
- La plancia dedicata resta utile come diagnostica energia, mentre i moduli clima consumano il layer canonico senza duplicare la logica di fallback.

## Riferimenti
- [docs/logic/core/regole_core_logiche.md](../core/regole_core_logiche.md)
- [docs/logic/core/README_sensori_clima.md](../core/README_sensori_clima.md)
- [docs/logic/core/regole_plancia.md](../core/regole_plancia.md)
- [README_ClimaSystem.md](../../../README_ClimaSystem.md)
