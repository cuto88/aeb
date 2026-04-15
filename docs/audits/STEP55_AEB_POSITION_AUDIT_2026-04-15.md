# STEP55 AEB Position Audit (2026-04-15)

## Scope
- Valutare la posizione corrente del repository `aeb` rispetto a una traiettoria `AEB` realistica.
- `AEB` qui significa: edificio con osservabilita`, arbitraggio e uso attivo dell’energia, non solo controllo HVAC di base.

## AEB definition used here
- Per questo repo `AEB` non coincide con “c’e` automazione”.
- Il livello minimo difendibile e`:
  - osservabilita` runtime utile
  - controllo attuatori con authority chiara
  - policy layer che decide tra comfort, energia e vincoli
  - KPI e trail audit
  - almeno un perimetro di actuation live sicuro e governato

## FACT

### 1. La base di orchestrazione esiste gia`
- Heating / AC / VMC sono gia` dentro il perimetro `ClimateOps`.
- Esistono:
  - layer contratti/policy
  - sensori di reason/explainability
  - KPI AEB
  - plancia operativa unificata
- La closure di authority baseline ClimateOps e` gia` assorbita nei current status recenti.

### 2. Un primo perimetro AEB live esiste davvero
- Il writer path DHW / EHW e` chiuso e formalizzato.
- La catena read-feedback + writer + riconciliazione post-live e` trattata come `CLOSED`.
- Questo significa che il sistema non e` piu` solo “advisory”: almeno un dominio e` arrivato a un’azione live governata.

### 3. L’osservabilita` AEB e` migliorata ma resta a perimetro stretto
- Esiste un primo layer `AEB MVP` con osservabilita`, outcome e gate.
- Il refresh del `2026-04-15` ha anche rafforzato:
  - fallback temperatura esterna
  - toolkit audit involucro
  - hygiene Git/ops
- Questi elementi non chiudono AEB da soli, ma migliorano la qualita` della base di controllo.

### 4. La multi-load orchestration non e` ancora chiusa
- MIRAI non e` ancora chiuso come carico AEB dispatchable governato.
- AC single-writer authority cleanup resta aperto.
- Il planner DHW non e` ancora promosso a policy piena.
- Quindi l’AEB esiste come struttura e come primo pass live, ma non ancora come sistema multi-carico maturo.

### 5. Il filone supervisor non sposta ancora il giudizio AEB
- Il supervisor/n8n introdotto il `2026-04-15` e` al momento `DRAFT / PARTIAL`.
- Migliora governance e reportistica potenziale, ma non cambia ancora il livello di chiusura AEB.

## RISKS
- Confondere “ClimateOps orchestrator” con “AEB gia` completo”.
- Sopravvalutare la chiusura del dominio DHW/EHW e trasferirla automaticamente a MIRAI o AC.
- Considerare il planner o i KPI come equivalenti a una reale orchestrazione multi-load chiusa.
- Lasciare aperta l’ambiguita` AC writer e poi usare quel dominio come se fosse gia` pienamente governato.

## DRIFT
- Nessun drift forte tra naming repo (`aeb`) e direzione architetturale.
- Drift ancora presente tra:
  - ambizione AEB dichiarata
  - chiusura effettiva dei carichi dispatchable oltre il solo DHW/EHW
- In pratica:
  - `AEB as architecture`: reale
  - `AEB as mature multi-load operating system`: non ancora chiuso

## JUDGEMENT

### AEB posture
- `PARTIAL but real`

### Why
- Il sistema ha superato il livello “solo BMS/HVAC scripting” perche':
  - esiste arbitraggio tra domini
  - esiste policy layer
  - esiste audit trail
  - esiste almeno un path live governato
- Pero` non e` ancora un AEB pienamente chiuso perche':
  - manca la closure su MIRAI
  - manca la closure completa AC authority
  - manca una multi-load policy live piu` ampia

## Practical conclusion
- Oggi `ClimateOps` si puo` descrivere come:
  - piu` avanzato di un semplice controllo HVAC locale
  - vicino a un “energy-aware building control layer”
  - ancora sotto un AEB pienamente maturo

## NEXT ACTION
1. Chiudere `MIRAI runtime truth`.
2. Chiudere `AC single-writer authority cleanup`.
3. Definire un boundary ristretto ma reale per `MIRAI inside AEB`.
4. Promuovere il judgement AEB solo dopo una seconda closure live oltre il solo DHW/EHW.
