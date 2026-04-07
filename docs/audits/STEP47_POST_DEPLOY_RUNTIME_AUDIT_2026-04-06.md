# STEP47 Post-deploy runtime audit (2026-04-06)

## Scope
- Narrow runtime audit immediately after deploy of the current local workspace to Home Assistant.
- Focus:
  - deployed AEB MVP observability layer
  - deployed DHW writer post-live reconciliation
  - current safety posture vs retry-readiness
  - post-deploy config health

## Deploy fact
- Local gates: passed
- Runtime config check after deploy:
  - `ha core check = Command completed successfully.`
- Deployed via SSH/SCP fallback after SMB path `Z:\` mapping failed in this environment.
- Remote runtime paths updated under `/homeassistant`:
  - `packages/`
  - `lovelace/`
  - `docs/logic/`
  - `configuration.yaml`

## Runtime baseline
- Snapshot source:
  - `/homeassistant/.storage/core.restore_state`
  - `/homeassistant/.storage/trace.saved_traces`
- snapshot timestamp observed in restore-state:
  - `2026-04-06T19:32:42.604090+00:00`
- Modbus / heating baseline:
  - `binary_sensor.cm_modbus_ehw_ready = on`
  - `binary_sensor.climateops_heating_conflict_real = off`
  - `binary_sensor.heating_should_run = off`
  - `switch.heating_master = off`
  - `binary_sensor.mirai_machine_running_by_power = off`

## Findings

### 1. AEB MVP deployed package is present and coherent at runtime
- persisted AEB state:
  - `sensor.climateops_aeb_mvp_mode = disabled`
  - `sensor.climateops_aeb_mvp_reason = disabled`
  - `sensor.climateops_aeb_mvp_last_outcome = live_write_sent`
  - `input_text.climateops_aeb_mvp_last_action = LIVE_REQUEST:action=boost|target_c=46.0|actual_c=45.0|reason=ok`
- deployed package verification on remote file:
  - `ClimateOps AEB MVP Last Outcome`
  - `ClimateOps Heating Conflict Real`
  - `climateops_aeb_mvp_live_request_counter`

Interpretation:
- the deployed runtime still remembers the first successful conservative live pass
- the new observability and corrected heating-conflict gate are present on the deployed node

Conclusion:
- AEB MVP deploy content is in place
- current posture remains safe-by-default

### 2. DHW writer semantic reconciliation remains closed after deploy
- writer-facing persisted state:
  - `input_number.climateops_dhw_requested_setpoint = 45.0`
  - `sensor.climateops_dhw_actual_feedback = 45.0`
  - `sensor.climateops_dhw_expected_feedback = 45.0`
  - `binary_sensor.climateops_dhw_feedback_matches_expected = on`
  - `input_text.climateops_dhw_write_result = LIVE_WRITE_SENT:hub=ehw_modbus|addr=1104|raw=150|target_c=45.0|expected_c=45.0`
  - `sensor.ehw_setpoint = 45.0`
- remote package verification on deployed file:
  - `climateops_dhw_writer_reconcile_post_live`
  - logbook message `Post-live semantic reconciliation applied`

Interpretation:
- the prior semantic mismatch between `requested / expected / actual` is no longer visible
- writer state is currently coherent and stable after deploy

Conclusion:
- DHW writer path is healthy
- post-live semantic reconciliation is effectively closed

### 3. Retry-readiness is now unfavorable, but for correct runtime reasons
- current grid posture:
  - `sensor.grid_direction = import`
  - `sensor.grid_power_w = 651.59`
- current readiness:
  - `binary_sensor.climateops_aeb_mvp_live_retry_ready = off`

Interpretation:
- this is not a deploy regression
- readiness changed because current electrical conditions are not favorable for a conservative self-consumption retry

Conclusion:
- system is safe
- system is not currently retry-ready

### 4. Trace evidence remains consistent with the expected control history
- `automation.climateops_aeb_mvp_dispatch` still has traces up to:
  - `2026-04-05T09:00:00.210626+00:00`
- `automation.climateops_dhw_writer_reconcile_post_live` contains a finished run at:
  - `2026-04-03T15:59:07.964280+00:00`
- finished reconcile evidence:
  - `requested_c = 44.5` before reconciliation
  - `target_c = 45.0`
  - `actual_c = 45.0`
  - `input_number.set_value` executed
  - logbook message emitted

Interpretation:
- saved traces still support the earlier causal explanation of the reconciliation fix
- no contradictory post-deploy evidence is visible

Conclusion:
- runtime evidence chain remains coherent

## Decision
- Runtime health: OK
- Post-deploy config health: OK
- AEB MVP observability deploy: CLOSED
- DHW writer reconciliation deploy: CLOSED
- Current live retry posture: NOT READY

## Recommended next step
- Keep the system in safe posture and wait for a naturally favorable export window before any future controlled live retry.
