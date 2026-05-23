# STEP113 - Source-side drift closure (2026-05-22)

## Scope
- Chiudere la sola parte source del drift planner/arbiter con il massimo ROI.
- Nessun cambio di logica funzionale.
- Nessun deploy runtime eseguito da questo step.

## FACT

- Il repository ora usa i nomi canonicali gia` definiti nel SOT:
  - `sensor.planner_recommended_mode`
  - `sensor.arbiter_suggested_mode`
  - `sensor.arbiter_suggested_reason`
- I riferimenti attivi sono allineati nei file di implementazione e nel contratto documentale:
  - `packages/cm_system_facade.yaml`
  - `packages/climate_ventilation_templates.yaml`
  - `docs/SOT_ENTITIES.md`
- Il residuo documentale rimasto e` una verifica runtime post-reload, non piu` un'ambiguita` di source.

## IPOTESI

- Confidenza alta: non ha senso tenere aperta a lungo una categoria di drift che ormai e` stata risolta lato source.
- Confidenza media: la conferma live post-reload restera` utile, ma non impedisce di chiudere la parte source come completata.

## DECISIONE

- Chiudere il drift lato source.
- Mantenere aperta solo la verifica runtime post-reload come follow-up minimo.
- Non toccare gli hardware backlog messi in standby.

## Residuo

- Verifica runtime post-reload ancora necessaria.
- Security hygiene resta aperta come follow-up separato.
