# STEP68 - EHW reconciliation runtime verification

Date: 2026-04-22
Scope: runtime verification after loading `packages/ehw_reconciliation.yaml`.

## FACT

- Before restart, the package file existed on `/homeassistant/packages/ehw_reconciliation.yaml`.
- HA API returned `404 Not Found` for:
  - `sensor.ehw_operation_state`
  - `binary_sensor.ehw_power_confirmed`
  - `binary_sensor.ehw_demand_power_mismatch`
- This confirmed the package had been deployed but not loaded.
- A controlled `ha core check && ha core restart` was executed.
- SSH command timed out at the client after restart, but returned:
  - `Command completed successfully.` for config check
  - `Command completed successfully.` for restart
- HA API returned after restart.

## Runtime Result

- `sensor.ehw_operation_state = active_power_confirmed`
- `binary_sensor.ehw_power_confirmed = on`
- `binary_sensor.ehw_demand_power_mismatch = off`
- `sensor.t_in_med = 22.57`

## IPOTESI

- Confidenza alta: the previous `ehw_running=on` / `ehw_power_w=0.0` observation was at least partly timing/semantic ambiguity, not a persistent fault.
- Confidenza alta: the new reconciliation entities make this distinction explicit.

## DECISIONE

- Treat EHW reconciliation as runtime-loaded and verified.
- Use `sensor.ehw_operation_state` for operator diagnostics instead of interpreting `binary_sensor.ehw_running` as power activity.
- Keep observing whether `demand_no_power` appears frequently; only persistent or long-duration mismatch should trigger investigation.

## Verification

- HA API: PASS.
- New entities present: PASS.
- EHW mismatch state: `off`.
- Runtime deploy/restart: completed.
