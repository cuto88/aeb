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

## Provenienza operativa

- macchina operativa: workstation Windows autorizzata per le operazioni AEB;
- runtime target verificato: runtime Home Assistant Core Docker corrente,
  identificato nell'inventario operativo privato;
- macchina legacy: non contattata e non modificata;
- accesso diagnostico: LAN e SSH secondo l'inventario operativo privato;
- deploy: previsto dopo pubblicazione e config check;
- modifiche runtime: previste esclusivamente per il package attuatore
  `packages/climateops/actuators/system_actuator.yaml`;
- source of truth remota: `cuto88/aeb`, branch `main`.
