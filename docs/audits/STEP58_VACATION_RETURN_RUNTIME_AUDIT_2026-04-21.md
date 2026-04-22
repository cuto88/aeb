# STEP58 Vacation return runtime audit (2026-04-21)

## Scope
- Verificare il comportamento operativo dopo circa 5 giorni di assenza.
- Contesto umano dichiarato: durante la vacanza qualcuno e` comunque entrato in casa.
- Verificare se `vacation mode`, feedback scuri e supervisor hanno prodotto evidenza utile.

## Evidence sources
- `docs/audits/STEP57_FIVEDAY_UNATTENDED_VALUE_PLAN_2026-04-15.md`
- `docs/audits/CURRENT_SUPERVISOR_STATUS.md`, generato `2026-04-21T08:00:15Z`
- Home Assistant `core.restore_state`
- Home Assistant recorder nuovo post-reset, interrogato dopo il recovery del recorder
- Home Assistant core logs

## Finding 1 - Supervisor did run, but only as repo/process monitor
- `CURRENT_SUPERVISOR_STATUS.md` e` stato generato il `2026-04-21T08:00:15Z`.
- Il report identifica correttamente:
  - branch `main`
  - ultimi commit relativi a `vacation mode` e feedback scuri
  - tre path untracked residui
  - stato `NO-GO` per drift documentale
- Non contiene pero` una vera analisi runtime dei 5 giorni.

Verdetto:
- supervisor utile come sentinella repo/audit
- supervisor non ancora sufficiente come audit runtime autonomo

## Finding 2 - Vacation mode risulta `off` al rientro
- Stato persistito in `core.restore_state`:
  - `input_boolean.policy_vacation_mode = off`
  - timestamp `2026-04-21T20:53:46Z`
- Stato recorder post-reset:
  - `input_boolean.policy_vacation_mode = off`
  - `binary_sensor.cm_policy_vacation_mode = off`
  - `binary_sensor.policy_allow_ac = on`
  - `binary_sensor.policy_allow_vmc_boost = on`
  - `binary_sensor.policy_allow_shift_load = on`
  - `binary_sensor.climateops_noncritical_loads_allowed = on`

Interpretazione:
- al momento della verifica il sistema non era piu` in assetto vacanza
- se qualcuno e` entrato in casa, non abbiamo evidenza affidabile dal recorder storico per distinguere:
  - vacation mode mai attivato
  - vacation mode attivato e poi spento
  - vacation mode spento per uso reale della casa

## Finding 3 - Feedback scuri manuali non usati
- Stato persistito in `core.restore_state`:
  - `input_boolean.envelope_giorno_shade_applied = off`
  - `input_boolean.envelope_notte1_shade_applied = off`
  - `input_boolean.envelope_notte2_shade_applied = off`
  - `input_boolean.envelope_bagno_shade_applied = off`
  - `binary_sensor.envelope_any_shade_applied = off`
  - `sensor.envelope_shade_applied_rooms = none`

Interpretazione:
- il layer manuale scuri esiste ed e` caricato
- non e` stato usato come evidenza operatore durante la finestra
- dato che il bagno non ha scuro reale, il suo helper resta da correggere in un cleanup successivo

## Finding 4 - Stato involucro corrente post-reset
Snapshot recorder post-reset:
- `sensor.envelope_recommended_action = keep_closed`
- `sensor.envelope_worst_room_name = notte2`
- `sensor.envelope_house_night_flush_potential = none`
- `sensor.t_in_med = 21.43`
- `sensor.t_in_notte2 = 21.7`
- `sensor.t_in_bagno = 21.5`
- `sensor.t_out_effective = 16.7`
- `switch.heating_master = off`
- `switch.ac_giorno = unknown`
- `switch.ac_notte = unknown`

Interpretazione:
- al rientro il comportamento non mostra emergenza termica
- `notte2` resta la stanza sentinella
- AC resta non informativa perche' gli switch sono `unknown`

## Finding 5 - L'audit storico 16-21 aprile e` compromesso dal recorder
- Il recorder HA ha rinominato il database storico:
  - `/homeassistant/home-assistant_v2.db.corrupt.2026-04-21T20:44:59.837397+00:00`
- Il nuovo DB contiene solo evidenza post-reset.
- Il file storico `.corrupt` non e` interrogabile con SQLite da SMB:
  - errore: `file is not a database`

Conseguenza:
- non possiamo produrre un audit quantitativo affidabile sui 5 giorni completi dal recorder locale
- qualunque giudizio sui giorni di vacanza deve essere marcato come `PARTIAL / evidence-limited`

## Verdict
- Vacation-mode runtime evidence: `PARTIAL`
- Supervisor unattended value: `PARTIAL but useful`
- Involucro post-return state: `OK, no obvious emergency`
- Five-day historical audit quality: `BLOCKED by recorder DB incident`
- Human presence during vacation: `not reconstructable from current evidence`

## Required follow-up
1. Correggere il modello scuri rimuovendo `bagno` dal feedback manuale, o marcarlo esplicitamente `not_applicable`.
2. Decidere se `vacation mode` deve avere un audit sensor persistente dedicato, meno dipendente dal recorder storico.
3. Chiudere l'incidente recorder come audit separato.
4. Non usare questa finestra come base decision-grade per solar gain o Passivhaus closure.

