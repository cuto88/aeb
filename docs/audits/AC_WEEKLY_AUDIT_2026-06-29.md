# AC weekly audit (2026-06-29)

Scope: `2026-06-22` .. `2026-06-28`

## Operational provenance

| Campo | Valore |
| --- | --- |
| Operator machine | `DS-WORK` |
| Runtime target | `mercurio-edge` |
| Legacy machine status | `DS-01 powered off` |
| Access mode | `local repo only` |
| Deploy eseguito | `no` |
| Runtime changes eseguite | `no` |
| Commit / GitHub Actions rilevanti | `fe73cfe` (`docs: require operational provenance in audits`), `fb649b8` (`docs: record DS-01 cutover confirmation`) |

## Evidence available in this workspace

- The AC package files in the repo match the DR snapshot taken on `2026-06-22` under `_dr_backups/ha_runtime_snapshot_20260622_110941`.
- The repo does not contain `docs/runtime_evidence/` exports for `2026-06-22` .. `2026-06-28`.
- The HA SSH key paths referenced in the operational notes are not present in this workspace, so live trace/logbook collection was not possible here.
- No commit touching the AC packages or `packages/climateops/actuators/system_actuator.yaml` appears in `git log --since=2026-06-22`.

## Findings

### 1. AC source/runtime posture is stable

The key AC files are byte-identical between repo and the 22/06 DR snapshot:

- `packages/climate_ac_comfort_control.yaml`
- `packages/climate_ac_logic.yaml`
- `packages/climate_ac_mapping.yaml`
- `packages/climate_ac_observability.yaml`
- `packages/climate_ac_templates.yaml`
- `packages/climateops/actuators/system_actuator.yaml`
- `packages/climateops/drivers/ac_proxy.yaml`

This means there is no source-side drift to reconcile before considering tuning.

### 2. No live event-level audit for last week

The repo snapshot does not include AC trace exports or logbook evidence for the requested week. Because the HA SSH keys are unavailable in this workspace, I could not validate:

- `automation.climateops_system_actuate`
- `script.ac_giorno_apply` / `script.ac_notte_apply`
- `switch.ac_giorno` / `switch.ac_notte`

So this is a source audit, not a runtime trace audit.

### 3. VMC is not a valid optimization target right now

Per user note, VMC is off. Any tuning that depends on active VMC interaction should be deferred until reactivation and a fresh analysis window.

## Optimization candidates

### Low risk

- Deduplicate the day/night request logic in `packages/climate_ac_comfort_control.yaml`.
  - The day and night comfort request sensors currently repeat the same temperature/humidity/dew-point logic with only the source sensors changed.
  - A shared template or reusable macro would reduce maintenance risk.
- Parameterize the AC apply scripts.
  - `script.ac_giorno_apply` and `script.ac_notte_apply` in the legacy mapping package are structurally identical apart from the target entity.
  - A single generic helper would reduce duplication.

### Medium risk

- Revisit the `time_pattern` wakeup in `automation.climateops_system_actuate`.
  - It currently re-evaluates every 2 minutes even when no relevant state changed.
  - If the goal is to minimize churn, that periodic trigger can be relaxed or removed, but only after confirming state-driven triggers are sufficient.

### Data-dependent, defer until VMC returns

- Tune `input_number.ac_equipment_target_offset`.
- Tune the comfort thresholds in `packages/climate_ac_comfort_control.yaml`.
- Revisit the lock/minimum timings in `packages/climate_ac_templates.yaml`.

Those should be driven by event-level traces and a week of live behavior after VMC reactivation.

## Verdict

For the last week there is no evidence of AC drift or regression in source/runtime configuration.

The only safe optimization I would make now is structural cleanup of duplicated AC logic. I would not change comfort thresholds or timing without fresh traces, and I would not include VMC in the analysis until it is back online.
