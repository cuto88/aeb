# STEP7 Post-Deploy Runtime Verification (2026-02-25)

Date: 2026-02-25  
Scope: verifica runtime dopo merge su `main` + deploy safe Step6/Step7.

## Operazioni eseguite
- Merge branch `feat-aeb-step7-closure-2026-02-25` su `main` e push remoto.
- Deploy con `ops/deploy_safe.ps1 -Target Z:\` completato con backup.
- Runtime checks via SSH:
  - `ha core check` -> `Command completed successfully.`
  - `ha core restart` -> completato (dopo coda job supervisor).
  - `ha core info` -> `boot: true`, `version: 2026.2.3`.

## Evidenza deploy (FACT)
- File runtime aggiornati verificati su host:
  - `/homeassistant/packages/climateops/core/kpi.yaml`
  - `/homeassistant/packages/climate_policy_energy.yaml`
  - `/homeassistant/configuration.yaml` (dashboard `9-climateops-step7`)
- Tracce presenti per:
  - `automation.climateops_system_actuate` in `/homeassistant/.storage/trace.saved_traces`.

## Smoke check stato nuove entita` (snapshot)
- Da `/homeassistant/.storage/core.restore_state` risultano entita` Step7 presenti
  (forecast/policy/hierarchy/KPI), con stato iniziale `unknown` al timestamp di bootstrap.
- Non sono emersi errori template nelle ultime 400 righe di `ha core logs`
  filtrate su entita` Step7.

## Esito
- Deploy e riavvio: OK.
- Caricamento definizioni Step7: OK.
- Verifica funzionale completa dei valori runtime: PARZIALE
  (necessaria conferma a caldo da UI/state machine dopo fase di warm-up sensori).

## Follow-up operativo
1. Verificare da UI (Developer Tools -> States) gli stati:
   - `binary_sensor.policy_forecast_inputs_ready`
   - `binary_sensor.policy_allow_shift_load`
   - `binary_sensor.contract_hierarchy_mode_ready`
   - `sensor.cm_system_mode_suggested`
   - `binary_sensor.aeb_kpi_inputs_ready`
   - `sensor.aeb_self_consumption_ratio_pct`
2. Salvare export evidenza in `docs/runtime_evidence/2026-02-25/`.
3. Nota: tentativo di lettura diretta via Supervisor/Core API da shell SSH ha restituito `401 Unauthorized`,
   quindi la conferma live degli stati resta demandata a UI/export runtime.
