# STEP59 Home Assistant recorder DB incident (2026-04-21)

## Scope
- Documentare l'incidente recorder emerso durante il tentativo di audit post-vacanza.
- Separare il problema di osservabilita` dal comportamento ClimateOps/AEB.

## Timeline
- `2026-04-21T20:44:59Z`
  - Home Assistant rinomina il database storico in:
    - `/homeassistant/home-assistant_v2.db.corrupt.2026-04-21T20:44:59.837397+00:00`
  - viene creato un nuovo `/homeassistant/home-assistant_v2.db`.
- `2026-04-21T20:48-20:50Z`
  - log ripetuti recorder:
    - `SQLAlchemyError error processing task CommitTask()`
    - `sqlalchemy.orm.exc.StaleDataError`
    - `UPDATE statement on table 'states' expected to update 15 row(s); 0 were matched`
- Dopo restart controllato:
  - `ha core check`: passed
  - `ha core restart`: eseguito, timeout lato shell ma core tornato operativo
  - `ha core info`: Home Assistant `2026.4.2`, latest `2026.4.3`
  - log recorder post-restart:
    - `The system could not validate that the sqlite3 database ... was shutdown cleanly`
    - `Ended unfinished session`

## Current state after recovery
- Nuovo DB recorder attivo:
  - `/homeassistant/home-assistant_v2.db`
  - dimensione cresciuta dopo restart, quindi il recorder ha ripreso a scrivere
- DB storico conservato:
  - `/homeassistant/home-assistant_v2.db.corrupt.2026-04-21T20:44:59.837397+00:00`
- Hardlink diagnostico temporaneo creato per lettura SMB:
  - `/homeassistant/home-assistant_v2_corrupt_20260421T204459Z.db`
  - poi rimosso
- Il file originale `.corrupt` non e` stato rimosso.

## Recovery actions performed
- Config check:
  - `ha core check`
  - risultato: `Command completed successfully`
- Restart controllato:
  - `ha core restart`
  - timeout lato shell, ma `ha core info` ha confermato core operativo
- Verifica log:
  - dopo restart non e` stata osservata la stessa raffica continua di `StaleDataError`

## Risk assessment
- Perdita o indisponibilita` dello storico recorder recente: `HIGH`
- Stato runtime HA dopo recovery: `PASS with observation`
- Integrita` audit 16-21 aprile: `NO-GO for decision-grade analysis`
- Rischio ClimateOps immediato: `LOW`, perche' il problema e` osservabilita`/storico, non attuazione diretta

## Likely impact
- Audit quantitativi su:
  - vacation mode history
  - scuri manuali
  - night flush
  - solar gain
  - presenza/interventi umani
  risultano compromessi per la finestra coperta dal DB corrotto.

## Required follow-up
1. Monitorare per 24 ore che il nuovo recorder continui a crescere e non ripeta `StaleDataError`.
2. Non eliminare il file `.corrupt` finche' non si decide se tentare recovery offline.
3. Valutare backup/export periodico di evidenze audit minime fuori dal recorder.
4. Considerare un sensore/report giornaliero `vacation audit snapshot` generato su file, cosi` i prossimi audit non dipendono solo dal DB recorder.

## Verdict
- Recorder incident: `CONFIRMED`
- Immediate recovery: `DONE`
- Historical data recovery: `OPEN / uncertain`
- Audit consequence: la finestra vacanza resta `PARTIAL` e non decision-grade.

