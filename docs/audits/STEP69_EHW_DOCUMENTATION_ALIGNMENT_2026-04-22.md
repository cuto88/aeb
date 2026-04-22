# STEP69 - EHW documentation alignment

Date: 2026-04-22
Scope: documentation only.

## FACT

- `packages/ehw_reconciliation.yaml` is deployed and runtime-loaded.
- Runtime verification in `STEP68` confirmed:
  - `sensor.ehw_operation_state = active_power_confirmed`
  - `binary_sensor.ehw_power_confirmed = on`
  - `binary_sensor.ehw_demand_power_mismatch = off`
- The canonical EHW entity map did not yet include the reconciliation entities.
- The audit index did not yet include STEP64/STEP68 or the new 2026-04-22 operational hardening sequence.

## IPOTESI

- Confidenza alta: keeping entity maps current prevents future misuse of `binary_sensor.ehw_running`.
- Confidenza alta: the main ROI is semantic clarity, not more runtime logic.

## DECISIONE

- Update `docs/logic/core/README_sensori_ehw.md` with:
  - current 2026-04-22 checkpoint
  - semantics of `binary_sensor.ehw_running`
  - new reconciliation entities
  - usage guidance for diagnostics and future alarms
- Update `docs/logic/energy_pm/plancia_mirai_ehw.md` with EHW reconciliation references.
- Update `docs/audits/README.md` with STEP64-STEP68 and current hardening steps.

## Verification

- Documentation references now include:
  - `sensor.ehw_operation_state`
  - `binary_sensor.ehw_power_confirmed`
  - `binary_sensor.ehw_demand_power_mismatch`
- No runtime deploy required.
