# ClimateOps Cleanup Plan (Step 2/3)

## What is authoritative where
- **Proxy template binary sensors** live in `packages/climateops/drivers/`:
  - `heating_proxy.yaml` → `climateops_heating_master_is_on`
  - `vmc_proxy.yaml` → `climateops_vmc_is_running`
  - `ac_proxy.yaml` → `climateops_ac_giorno_is_on`, `climateops_ac_notte_is_on`
- **Strategy logic** lives in `packages/climateops/strategies/arbiter.yaml` and references the proxy entities above.

## Files safe to archive later
- None identified in Step 2/3. No duplicate proxy definitions were found that need consolidation.

## No entity rename rule
- Do **not** rename any `entity_id` or change `unique_id`. Keep registry stability by leaving identifiers unchanged.

## Next step (3/3): docs + final tidy
- Validate documentation and comments only; keep behavior unchanged.
- If any future duplicates are discovered, reduce to a single authoritative proxy definition in `packages/climateops/drivers/`.
