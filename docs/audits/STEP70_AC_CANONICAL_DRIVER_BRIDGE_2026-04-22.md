# STEP70 - AC canonical driver bridge

Date: 2026-04-22
Scope: ClimateOps naming bridge and AC observed-state authority.

## FACT

- Runtime exposes the effective AC feedback entities as:
  - `binary_sensor.ac_giorno_is_on_proxy`
  - `binary_sensor.ac_notte_is_on_proxy`
- Runtime exposes effective heating/VMC feedback as:
  - `binary_sensor.heating_master_is_on_proxy`
  - `binary_sensor.vmc_is_running_proxy`
- `binary_sensor.climateops_ac_giorno_is_on`, `binary_sensor.climateops_ac_notte_is_on`,
  `binary_sensor.climateops_heating_master_is_on` and `binary_sensor.climateops_vmc_is_running`
  are not available through the runtime API.
- `binary_sensor.cm_policy_allow_ac` and `binary_sensor.cm_policy_surplus_ok` existed in
  documentation/SOT but were unavailable at runtime.

## IPOTESI

- Confidenza alta: the unavailable `climateops_*` names are caused by entity registry naming
  drift around template names/unique IDs.
- Confidenza alta: the highest-ROI correction is to make `cm_*` the runtime abstraction layer
  over the actual proxy entity IDs, not to rename runtime entities manually.
- Confidenza media: keeping the historical `packages/climateops/drivers/*_proxy.yaml` files is
  acceptable until a later cleanup, because the control path should consume only `cm_driver_*`.

## DECISIONE

- Add canonical bridge entities in `packages/cm_naming_bridge.yaml`:
  - `binary_sensor.cm_policy_allow_ac`
  - `binary_sensor.cm_policy_surplus_ok`
  - `binary_sensor.cm_driver_heating_is_on`
  - `binary_sensor.cm_driver_vmc_is_running`
  - `binary_sensor.cm_driver_ac_giorno_is_on`
  - `binary_sensor.cm_driver_ac_notte_is_on`
- Point the driver bridge to the runtime-effective `*_is_on_proxy` entities.
- Update `packages/climateops/strategies/arbiter.yaml` to consume `cm_driver_*`.
- Update `docs/SOT_ENTITIES.md` so the canonical map reflects runtime truth.

## ROI

- Removes hidden dependency on unavailable entity IDs.
- Keeps strategy logic independent from entity registry drift.
- Improves observability of AC/VMC/heating active-state decisions without touching physical actuation.
- No manual AC window required.

## Verification

- Local `ops/gates_run_ci.ps1`: `ALL GATES PASSED`.
- Runtime deploy completed for:
  - `/homeassistant/packages/cm_naming_bridge.yaml`
  - `/homeassistant/packages/climateops/strategies/arbiter.yaml`
- `ha core check`: passed.
- `template.reload`: completed without full HA restart.
- Runtime API after reload:
  - `binary_sensor.cm_policy_allow_ac = on`
  - `binary_sensor.cm_policy_surplus_ok = off`
  - `binary_sensor.cm_driver_heating_is_on = off`
  - `binary_sensor.cm_driver_vmc_is_running = on`
  - `binary_sensor.cm_driver_ac_giorno_is_on = off`
  - `binary_sensor.cm_driver_ac_notte_is_on = off`
  - `sensor.arbiter_suggested_mode = VENT`
  - `sensor.arbiter_suggested_reason = VMC running (observed)`
