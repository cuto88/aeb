# AEB Digital Twin Specification v1

Status: **Draft**  
Scope: **Casa Mercurio / AEB**  
Authority: **normative for the non-runtime digital twin data layer after adoption**

## 1. Purpose

This specification defines the minimum semantic contract for representing Casa Mercurio as a versioned engineering knowledge system.

The digital twin is not only a description of the building. It represents:

- physical reality;
- documented design and nominal specifications;
- observed runtime behaviour;
- measurements and derived values;
- decisions, maintenance and incidents;
- uncertainty, provenance and verification status;
- relationships between spaces, systems, assets, sensors, actuators and automation logic.

The goal is to make building knowledge reusable by people, Home Assistant integrations, audits, simulations and future agents without treating chat memory or live runtime state as an implicit source of truth.

## 2. Normative language

The terms **MUST**, **MUST NOT**, **SHOULD**, **SHOULD NOT** and **MAY** express requirement strength.

- **MUST / MUST NOT**: mandatory for conformance.
- **SHOULD / SHOULD NOT**: expected unless a documented reason exists.
- **MAY**: optional.

## 3. Architectural principles

### 3.1 Separation of concerns

The following information classes MUST remain distinguishable:

1. **Nominal specifications** — manuals, datasheets and manufacturer documentation.
2. **Installed reality** — nameplates, photographs, drawings, surveys and verified physical inspection.
3. **Observed runtime** — Home Assistant states, recorder history, energy data and runtime evidence snapshots.
4. **Derived knowledge** — calculations, aggregations, inferred relationships and analytical conclusions.
5. **Decision knowledge** — why a choice was made, alternatives considered and evidence used.

Nominal data MUST NOT be presented as measured runtime performance. Family-level documentation MUST NOT be presented as the exact installed model.

### 3.2 Repository versus runtime

The Git repository is the authoritative, versioned source for curated digital twin knowledge.

Home Assistant is authoritative for live state only within the limits of available runtime evidence.

Files under `data/` MUST NOT directly control Home Assistant unless an explicit, reviewed bridge is implemented.

### 3.3 No silent certainty promotion

A fact MUST NOT move from estimated, inferred or family-level documentation to verified installed reality without new supporting evidence.

### 3.4 Stable identity

Every first-class entity MUST have one stable identifier. Display names MAY change; identifiers SHOULD remain stable.

### 3.5 References over duplication

Information SHOULD be stored once and referenced by identifier elsewhere. Necessary denormalisation MUST be documented and SHOULD be machine-checkable.

## 4. Conformance model

A dataset conforms to this specification when:

- every first-class entity has a valid identifier and type;
- material claims carry provenance and confidence;
- references resolve to known entities or are explicitly marked unresolved;
- runtime observations are separated from nominal specifications;
- unknown values are represented explicitly rather than invented;
- changes remain reviewable through Git history.

The existing v0 files are considered **legacy-compatible input**. Adoption of this specification does not require an immediate destructive migration.

## 5. Core entity types

The controlled entity vocabulary is divided into domains.

### 5.1 Building and spatial entities

- `building`
- `floor`
- `space`
- `zone`
- `envelope_element`
- `window`
- `door`
- `opening`

### 5.2 Technical entities

- `system`
- `asset`
- `component`
- `network_node`
- `meter`
- `sensor`
- `actuator`
- `control_point`

### 5.3 Software and operational entities

- `automation`
- `policy`
- `dashboard`
- `runtime_entity`
- `integration`

### 5.4 Evidence and knowledge entities

- `document`
- `manual`
- `datasheet`
- `drawing`
- `photo`
- `measurement`
- `runtime_evidence`
- `decision`
- `maintenance_event`
- `incident`
- `open_question`

### 5.5 External entities

- `person`
- `supplier`
- `installer`
- `manufacturer`

New entity types MAY be introduced only when no existing type represents the concept without semantic distortion. Additions SHOULD update this specification or an approved controlled vocabulary file.

## 6. Identifier convention

Canonical identifiers MUST use lowercase ASCII tokens separated by dots:

```text
<type>.<scope>.<name>
```

Examples:

```text
building.casa_mercurio
space.ground_floor.giorno
system.hvac.vmc
asset.vmc.main
asset.heat_pump.main
sensor.bagno.relative_humidity
actuator.vmc.speed_3
automation.vmc.bathroom_boost
decision.2026.plenum_sealing
maintenance.2026.vmc_plenum_sealing
```

Rules:

- identifiers MUST be unique within the dataset;
- identifiers MUST NOT contain spaces or accented characters;
- identifiers SHOULD describe identity, not mutable state;
- sequential numbers MAY be used when no meaningful stable name exists;
- Home Assistant `entity_id` values MUST be stored as external runtime identifiers, not reused automatically as digital twin IDs.

## 7. Minimum entity envelope

Each first-class entity MUST support this logical structure:

```yaml
id: asset.vmc.main
type: asset
name: Main ventilation unit
status: active
version: 1
confidence: documented
sources:
  - source_id: document.manual.vmc_ris_m9_22_ha
    locator: "p. 2"
created_at: 2026-06-29
updated_at: 2026-07-30
owner: aeb
attributes: {}
used_by: []
```

### 7.1 Required fields

- `id`
- `type`
- `name`
- `status`
- `confidence`
- `sources`

### 7.2 Recommended fields

- `version`
- `created_at`
- `updated_at`
- `owner`
- `attributes`
- `used_by`
- `notes`

Unknown values MUST be `null`, omitted when optional, or represented by an `open_question` reference. Placeholder strings such as `TBD`, `unknown_model_1` or invented defaults SHOULD NOT be used.

## 8. Status vocabulary

Entity lifecycle status SHOULD use:

- `planned`
- `installed`
- `active`
- `inactive`
- `maintenance`
- `faulted`
- `retired`
- `removed`
- `unknown`

Status describes lifecycle or operational availability, not evidence quality.

Example: a VMC may have `status: maintenance` and still have `confidence: verified` for its installed model.

## 9. Confidence vocabulary

The canonical confidence levels are:

- `verified` — confirmed against installed reality through direct inspection, nameplate, authoritative project evidence or equivalent strong evidence;
- `measured` — obtained through a documented measurement process;
- `runtime_observed` — observed in a defined runtime evidence window;
- `documented` — supported by a manual, datasheet, drawing, invoice or other document, but not necessarily verified as installed reality;
- `user_reported` — explicitly supplied by the owner but not independently verified;
- `inferred` — reasoned from available evidence;
- `estimated` — approximate value with stated assumptions;
- `to_confirm` — candidate value or unresolved claim;
- `unknown` — no usable value is available.

Legacy v0 confidence values MAY be retained temporarily. Migration SHOULD map them to this vocabulary.

Confidence MUST describe the individual claim where claims have different evidence strengths. A single entity-level confidence MUST NOT conceal weaker material attributes.

## 10. Source and evidence model

### 10.1 Source types

Controlled source types include:

- `repository`
- `dropbox_manual`
- `dropbox_document`
- `photo`
- `nameplate`
- `drawing`
- `invoice`
- `project_document`
- `home_assistant_runtime`
- `runtime_evidence_snapshot`
- `measurement`
- `survey`
- `user_report`
- `chat_record`
- `calculation`
- `external_reference`

### 10.2 Evidence reference

Material claims SHOULD use structured evidence references:

```yaml
sources:
  - source_id: document.manual.vmc_ris_m9_22_ha
    source_type: dropbox_manual
    locator: "technical data table"
    observed_at: null
    captured_at: 2026-06-29
    note: "Manual covers RIS M9 22 HA."
```

A source path or URL SHOULD NOT be the sole identifier because storage locations may change.

### 10.3 Claim-level provenance

Where an attribute can be disputed or updated independently, it SHOULD use a claim envelope:

```yaml
model:
  value: RIS M9 22 HA
  confidence: verified
  sources:
    - source_id: evidence.nameplate.vmc_main
```

For compact, low-risk records, entity-level provenance MAY be used when all attributes share the same source and confidence.

## 11. Temporal model

The following timestamps have distinct meanings:

- `created_at` — record creation date;
- `updated_at` — last semantic update;
- `observed_at` — when a state or measurement was observed;
- `valid_from` / `valid_to` — interval in which a fact is considered true;
- `installed_at` — physical installation date;
- `removed_at` — physical removal date.

Runtime values MUST include an observation timestamp or evidence window. A current-state assertion without temporal context MUST NOT be archived as durable knowledge.

## 12. Relation model

Relations connect existing entity identifiers.

Minimum relation structure:

```yaml
id: relation.vmc_main.supplies.camera_01
source: asset.vmc.main
relation: supplies_air_to
target: space.ground_floor.camera_01
status: active
confidence: verified
sources:
  - source_id: drawing.vmc.distribution
```

### 12.1 Controlled relation vocabulary

#### Spatial and containment

- `contains`
- `part_of`
- `located_in`
- `installed_on`
- `adjacent_to`
- `serves`

#### Physical and energy flow

- `connected_to`
- `supplies_air_to`
- `extracts_air_from`
- `supplies_heat_to`
- `supplies_cooling_to`
- `supplies_hot_water_to`
- `powered_by`
- `meters`

#### Sensing and control

- `measures`
- `observes`
- `commands`
- `controls`
- `actuates`
- `triggers`
- `depends_on`
- `inhibits`
- `overrides`

#### Documentation and evidence

- `documents`
- `evidences`
- `derived_from`
- `supersedes`
- `resolves`

#### Operations and lifecycle

- `maintains`
- `affected_by`
- `caused_by`
- `replaced_by`
- `requires`

Relations SHOULD be directional and semantically precise. Generic `related_to` SHOULD be avoided except during temporary ingestion.

## 13. Asset model

An `asset` is an individually identifiable installed item with operational or maintenance relevance.

Recommended asset attributes:

```yaml
manufacturer:
family:
model:
serial_number:
installation_location:
installed_at:
commissioned_at:
manual_refs: []
nameplate_evidence: []
runtime_entity_refs: []
maintenance_plan_ref:
nominal_specs: {}
observed_runtime: {}
```

Family-level possible models MUST be represented separately from `model` and marked `documented` or `to_confirm`.

## 14. Space model

A `space` represents a physical room or volume.

Recommended attributes:

```yaml
floor_ref:
use:
area_m2:
height_m:
volume_m3:
orientation:
adjacent_space_refs: []
envelope_element_refs: []
window_refs: []
door_refs: []
sensor_refs: []
actuator_refs: []
supplied_by: []
extracted_by: []
```

A space MUST NOT embed the complete records of sensors, assets or envelope elements. It SHOULD reference their identifiers.

## 15. Sensor, actuator and runtime entity model

A physical sensor or actuator and its Home Assistant representation are distinct concepts.

Example:

```yaml
id: sensor.bagno.relative_humidity
type: sensor
attributes:
  quantity: relative_humidity
  unit: "%"
  physical_location:
    space_ref: space.ground_floor.bagno
    height_m: null
  accuracy: null
  calibration_ref: null
  runtime_entity_refs:
    - runtime_entity.home_assistant.sensor_bagno_umidita
```

A `runtime_entity` SHOULD record:

- platform;
- external identifier;
- device or integration reference;
- unit and device class;
- availability expectations;
- source mapping;
- last verification date.

Renaming a Home Assistant entity MUST NOT force a change to the physical sensor ID.

## 16. Nominal, observed and derived data

### 16.1 Nominal specifications

Nominal specifications describe manufacturer or design expectations.

```yaml
nominal_specs:
  airflow_at_100_pa_m3_h:
    value: 269
    confidence: documented
    sources:
      - source_id: document.manual.vmc_ris_m9_22_ha
```

### 16.2 Observed runtime

Observed runtime MUST include a time or evidence window and acquisition source.

```yaml
observed_runtime:
  - metric: electrical_power
    value: 82
    unit: W
    observed_at: 2026-08-10T14:30:00+02:00
    confidence: runtime_observed
    source_id: runtime_evidence.vmc.power_test_speed_2
```

Long time-series SHOULD remain in the runtime database. The repository SHOULD store mappings, curated snapshots, baselines, test results and durable conclusions rather than duplicating the full recorder history.

### 16.3 Derived values

Derived values MUST identify their method and inputs:

```yaml
derivation:
  method: arithmetic_mean
  input_refs:
    - runtime_evidence.vmc.power_test_speed_2
  assumptions: []
```

## 17. Decision knowledge

A decision record SHOULD contain:

```yaml
id: decision.2026.plenum_sealing
type: decision
name: Seal the VMC plenums with butyl tape
status: accepted
context: Air leakage found at sheet-metal plenums.
options:
  - silicone
  - butyl tape
  - EPDM system
selected_option: butyl tape
rationale:
  - removable for inspection
  - suitable for irregular joints
consequences: []
evidence_refs: []
related_entity_refs:
  - component.vmc.supply_plenum
  - component.vmc.extract_plenum
decided_at: 2026
supersedes: null
```

Decisions MUST preserve rationale and alternatives when these are known. A changed decision SHOULD create a new record linked with `supersedes`; history SHOULD NOT be overwritten.

## 18. Maintenance and incident knowledge

Maintenance events SHOULD record:

- affected asset or component;
- date and performer;
- work performed;
- materials and replacement parts;
- before/after evidence;
- measurements;
- next due condition or date;
- resulting status.

Incidents SHOULD distinguish symptoms, confirmed cause, corrective action and unresolved hypotheses.

## 19. Document model

Documents SHOULD be registered as entities even when the binary file remains in Dropbox.

Recommended fields:

```yaml
id:
type:
title:
document_date:
manufacturer:
model_scope: []
storage:
  provider: dropbox
  path:
content_hash: null
language:
status:
```

Manuals covering multiple models MUST list their model scope. Presence of a model in a manual MUST NOT prove installation.

## 20. File organization

Target organization:

```text
data/
  building.yaml
  spaces/
  assets/
  sensors/
  actuators/
  runtime_entities/
  relationships.yaml
  documents.yaml
  knowledge/
    decisions/
    maintenance/
    incidents/
    measurements/
  open_questions.yaml
```

The current v0 files MAY remain during migration:

```text
data/building_core.yaml
data/rooms.yaml
data/systems.yaml
data/sensors_actuators.yaml
data/open_questions.yaml
```

Migration SHOULD be incremental and reviewable. A file split MUST NOT silently alter meaning or confidence.

## 21. Validation rules

Automated validation SHOULD eventually enforce:

1. unique identifiers;
2. allowed entity and relation types;
3. valid confidence and status values;
4. resolvable internal references;
5. ISO 8601 dates and timestamps;
6. explicit units for physical quantities;
7. no credentials or sensitive secrets;
8. no runtime observation without temporal context;
9. no exact installed model supported only by a multi-model family manual;
10. no dangling `used_by` or relationship references unless explicitly unresolved.

## 22. Privacy and security

The data layer MUST NOT contain:

- passwords;
- API tokens;
- private keys;
- unrestricted access URLs;
- precise personal data not required for engineering use.

Exact address and coordinates SHOULD be isolated or redacted when not operationally necessary.

Runtime imports MUST use an approved evidence boundary and MUST NOT make the repository a substitute secrets store.

## 23. Versioning and change management

This specification uses semantic versioning at the document level:

- patch: clarification without semantic change;
- minor: backward-compatible vocabulary or field addition;
- major: incompatible change to identity, required fields or semantics.

Entity `version` numbers represent the semantic evolution of individual curated records. Git history remains the authoritative change log.

Material schema changes SHOULD include:

- migration impact;
- compatibility decision;
- affected files;
- validation updates;
- rollback or recovery path where relevant.

## 24. Initial adoption plan

Adoption SHOULD proceed in the following order:

1. register stable IDs for existing building, spaces and systems;
2. create an asset register from verified nameplates and installed documentation;
3. register Dropbox manuals and drawings as document entities;
4. map physical sensors and actuators to Home Assistant runtime entities;
5. create the first controlled relationships;
6. migrate decisions and maintenance records;
7. add schema validation;
8. resume runtime evidence acquisition after systems return to service.

The first implementation target is `data/assets.yaml` or `data/assets/`, populated without guessing exact models or serial numbers.

## 25. Current known constraints

At publication of this draft:

- the VMC is offline for maintenance, so current runtime baselines are intentionally deferred;
- the VMC installed model is documented as RIS M9 22 HA;
- heat pump, DHW and Toshiba AC families are documented, but exact installed models remain to be verified;
- the SolarEdge inverter model is documented as SE6000H;
- existing data contains mixed legacy confidence terms that require gradual normalization;
- Dropbox documents and repository data are available, while live Home Assistant recorder access is not assumed by this specification.

## 26. Acceptance criteria for v1 adoption

This draft can be marked **Adopted** when:

- controlled vocabularies have been reviewed;
- identifier rules are accepted;
- at least one complete asset record conforms;
- at least one relationship chain resolves end-to-end;
- legacy v0 compatibility is documented;
- no runtime-control behaviour is changed by adoption.
