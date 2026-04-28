# STEP82 - Wired windows binding plan

Date: 2026-04-24
Scope: formalize the minimum remaining work for serramenti contacts, given that the logical model and Lovelace exposure already exist.

This step does not choose hardware and does not change runtime logic yet.

## FACT

- The runtime already contains the logical window model.
- Existing upstream helper entities already exposed in packages/UI:
  - `input_boolean.vent_finestra_giorno1_aperta`
  - `input_boolean.vent_finestra_giorno2_aperta`
  - `input_boolean.vent_portoncino_ingresso_aperto`
  - `input_boolean.vent_foro_cappa_aperto`
  - `input_boolean.vent_finestra_notte1_aperta`
  - `input_boolean.vent_finestra_notte2_aperta`
  - `input_boolean.vent_finestra_notte3_aperta`
  - `input_boolean.vent_finestra_bagno_aperta`
- Existing downstream aggregates already present:
  - `binary_sensor.windows_giorno_any`
  - `binary_sensor.windows_notte_any`
  - `binary_sensor.windows_bagno_any`
  - `binary_sensor.windows_all_closed`
  - `sensor.windows_open_count`
  - `sensor.vent_finestre_state`
- These entities are already used in Lovelace and climate logic.
- Physical wired contacts already exist on serramenti, with tamper, and collection point in the garage junction box.

## IPOTESI

- Confidenza alta: the missing work is not UI, not naming, and not climate aggregation.
- Confidenza alta: the missing work is only the upstream binding from physical contacts to the existing helper layer.
- Confidenza alta: preserving the current entity model is the highest-ROI path because it avoids breaking Lovelace and downstream logic.

## DECISIONE

- Keep the current window entity surface.
- Do not redesign window dashboards.
- Do not rename aggregates.
- Replace only the current manual/helper source with physical inputs.

## Target binding model

### Current posture

FACT
- Current structure is:
  - physical contacts: present in field
  - helper/window booleans: present in runtime
  - aggregated binary sensors: present in runtime
  - dashboards: present

DECISIONE
- Treat current `input_boolean.vent_finestra_*` as the compatibility boundary to preserve until cutover is complete.

### Minimal target

DECISIONE
- Introduce one physical input acquisition layer upstream of the helper booleans.
- Preserve existing zone/group semantics.
- First cut should bind at least:
  - `giorno1`
  - `giorno2`
  - `notte1`
  - `notte2`
  - `notte3`
  - `bagno`
- `portoncino_ingresso` and `foro_cappa` can stay separate as already modeled.

## Implementation posture

### What must happen

DECISIONE
- Read the wired contacts from one field I/O source.
- Map each physical input to the corresponding existing helper entity or to an equivalent physical binary sensor bridge.
- Keep aggregates unchanged.

### What must NOT happen

DECISIONE
- Do not create a second competing window model.
- Do not add new dashboard-only entities.
- Do not over-model every sash before zone-level value is realized.
- Do not mix physical truth and manual placeholders silently without an explicit bridge rule.

## Recommended cutover pattern

1. Add physical input entities with stable names.
2. Bridge each physical entity into the existing `input_boolean.vent_finestra_*` compatibility layer or replace those booleans with physical entities one by one.
3. Verify that these existing downstream entities remain correct without changes:
   - `binary_sensor.windows_giorno_any`
   - `binary_sensor.windows_notte_any`
   - `binary_sensor.windows_bagno_any`
   - `binary_sensor.windows_all_closed`
   - `sensor.windows_open_count`
   - `sensor.vent_finestre_state`
4. Only after verification, decide whether the compatibility booleans should remain or be retired.

## Success criterion

FACT
- This work is complete when the existing window plance and aggregates are driven by physical contacts, not by manual booleans.

DECISIONE
- Closure criterion:
  - no climate policy depends on manual window placeholders where physical contacts already exist
  - no Lovelace rewrite required
  - physical contacts become the real source of truth

## Final decision

DECISIONE
- Window integration is now redefined precisely as:
  - `physical input binding into the existing helper/aggregate model`
- The next engineering step is not architectural discovery.
- It is a narrow binding implementation plan around the already existing entity surface.
