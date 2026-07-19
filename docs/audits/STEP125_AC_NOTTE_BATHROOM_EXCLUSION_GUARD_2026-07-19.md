# STEP125 — Guard esclusione bagno da AC notte (2026-07-19)

## Problema

Una patch runtime aveva escluso il bagno dal controllo `ac_notte`, ma la stessa
decisione non era stata riconciliata nel repository. Il deploy successivo del
file completo `climate_ac_comfort_control.yaml` ha quindi reintrodotto
`sensor.t_in_bagno` e `sensor.ur_in_bagno`.

La diagnosi successiva ha individuato anche il meccanismo materiale della
regressione: `homeassistant.packages` usa `!include_dir_named packages`, che
carica ricorsivamente anche i file YAML nelle sottocartelle. I backup conservati
in `packages/_codex_backups` venivano quindi interpretati come package attivi e
una copia precedente poteva prevalere sul file corrente.

Il controllo non calcola una media: usa il massimo dei sensori disponibili.
Un picco transitorio del bagno poteva pertanto governare direttamente la
richiesta dello split notte.

## Policy definitiva

- temperatura notte: massimo fra `sensor.t_in_notte1` e `sensor.t_in_notte2`;
- umidita` notte: massimo fra `sensor.ur_in_notte1` e `sensor.ur_in_notte2`;
- temperatura e umidita` bagno: intenzionalmente escluse dal controllo AC;
- carichi transitori bagno: gestiti dalla logica VMC/boost dedicata.
- entita` canoniche: `sensor.ac_notte_temperatura_camere` e
  `sensor.ac_notte_umidita_camere`; nuovi unique ID evitano il riuso della
  definizione template precedente rimasta materializzata nel runtime.

## Protezione dalla regressione

`ops/gate_ac_night_sensor_policy.ps1` fallisce se i sensori bagno vengono
reintrodotti nei blocchi temperatura o umidita` di controllo `ac_notte`. Il gate
e` eseguito sia da `ops/gates_run.ps1` sia da `ops/gates_run_ci.ps1`.

`ops/gate_include_tree.ps1` fallisce inoltre se trova file YAML sotto directory
di backup annidate in `packages`. I backup runtime devono stare sotto
`/config/backups`, mai sotto `/config/packages`.

## Provenienza operativa

- macchina operativa: workstation Codex, workspace `C:\2_OPS\aeb`;
- runtime target: `mercurio-edge`, `192.168.178.110`, container `homeassistant`;
- configurazione runtime: bind mount `/opt/data/homeassistant` esposto come `/config`;
- macchina legacy `.84:2222`: non usata;
- accesso: LAN e SSH al nuovo host Docker;
- deploy: patch chirurgica del solo `climate_ac_comfort_control.yaml`;
- modifiche runtime: esclusione bagno e reload/restart solo dopo `check_config`;
- Git locale: non usato, come richiesto dalla policy del workspace.

## Esito deploy

- backup pre-deploy:
  `/config/packages/_codex_backups/20260719_ac_notte_bathroom_guard/climate_ac_comfort_control.yaml`;
- diff pre-deploy: limitato alla rimozione dei sensori bagno dai due blocchi e
  all'aggiornamento dell'attributo `strategy`;
- nuovo gate dedicato: PASS;
- gate repository precedenti a `yamllint`: PASS;
- suite CI completa: non conclusa per dipendenza locale `yamllint` assente;
- Home Assistant `check_config`: PASS;
- riavvio container `homeassistant`: PASS;
- endpoint HTTP tornato disponibile dopo circa 20 secondi;
- log post-avvio: nessun errore relativo alla modifica; presenti warning
  preesistenti LocalTuya/Meross;
- verifica API entity-level: non eseguita per assenza del file locale `.env`
  contenente `HA_TOKEN`; configurazione runtime e avvio sono stati verificati.

## Chiusura regressione runtime

La verifica dalla plancia ha mostrato che i backup sotto
`/config/packages/_codex_backups` erano realmente caricati come package. La
cartella e` stata spostata integralmente e in modo recuperabile in
`/config/backups/packages_codex_backups_20260719`.

Dopo `check_config` e riavvio completo:

- `switch.ac_notte = off`;
- `binary_sensor.ac_notte_comfort_request = off`;
- `sensor.ac_notte_temperatura_camere = 25.6 °C`;
- `sensor.ac_notte_umidita_camere = 55.0%`;
- `sensor.ac_notte_dew_point = 15.9 °C`;
- bagno rilevato separatamente a `26.8 °C`, senza partecipare al controllo;
- attributo `strategy`: bagno intenzionalmente escluso.

