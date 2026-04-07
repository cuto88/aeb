# Plancia ClimateOps Step7

File dashboard storico: `lovelace/_archive/climateops_step7_plancia.yaml`

## Scopo
Dashboard tecnica per osservare in un unico punto:
- forecast contracts,
- tariff/grid policy,
- hierarchy mode/reason,
- KPI AEB runtime.
- executive view mobile-first per lettura rapida stato operativo.
- diagnostics view mobile-first per analisi reason/contract chain.

## Vista Executive (UI Sprint 1)
- path: `executive`
- max columns: `1` (mobile-first)
- contenuti:
  - stato sintetico GO/NO-GO runtime (reason + readiness),
  - KPI giornalieri Phase1 + recommendation planner,
  - policy energetica forecast/tariff-grid,
  - trend rapido 24h (self-consumption, comfort-energy, grid import).

## Vista Diagnostics (UI Sprint 2)
- path: `diagnostics`
- max columns: `1` (mobile-first)
- contenuti:
  - readiness contratti runtime (forecast/hierarchy/tariff-grid/KPI),
  - reason chain completa (`cm_system_reason`, planner/policy/heating/ventilation),
  - snapshot KPI AEB e stato policy,
  - trend diagnostico 24h (grid import/price + comfort/vmc KPI).

## Sezioni
- Stato generale: `cm_system_mode_suggested`, `cm_system_reason`, contratti hierarchy.
- Forecast contracts: readiness/reason + forecast PV/T next hour.
- Tariff/Grid policy: toggle `policy_enable_tariff_grid`, reason e segnali import/price.
- Hierarchy layer: `climateops_hierarchy_mode/reason` + bridge `cm_*`.
- KPI AEB: snapshot `aeb_*`.
- Trend 24h: prezzo rete, import rete, KPI principali.

## Nota operativa
- `policy_enable_tariff_grid` resta di default `off`.
- Se le entità forecast non sono ancora disponibili a runtime, i relativi stati possono
  risultare `unknown` in bootstrap e poi convergere con i feed attivi.
- La dashboard non fa piu' parte del set Lovelace attivo.
- Il duplicato runtime `lovelace/climateops_step7_plancia.yaml` e` stato rimosso dal repo attivo; resta solo la copia storica in archivio.
