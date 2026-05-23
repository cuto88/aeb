# STEP7.4 KPI Closure (2026-02-25)

Date: 2026-02-25  
Scope: chiusura KPI AEB a livello repo (template KPI + dashboard + docs).

## Obiettivo
Introdurre KPI AEB minimi misurabili e compatibili HA 2026.2.x, senza dipendenza da
`history_stats` YAML.

## File modificati
- `packages/climateops/core/kpi.yaml`
- `lovelace/06_power_runtime.yaml`
- `docs/logic/energy_pm/plancia_mirai_ehw.md`

## Modifiche applicate

### 1) KPI template runtime (`kpi.yaml`)
Aggiunti:
- `binary_sensor.aeb_kpi_inputs_ready`
- `binary_sensor.aeb_load_shift_effective_now`
- `sensor.aeb_self_consumption_ratio_pct`
- `sensor.aeb_shift_effectiveness_pct`
- `sensor.aeb_comfort_energy_score_pct`
- `sensor.aeb_policy_activation_rate_pct`
- `sensor.aeb_kpi_reason`

Note:
- calcoli con fallback su `sensor.sensor_grid_power_w` se `sensor.policy_grid_power_w`
  non disponibile;
- KPI progettati come snapshot runtime (non time-aggregated).

### 2) Dashboard
In `lovelace/06_power_runtime.yaml` aggiunta sezione:
- `KPI AEB (runtime)` con stato input + reason + indicatori principali.

### 3) Documentazione plancia
In `docs/logic/energy_pm/plancia_mirai_ehw.md` aggiornata la sezione layout con
elenco KPI AEB e nota operativa sul layer template.

## Validazione
- `ops/validate.ps1`: PASS

## Limiti noti
- KPI sono runtime/istantanei; la closure statistica multi-giorno richiede una fase
  evidenza runtime (`docs/runtime_evidence/<date>/`) con finestra osservazionale.

## Esito
- Step 7.4 completato a livello repository.
