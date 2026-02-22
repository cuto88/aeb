# Step 0 — Home Assistant Maturity Snapshot (Passivhaus/AEB)
Date: 2026-02-21
Scope: Read-only repository audit

## A) Repository & Configuration Topology

### FACT
- Runtime entrypoint is `configuration.yaml`, with package loading via `homeassistant: packages: !include_dir_named packages` (`configuration.yaml:8`).
- Themes are loaded via `!include_dir_merge_named themes` (`configuration.yaml:5`).
- Dashboards are YAML-defined from `lovelace/*.yaml` (`configuration.yaml:17` and below).
- Active runtime package files are flat in `packages/` (24 root YAML files) plus a `packages/climateops/` sub-tree present on disk.
- `packages/climateops.yaml` is comment-only (`packages/climateops.yaml:1`).
- Legacy markers exist in core climate modules: `climate_heating`, `climate_ventilation`, `climate_ventilation_windows`, `climate_ac_mapping`, `climate_ac_logic` (all start with `LEGACY MODULE`).
- Include-tree validation passed with 4 include directives scanned (`ops/gate_include_tree.ps1` run result).

### UNKNOWN
- Whether `packages/climateops/**/*.yaml` is effectively loaded at runtime in this environment (docs claim auto-include of all YAML under `packages/`, `docs/climateops/ENTRYPOINTS.md:4`, but no explicit include chain to subfolders is declared in YAML).

### Tree summary (runtime-relevant)
- `configuration.yaml`
- `packages/*.yaml` (climate, policy, contracts, energy, EHW, MIRAI, notify, migration boundary)
- `packages/climateops/**` (drivers/strategies/actuator/core/overrides; load status UNKNOWN)
- `lovelace/*.yaml`
- `docs/*` governance + logic docs + audits
- `_archive`, `_quarantine`, `_backup*` present (non-runtime by default)

### Entry points
- Core HA: `configuration.yaml`
- Climate logic: `packages/climate_*.yaml`
- Energy/PV: `packages/energy_pm.yaml`, `packages/energy_pv_solaredge.yaml`
- DHW/ACS telemetry: `packages/ehw_modbus.yaml`
- Policy/contracts: `packages/climate_policy_*.yaml`, `packages/climate_contracts.yaml`, `packages/cm_naming_bridge.yaml`

### Include graph
- `configuration.yaml` -> `packages/` (named include)
- `configuration.yaml` -> `themes/`
- `configuration.yaml` -> `lovelace/*.yaml` dashboards
- No `!include` directives found inside `packages/*.yaml` (flat package definitions)

## B) Subsystem Inventory (FACTUAL)

### Heating
- Inputs: indoor zone temps, outdoor temp, helper setpoints/hysteresis/windows, surplus policy (`packages/climate_heating.yaml`, `packages/climate_policy_energy.yaml`).
- Decision logic: template-driven priority/reason (`sensor.heating_reason`, `sensor.heating_priority`) with anti-frost/comfort/PV/night/manual branches (`packages/climate_heating.yaml:285+`).
- Outputs: template switch `switch.heating_master` drives physical relay `switch.4_ch_interrutore_3` via inverted logic (`packages/climate_heating.yaml:482+`).
- Deterministic vs heuristic: deterministic threshold/state logic.
- Time-based vs condition-based: both (time windows + conditions).
- Centralized vs scattered: mostly centralized in one file.

### Cooling (AC)
- Inputs: `t_in_med`, `t_out`, `ur_in_media`, `ur_out`, manual helpers, lock timers (`packages/climate_ac_mapping.yaml`, `packages/climate_ac_logic.yaml`).
- Decision logic: failsafe/lock/hook scaffolding exists; legacy control automations are commented out (`packages/climate_ac_logic.yaml:313+`).
- Outputs: scripts can apply `switch.ac_giorno` / `switch.ac_notte`; active automations mainly hook timeout + notifications, not full cooling arbitration.
- Deterministic vs heuristic: deterministic where implemented.
- Time-based vs condition-based: mostly condition/event-based.
- Centralized vs scattered: split across mapping + logic; active control path is partial.

### DHW / ACS
- Inputs: Modbus registers + calibration helpers (`packages/ehw_modbus.yaml`).
- Decision logic: telemetry transformation, scaling, readiness/running inference.
- Outputs: sensors/binary_sensors (tank top/bottom, setpoint, running). No actuator service logic found.
- Deterministic vs heuristic: deterministic transformations.
- Time-based vs condition-based: polling + template conditions.
- Centralized vs scattered: centralized in one package.

### VMC (mechanical ventilation)
- Inputs: indoor/outdoor T/RH/AH, bathroom RH, season override, thresholds, policy flag (`packages/climate_ventilation.yaml`).
- Decision logic: priority and reason templates (`sensor.ventilation_priority`, `sensor.ventilation_reason`), freecooling candidate/status, anti-dry, bathroom boost.
- Outputs: message/debug and backup sync automations; no direct VMC relay actuation in this legacy file.
- Deterministic vs heuristic: deterministic threshold/state logic.
- Time-based vs condition-based: both.
- Centralized vs scattered: mostly centralized in one file.

### Natural ventilation
- Inputs: window state aliases (`input_boolean.vent_finestra_*`), meteo OK binary sensor.
- Decision logic: aggregated window/open-count + `sensor.clima_open_windows_recommended`.
- Outputs: recommendation sensor + text message.
- Deterministic vs heuristic: deterministic thresholds.
- Time-based vs condition-based: both.
- Centralized vs scattered: split between `climate_ventilation_windows.yaml`, `climate_ventilation.yaml`, `stub_ventilation_meteo.yaml`.

### Energy / PV / grid
- Inputs: SolarEdge production entities, powermeter entities, legacy `binary_sensor.surplus_ok` abstraction.
- Decision logic: PV and PM are mostly metering; surplus policy is pass-through fail-safe abstraction (`packages/climate_policy_energy.yaml`).
- Outputs: utility_meter/statistics/template KPIs; no explicit grid dispatch or load control in active packages shown.
- Deterministic vs heuristic: deterministic.
- Time-based vs condition-based: both (utility/statistics + conditions).
- Centralized vs scattered: metering centralized; climate-energy coupling via policy sensor.

## C) Coupling & Fragility Analysis

### FACT
- Hard-coded actuator dependencies are extensive: `switch.vmc_vel_*`, `switch.heating_master`, `switch.4_ch_interrutore_3`, `switch.ac_giorno/notte`.
- Cross-module hard dependencies: heating relies on `binary_sensor.policy_surplus_ok` (`packages/climate_heating.yaml:300`), policy relies on `binary_sensor.surplus_ok` (`packages/climate_policy_energy.yaml:9`).
- Contract layer includes architectural placeholders:
- `Contract actuators defined` is forced `on` (`packages/climate_contracts.yaml:51-53`).
- `contract_surplus_ok_ready` checks `has_value('binary_sensor.surplus_ok')` (`packages/climate_contracts.yaml:26`).
- AC hook listener exists (`hook_vmc_request_ac_block`) but no emitter found in runtime YAML.
- TODO indicates unfinished freecooling-window closure coupling (`packages/climate_ventilation.yaml:354`).

### Coupling level
HIGH

### Regression risk zones
- Climate-energy interface (`policy_surplus_ok` / missing or stale `surplus_ok`).
- AC control path (reason/priority scaffolding vs commented legacy controller).
- VMC/natural ventilation meteo-window assumptions (stub meteo + window alias booleans).
- ClimateOps vs legacy parallel presence (load/authority ambiguity).
- Entity naming bridge (`cm_*`) vs legacy ids where docs and runtime diverge.

## D) Observability & Explainability

### Explainability
- FACT: Present for heating/ventilation via `reason` and `priority` sensors.
- FACT: Telegram debug automation for priority changes exists (`packages/notify_telegram.yaml`).
- FACT: ClimateOps explainability helpers exist (`packages/climateops/core/explainability.yaml`) but runtime effectiveness is UNKNOWN if climateops sub-tree is not loaded.

### Debug/log surfaces
- Template reason sensors, runtime counters (`*_churn_suppressed`), history_stats sensors.
- Persistent notification/logbook exists for AC hook alert path.

### KPIs measurable
- Comfort: FACT (indoor averages/min, rooms below target, runtime stats).
- Energy: FACT (PV energy/power, PM daily/monthly/statistics).
- IAQ: PARTIAL FACT (humidity/absolute humidity available; no explicit CO2/VOC KPI entities found in runtime packages).

### Observability classification
PARTIAL

## E) Passivhaus Readiness Check

- Low-frequency control (anti short-cycling): PRESENT (heating and AC min_on/min_off locks declared).
- Inertia awareness (radiant systems): PARTIAL (heating windows + long-cycle semantics exist; control authority path partially implicit).
- IAQ priority (VMC baseline, humidity control): PARTIAL (humidity-based boost/anti-dry exists; meteo/IAQ inputs partly stubbed/document-drifted).
- Noise/night constraints: PARTIAL (night windows and anti-dry nighttime logic present; explicit noise policy not found).
- Window-open logic: PARTIAL (open-window recommendation exists; real contact sensors pending, TODO indicates alias booleans).

## F) AEB (Active Energy Building) Readiness

### Checks
- PV-aware logic: BASIC (heating references surplus policy; PV metering exists).
- Load shifting (preheat/precool/DHW): BASIC for heating precharge intent; DHW/AC shifting logic not evidenced in active runtime packages.
- Grid interaction awareness: NONE (no explicit tariff/grid import/export arbitration found).
- Energy hierarchy (self-consumption first): BASIC intent via surplus abstraction; full hierarchy orchestration not evidenced.

### AEB readiness
BASIC

## G) Predictive Readiness (NO DESIGN)

- Weather forecast input: UNKNOWN/ABSENT in runtime YAML (no forecast entity usage found).
- Outdoor temperature history: PARTIAL FACT (current outdoor temp used; continuity/retention UNKNOWN).
- PV forecast or production history: PARTIAL FACT (production history via utility_meter exists; forecast not found).
- Occupancy/schedule signals: PARTIAL FACT (time windows exist; no occupancy entities used).

### Predictive readiness classification
PARTIALLY READY

## H) Overall Maturity Scorecard (0-5)

| Area | Score |
|---|---|
| Modularity | 3/5 |
| Stability | 2/5 |
| Observability | 3/5 |
| Passivhaus alignment | 2/5 |
| AEB alignment | 1/5 |
| Predictive readiness | 2/5 |

## I) Key Risks & Blockers

### Top 5 technical risks
1. AC control logic appears partially deactivated/commented while diagnostics remain active (`packages/climate_ac_logic.yaml:313+`).
2. Surplus dependency chain may degrade to fail-safe-off if `binary_sensor.surplus_ok` is missing/unavailable.
3. Meteo and window logic rely on stub/alias entities (`packages/stub_ventilation_meteo.yaml`, `packages/climate_ventilation_windows.yaml:39`).
4. Contract actuator definition can report structurally OK even when operational assumptions are weak (`contract_actuators_defined` forced on).
5. Docs-runtime divergence is substantial (declared stack and hooks vs runtime evidence).

### Top 3 architectural blockers
1. Runtime authority ambiguity between legacy climate packages and ClimateOps sub-tree (load state UNKNOWN).
2. Cross-module hooks described in docs are not consistently implemented in active YAML.
3. Policy layer depends on external entities not declared in active energy control package set (`surplus_ok` producer not found here).

### Top 3 unknowns to clarify before migration
1. Whether `packages/climateops/**/*.yaml` is loaded and active in the deployed HA runtime.
2. Which external automation engine (if any) currently actuates VMC/AC beyond what is in this repo.
3. Real data continuity/quality (sensor availability, recorder retention, forecast feeds) in production runtime.

This system is not yet demonstrably SAFE to migrate incrementally toward Passivhaus/AEB without regression risk: it has strong structural pieces (modular packages, reason/KPI sensors, locks, policy/contract layers) but also material runtime ambiguities (legacy vs ClimateOps authority, partial AC control path, stubbed dependencies, and unresolved hook/document drift) that keep current migration safety at a cautious low-confidence level.
