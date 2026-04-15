# MIRAI Profiled Mapping Plan

## Objective

- introdurre una struttura di mapping MIRAI basata su profili, non monolitica;
- preservare il namespace macchina gia' provato in runtime;
- validare il namespace Smart-MT in modalita' read-first;
- evitare promozioni premature di registri documentati ma non ancora corroborati sul campo.

## FACT

- namespace macchina provato:
  - `1003` status word
  - `1208` status code
  - `1209` fault code
- Smart-MT documenta registri aggiuntivi, ma l'evidenza runtime mostra drift o disponibilita' parziale su alcuni parametri.
- il manuale corretto usa `PW 59` come livello service HMI, non come procedura Modbus di unlock documentata.
- il repo contiene gia' un mapping stabile separato in [MIRAI_MODBUS_MAPPING.md](C:\2_OPS\aeb\docs\logic\core\MIRAI_MODBUS_MAPPING.md).

## Current Constraints

- Smart-MT presente.
- ACS / DHW non collegata.
- Febos-Crono Master non installato.
- prima passata solo read-only.
- nessuna scrittura live su registri service/config.
- nessuna assunzione di universalita' tra manuali, firmware, revisioni macchina.

## Layers

### Machine namespace

- ruolo: stato macchina minimo affidabile.
- registri stabili: `1003`, `1208`, `1209`.
- uso: readiness, stato, fault, diagnostica base runtime.
- requisito: resta intatto e separato da ogni discovery Smart-MT.

### Smart-MT namespace

- ruolo: sensori/logica controller, output DO/AO, sonde documentate.
- stato: documentato da manuale, ma da validare per profilo reale macchina/controller.
- uso: solo discovery read-first finche' non esiste evidenza runtime ripetuta.

## Why Profile-Based Mapping

- manuali e revisioni firmware possono divergere.
- la semantica di un registro documentato puo' non essere disponibile o non essere popolata sul profilo reale.
- il repo deve supportare almeno:
  - profilo `machine_stable`
  - profilo `smartmt_probe_readonly`
  - eventuali profili futuri per revisioni diverse
- il fallback corretto non e' un unico mapping globale, ma un set di profili piccoli e verificabili.

## Test Strategy

### Phase 0

- non toccare il profilo stabile macchina.
- usare il profilo stabile come baseline di verita' minima.

### Phase 1

- abilitare solo probe Smart-MT read-only a polling lento.
- testare i candidati ammessi in queste finestre:
  - idle
  - real heating run
  - transition/startup se disponibile

### Phase 2

- confrontare ogni candidato con:
  - realta' fisica
  - sensori runtime gia' esistenti
  - consistenza su letture ripetute

### Phase 3

- promuovere nel profilo stabile solo i candidati che passano i criteri di accettazione.
- lasciare gli altri in registry come `candidate`, `excluded` o `rejected_by_runtime`.

## Allowed Read-Now Candidates

- `8986`
- `8987`
- `8988`
- `9007`
- `9043`
- `9003`
- `9004`
- `9005`
- `9002`
- `9001`

## Explicit Exclusions

### ACS / DHW not connected

- `8989`
- `16395`

### Febos-Crono not installed

- `9146`
- `9147`
- `9148`
- `9151`
- `9066`
- `9152`
- `9153`

### Service / config do not write live

- `9024`
- `16394`
- `16392`
- `16393`

## Acceptance Criteria For Stable Promotion

- almeno due finestre runtime distinte con comportamento coerente.
- correlazione con realta' fisica osservabile.
- nessuna dipendenza non spiegata da stato macchina/rumore Modbus.
- nessun impatto negativo sul bus o sul profilo stabile.
- naming semantico difendibile.
- nessuna ambiguita' residua su layer:
  - `machine`
  - `smartmt`

## ASSUMPTION

- i registri `9001..9007` appartengono al layer Smart-MT output/state.
- `8986/8987/8988` sono sonde/controller-side documentate ma potrebbero avere scala o codifica non banale.

## RISK

- registro documentato ma vuoto/non implementato sul firmware reale.
- drift tra revisione manuale e profilo macchina installato.
- falsa promozione di un segnale correlato ma non causale.

## NEXT STEP

- usare [mirai_smartmt_candidates.yaml](C:\2_OPS\aeb\docs\mirai_smartmt_candidates.yaml) come registry operativo.
- abilitare temporaneamente [mirai_smartmt_probe.yaml](C:\2_OPS\aeb\packages\mirai_smartmt_probe.yaml) solo durante finestre di validazione.
- validare con la checklist in [MIRAI_SMARTMT_VALIDATION_CHECKLIST.md](C:\2_OPS\aeb\docs\MIRAI_SMARTMT_VALIDATION_CHECKLIST.md).
