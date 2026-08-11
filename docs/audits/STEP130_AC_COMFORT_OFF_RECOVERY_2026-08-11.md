# STEP130 — AC comfort OFF recovery (2026-08-11)

## Problema osservato

Sul runtime Home Assistant Docker corrente, `switch.ac_giorno` e` rimasto `on`
dopo il raggiungimento del comfort:

- `binary_sensor.ac_giorno_comfort_request = off`;
- `sensor.ac_giorno_comfort_reason = COMFORT_SATISFIED`;
- `sensor.climateops_hierarchy_mode = IDLE`;
- `binary_sensor.ac_giorno_lock_min_on_ok = on`;
- `switch.ac_giorno = on`.

Nello stesso momento `binary_sensor.cm_contract_actuators_ready = off`, perche`
gli attuatori `switch.vmc_vel_0` ... `switch.vmc_vel_3` erano `unavailable`.

## Root cause

L'automazione `automation.climateops_system_actuate` applicava il contratto
aggregato di readiness prima delle azioni. L'eccezione esistente consentiva di
superare il gate soltanto durante una richiesta `COOL_DAY`, `COOL_NIGHT` o
`COOL_BOTH`.

Quando il comfort diventava soddisfatto, la modalita` passava a `IDLE`. Con la
readiness aggregata falsa, l'automazione terminava quindi prima del ramo
`switch.turn_off`, anche se la zona AC era disponibile e il lock minimo ON era
gia` scaduto.

## Correzione

Il gate di `climateops_system_actuate` ora ammette anche un percorso di recovery
quando almeno una zona AC disponibile risulta ancora `on`.

La modifica non allarga i criteri di accensione: i rami ON continuano a
richiedere modalita` cooling, policy AC valida, ramo AC alimentato, assenza di
pausa automatica e lock minimo OFF soddisfatto. Il ramo OFF continua a richiedere
che il relativo lock minimo ON sia soddisfatto.

## Comportamento atteso

Con `ac_giorno = on`, richiesta comfort `off`, modalita` `IDLE` e VMC
indisponibile:

1. il gate iniziale non blocca piu` l'automazione;
2. `ac_day_should_run` risulta falso;
3. se `binary_sensor.ac_giorno_lock_min_on_ok = on`, viene inviato
   `switch.turn_off` a `switch.ac_giorno`;
4. il trigger periodico ogni due minuti garantisce il retry quando il lock non e`
   ancora scaduto al primo passaggio.

## Validazione e pubblicazione

- gate aggregato `ops/gates_run_ci.ps1`: PASS, `ALL GATES PASSED`, con
  `yamllint 1.38.0` gia` installato nell'ambiente utente e aggiunto
  temporaneamente al `PATH` del processo;
- config check Home Assistant pre-deploy: PASS;
- commit funzionale pubblicato su `main`:
  `2abe21618f6f636d5439a5d1e567a45bbeedb2b5`;
- deploy chirurgico: completato sul solo package attuatore;
- checksum SHA-256 sorgente/runtime:
  `8a6879ec94787fda7003bf90e2b1fd57e6a4cafdf61f346cb98318850151b7e3`;
- backup di rollback puntuale: `step130_ac_off_20260811_205453`;
- config check Home Assistant post-deploy: PASS;
- restart controllato del container Home Assistant: completato, restart count
  stabile e API nuovamente disponibile.

## Evidenza runtime post-deploy

Durante il riavvio l'integrazione AC ha inizialmente ripristinato gli switch come
`unknown`. L'automazione di bootstrap AC ha quindi stabilito il baseline OFF con
un unico contesto recorder:

- `context_id = 019FF23409BD2ABF6EFFB181B696E070`;
- `automation.climateops_ac_feedback_bootstrap_off` avviata alle 21:02:04 CEST;
- `switch.turn_off` su `switch.ac_giorno` alle 21:02:49 CEST;
- transizione osservata `switch.ac_giorno = off` nello stesso `context_id`;
- logbook alle 21:02:55 CEST: `giorno=off, notte=off`.

Al termine della verifica:

- `switch.ac_giorno = off`;
- `binary_sensor.ac_giorno_comfort_request = off`;
- `sensor.climateops_hierarchy_mode = IDLE`;
- `binary_sensor.cm_contract_actuators_ready = off`.

Il difetto non e` stato riprodotto forzando una nuova accensione fisica, per non
energizzare inutilmente il climatizzatore. La validazione strutturale conferma
comunque che, con AC gia` `on`, il nuovo termine del gate consente di raggiungere
il ramo OFF anche quando il contratto aggregato e` falso; lock, policy e criteri
di accensione restano invariati.

## Provenienza operativa

- macchina operativa: workstation Windows autorizzata per le operazioni AEB;
- runtime target verificato: runtime Home Assistant Core Docker corrente,
  identificato nell'inventario operativo privato;
- macchina legacy: non contattata e non modificata;
- accesso diagnostico: LAN e SSH secondo l'inventario operativo privato;
- deploy: eseguito dopo pubblicazione, backup e config check pre-deploy;
- modifiche runtime: eseguite esclusivamente per il package attuatore
  `packages/climateops/actuators/system_actuator.yaml`;
- source of truth remota: `cuto88/aeb`, branch `main`.

