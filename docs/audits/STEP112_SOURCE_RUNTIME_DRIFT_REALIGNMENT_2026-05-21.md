# STEP112 - Source/runtime drift realignment (2026-05-21)

## Scope
- Ridurre il drift tra source e runtime sui contratti planner/arbiter con il massimo ROI.
- Nessun cambio di logica funzionale.
- Nessun deploy runtime eseguito da questo step.

## FACT

- Il trail documentale indicava ancora drift bounded su:
  - planner recommended mode
  - arbiter suggested mode/reason
  - fallback facade
- I file source hanno ora riferimenti allineati ai nomi canonicali gia` documentati in SOT:
  - `sensor.planner_recommended_mode`
  - `sensor.arbiter_suggested_mode`
  - `sensor.arbiter_suggested_reason`
- Le modifiche toccano solo i punti di lettura, non la semantica della policy:
  - `packages/cm_system_facade.yaml`
  - `packages/climate_ventilation_templates.yaml`

## IPOTESI

- Confidenza alta: il valore operativo sta nel ridurre l’ambiguita` tra source, SOT e runtime, non nel moltiplicare nuovi alias.
- Confidenza media: il runtime dovra` essere reloadato o verificato per confermare che i nomi gia` attesi continuino a risolversi senza regressioni.

## DECISIONE

- Chiudere il drift a livello source.
- Tenere aperta la verifica runtime come follow-up minimo.
- Non toccare gli hardware backlog messi in standby.

## File toccati

- `packages/cm_system_facade.yaml`
- `packages/climate_ventilation_templates.yaml`

## Residuo

- Verifica runtime post-reload ancora necessaria.
- Security hygiene e` ancora aperta come follow-up separato.
