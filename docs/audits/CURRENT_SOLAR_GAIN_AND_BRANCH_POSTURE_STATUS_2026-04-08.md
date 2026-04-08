# Current Solar Gain And Branch Posture Status (2026-04-08)

## Scope
- Punto di ingresso unico per lo stato corrente del filone Solar Gain advisory + MIRAI branch posture.
- Riassume il passaggio da scaffold iniziale a runtime fix e postura attuale.

## Executive summary
- Solar Gain module scaffold: `CLOSED`
- Solar Gain active operator view: `Passive House` inside `lovelace/climate_casa_unified_plancia.yaml`
- Solar Gain runtime inputs on 2026-04-07 before fixes: `NOT READY`
- Solar Gain blocker from seasonal posture/current branch semantics: `CLOSED`
- Solar Gain calibration for decision-grade use: `OPEN`
- MIRAI branch posture semantics: `CLOSED`
- MIRAI full runtime truth for governed AEB use: `PARTIAL`

## Current position

### Solar Gain
- The advisory module exists and is structurally integrated.
- The standalone dashboard path has been retired; the active operator entrypoint is the unified climate dashboard.
- The first runtime audit on `2026-04-07` showed real passive gain but also showed that the advisory layer was blocked by missing/unknown inputs.
- After posture fixes, the module is no longer considered blocked by seasonal branch state alone.

### MIRAI branch posture
- Runtime semantics now distinguish:
  - intentionally unpowered branch
  - valid Modbus link
  - real fault or invalid payload
- This closes interpretive noise but does not by itself close full MIRAI runtime truth under real demand.

## Runtime judgement
- Solar Gain package posture: `GO`
- Solar Gain calibration posture: `WATCH / OPEN`
- MIRAI branch semantics: `GO`
- MIRAI AEB promotion readiness: `HOLD`

## Historical sources absorbed by this summary
- `STEP48_SOLAR_GAIN_ADVISORY_SCAFFOLD_2026-04-06.md`
- `STEP52_SOLAR_GAIN_RUNTIME_AUDIT_2026-04-07.md`
- `STEP53_MIRAI_BRANCH_POWER_AND_SOLAR_GAIN_CLOSURE_2026-04-07.md`
- `CURRENT_RUNTIME_STATUS_2026-04-08.md`

## Use rule
- Use this file when the question is “what is the current status of Solar Gain and MIRAI branch posture?”
- Use the original `STEP48`, `STEP52`, `STEP53` notes when the question is forensic or tied to the exact runtime evidence of 2026-04-07.
