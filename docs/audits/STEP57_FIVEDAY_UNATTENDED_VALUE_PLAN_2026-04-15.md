# STEP57 Five-Day Unattended Value Plan (2026-04-15)

## Scope
- Definire cosa puo` produrre valore nei prossimi 5 giorni con presenza umana ridotta o assente.
- Obiettivo: usare il tempo per aumentare evidenza, ridurre drift e preparare chiusure, senza richiedere deploy autonomi o decisioni runtime non governate.

## Constraint
- Nessuna autonomia piena su deploy o attuazioni runtime sensibili.
- Uso ammesso:
  - osservazione read-only
  - sintesi supervisor
  - triage repo/audit
  - preparazione task bounded per Codex

## What is realistic in 5 days

### 1. Daily supervisor status
- Un report read-only al giorno su:
  - stato repo
  - audit recenti
  - drift o nuove incoerenze
  - priorita` del giorno
- Outcome utile:
  - niente dimenticanze
  - backlog vivo
  - visibilita` continua sugli open item

### 2. Involucro / Passivhaus evidence accumulation
- Se arrivano snapshot o storico runtime, consolidare:
  - stanza peggiore
  - posture `keep_closed / prepare_night_flush / open_for_night_flush`
  - robustezza del fronte `night flush`
- Outcome utile:
  - ridurre incertezza su `solar gain`
  - migliorare fiducia nel modello stanza-per-stanza

### 3. MIRAI documentation and validation preparation
- Raffinare il draft Smart-MT:
  - candidate registry
  - checklist
  - piano finestra runtime
- Outcome utile:
  - al rientro la sessione MIRAI parte con meno tempo perso

### 4. Supervisor closure work
- Allineare il draft supervisor al contratto documentato:
  - payload `runtime_evidence`
  - distinguere design vs implementation
  - rimuovere o classificare meglio artefatti placeholder
- Outcome utile:
  - trasformare il supervisor da “idea promettente” a strumento davvero usabile

### 5. Audit chain hygiene
- Tenere aggiornati:
  - `CURRENT_RUNTIME_STATUS_*`
  - indice audit
  - note di triage quando cambiano davvero gli open item
- Outcome utile:
  - evitare ritorno con trail rotto o stale

## What is not realistic unattended
- Chiudere davvero `MIRAI runtime truth` senza una finestra runtime osservata bene.
- Dichiarare `AEB complete`.
- Dichiarare `Passivhaus closed`.
- Promuovere `solar gain` ad azione-grade senza ulteriore evidenza.
- Fare deploy automatici o correzioni live non supervisionate.

## Best-case outcome after 5 days
- Supervisor piu` utile e piu` coerente con il suo contratto.
- Trail audit aggiornato e ordinato.
- Filone involucro piu` solido.
- MIRAI piu` pronto per una sessione di chiusura breve al rientro.
- Backlog ridotto ai veri blocker:
  - MIRAI runtime truth
  - AC authority cleanup
  - multi-load dispatch boundary

## Success criterion
- Al rientro, il lavoro da fare non e` “capire dove siamo”.
- Il lavoro da fare diventa solo “chiudere i 2-3 blocker finali”.

## Suggested mode while away
- `Supervisor`: osserva e riassume
- `Codex`: prepara audit, triage e task bounded
- `Human`: approva solo i passaggi finali quando rientra

## Practical conclusion
- Si`, questi 5 giorni possono essere utili.
- Non per rendere il sistema autonomo da solo.
- Si` per arrivare al rientro con:
  - meno incertezza
  - piu` evidenza
  - meno lavoro di orientamento
  - chiusura finale molto piu` corta
