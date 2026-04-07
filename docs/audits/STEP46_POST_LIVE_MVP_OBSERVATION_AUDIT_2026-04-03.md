# STEP46 Post-live MVP observation audit (2026-04-03)

## Scope
- Narrow runtime audit after the first successful conservative live AEB MVP pass.
- Focus:
  - AEB MVP observability layer
  - DHW writer coherence
  - heating conflict real gate
  - consumi / EHW UI stability

## Runtime baseline
- Home Assistant core: `boot: true`
- Modbus readiness:
  - `binary_sensor.cm_modbus_ehw_ready = on`
  - `binary_sensor.cm_modbus_mirai_ready = on`
- Heating conflict:
  - `binary_sensor.climateops_heating_conflict_real = off`
  - `binary_sensor.heating_should_run = off`
  - `switch.heating_master = off`
  - `binary_sensor.mirai_machine_running_by_power = off`

## Findings

### 1. Observability layer is present, but counters are not yet representative
- `sensor.climateops_aeb_mvp_last_outcome = live_write_sent`
- `counter.climateops_aeb_mvp_live_requests_total = 0`
- `counter.climateops_aeb_mvp_holds_total = 0`

Interpretation:
- the outcome sensor correctly remembers the first successful live pass
- the counters remain `0` because the measurement layer was deployed after the first live event and does not backfill history

Conclusion:
- additive KPI layer is working structurally
- cumulative counters are valid only from their deployment point forward

### 2. DHW writer path is healthy, but post-live state is not in full semantic sync
- `input_text.climateops_dhw_write_result = LIVE_WRITE_SENT:hub=ehw_modbus|addr=1104|raw=153|target_c=46.0|expected_c=45.9`
- current DHW state:
  - `sensor.ehw_setpoint = 45.6`
  - `sensor.ehw_setpoint_raw_a = 152`
  - `sensor.ehw_setpoint_raw_calc = 152`
- current writer/control surface:
  - `input_number.climateops_dhw_requested_setpoint = 45.0`
  - `sensor.climateops_dhw_expected_feedback = 45.0`
  - `binary_sensor.climateops_dhw_feedback_matches_expected = off`
  - `sensor.climateops_dhw_blocked_reason = IDLE`

Interpretation:
- no runtime failure is visible
- but the writer-facing “expected/requested” state has returned to baseline while the tank setpoint remains elevated at ~`45.6`

Conclusion:
- this is not a transport or Modbus fault
- it is a post-session semantic mismatch between remembered target intent and actual remaining DHW setpoint

### 3. AEB readiness is currently favorable
- `binary_sensor.climateops_aeb_mvp_live_retry_ready = on`
- MVP posture is still safe:
  - `sensor.climateops_aeb_mvp_mode = disabled`
  - `sensor.climateops_aeb_mvp_reason = disabled`

Interpretation:
- the corrected heating conflict gate is behaving as intended
- the system is safe and simultaneously ready for a future controlled retry if needed

### 4. Consumi and EHW plance are stable after recent cleanup
- daily share block in consumi is stable:
  - `sensor.local_meters_energy_daily_total = 2.814`
  - `sensor.mirai_daily_share_pct = 2.5`
  - `sensor.ehw_daily_share_pct = 45.5`
  - `sensor.ds01_daily_share_pct = 36.3`
  - `sensor.pm1_daily_share_pct = 14.8`
- `sensor.ehw_power_w = 0.0` is present and suitable for the EHW 24h graph

Conclusion:
- recent UI/data cleanup on consumi and EHW is holding up at runtime

## Decision
- Runtime health: OK
- AEB MVP live path: CLOSED for first conservative pass
- AEB measurement layer: PARTIALLY CLOSED
- Main residual issue:
  - writer expected/requested state does not fully reflect the post-live DHW setpoint state

## Recommended next step
- Add one narrow post-live DHW state reconciliation rule so the MVP/writer observability layer reports the real remaining setpoint state after a successful live session.
