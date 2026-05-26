# STEP120 - HA Docker cutoff access recon - 2026-05-26

## Scope

Ricostruire lo stato accessi dopo cutoff runtime Home Assistant da endpoint storico HA OS/Supervised a runtime Docker/Core su host Linux.

## Fatti verificati

- HA API risponde su `http://192.168.178.110:8123`.
- `/api/config` conferma:
  - `version = 2026.4.4`
  - `config_dir = /config`
  - `state = RUNNING`
  - `location_name = Casa`
- `/api/hassio/*` restituisce `404`: il runtime non espone Supervisor API.
- SSH `192.168.178.110:22` risponde e accetta solo publickey.
- SSH `192.168.178.110:2222` non risponde.
- Accesso operativo ritrovato dopo test su utente corretto:
  - user: `dscomparin`
  - host: `192.168.178.110`
  - hostname remoto: `mercurio-edge`
  - chiave: `C:\Users\randalab\.codex\memories\ha_keys\ha_ed25519.20260517_073034_121.temp`
- Docker runtime:
  - container: `homeassistant`
  - image: `ghcr.io/home-assistant/home-assistant:stable`
  - bind mount: `/opt/data/homeassistant` -> `/config`
- Le chiavi HA storiche/copie temporanee testate non sono autorizzate per:
  - `root`
  - `randalab`
  - `docker`
  - `homeassistant`
  - `ha`
  - `ubuntu`
  - `debian`
- Nota: il primo test utente non includeva `dscomparin`; questo era il gap operativo principale nella ricostruzione iniziale.
- I job runtime del 2026-05-25 e 2026-05-26 falliscono prima del login SSH per ACL locale:
  - `Copy-Item : Accesso al percorso 'C:\2_OPS\aeb\.tmp\ha_ed25519.safe' negato`
  - origine: `ops/ha_secure_key.ps1`

## Stato operativo mitigazione 2026-05-26

- VMC recuperata via API in manuale `vel_1`:
  - `input_boolean.vmc_manual = on`
  - `input_select.vmc_mode = manual`
  - `input_select.vmc_manual_speed = vel_1`
  - `sensor.vmc_vel_index = 1`
- `automation.climateops_system_actuate = off` per impedire attuazione automatica del falso `HEAT` fino a deploy fix.
- `input_boolean.heating_enable = off`.

## Deploy fix 2026-05-26

- Runtime verificato come package monolitici:
  - `/config/packages/climate_heating.yaml`
  - `/config/packages/climate_ventilation.yaml`
- I file locali split `packages/climate_heating_templates.yaml` e `packages/climate_ventilation_templates.yaml` non corrispondevano al runtime attivo.
- Azione corretta:
  1. copia read-only dei due YAML runtime dal container;
  2. patch locale sui file runtime copiati;
  3. backup runtime sotto `/config/_ha_runtime_backups/step120_<timestamp>/`;
  4. `docker cp` dei due file patchati nel container;
  5. `python -m homeassistant --script check_config -c /config`;
  6. `docker restart homeassistant`.
- Check config: PASS.
- Stato post-restart:
  - `binary_sensor.vmc_sensors_ok = on`
  - `sensor.ventilation_priority = P_manual`
  - `sensor.vmc_vel_index = 1`
  - `switch.heating_master = unavailable`
  - `binary_sensor.heating_should_run = off`
  - `binary_sensor.heating_held_by_min_on_lock = off`
  - `sensor.cm_system_mode_suggested = VENT_BASE`
  - `automation.climateops_system_actuate = on`
- Stato contratti post-fix:
  - `binary_sensor.cm_contract_actuators_defined = on`
  - `binary_sensor.cm_contract_actuators_ready = off`
  - `sensor.cm_contract_missing_entities = OK`
- Interpretazione: il falso `HEAT` e` risolto, ma ClimateOps non attua finche` `switch.heating_master` resta `unavailable`. Questo e` preferibile al precedente falso ON.

## UI e integrazioni 2026-05-26

- L'utente HA `dscomparin` era attivo ma nel gruppo `system-users`, quindi non vedeva le Impostazioni amministrative in UI.
- Azione eseguita: promozione di `dscomparin` a `system-admin` in `/config/.storage/auth`.
- Backup runtime prima della modifica: `/config/_ha_runtime_backups/step120_auth_20260526T080118Z/auth`.
- Verifica post-restart:
  - `Davide`: `system-admin`, owner
  - `dscomparin`: `system-admin`
- Il log runtime mostra la causa dei sensori Tuya indisponibili:
  - `Config entry 'gg-109671632015417393853' for tuya integration could not authenticate: Authentication failed. Please re-authenticate`
- Impatto Tuya:
  - `sensor.t_in_notte2 = unavailable`
  - `sensor.ur_in_notte2 = unavailable`
  - `sensor.t_in_bagno = unavailable`
  - `sensor.ur_in_bagno = unavailable`
  - `switch.4_ch_interruttore_3 = unavailable`
- Azione utente necessaria: logout/login in HA con `dscomparin`, poi `Impostazioni -> Dispositivi e servizi -> Tuya -> Re-authenticate`.

## Verifica post re-auth Tuya 2026-05-26

- HA: `RUNNING`.
- Tuya re-auth parzialmente recuperata:
  - `sensor.t_in_bagno = 25.5`
  - `sensor.ur_in_bagno = 68.0`
  - `switch.4_ch_interruttore_3 = on`
  - `sensor.t_in_notte2 = unavailable`
  - `sensor.ur_in_notte2 = unavailable`
  - `sensor.batteria_cam2 = unavailable`
- Contratti ClimateOps:
  - `binary_sensor.cm_contract_actuators_ready = on`
  - `sensor.cm_contract_missing_entities = OK`
  - `input_text.cm_system_status = System actuation: VENT_BASE | OK`
- Test controllato automation:
  - trigger di `automation.climateops_system_actuate` con `skip_condition=false`;
  - risultato coerente: `sensor.cm_system_mode_suggested = VENT_BASE`;
  - VMC target e stato fisico allineati: `sensor.vmc_vel_target = 2`, `sensor.vmc_vel_index = 2`, `switch.vmc_vel_2 = on`;
  - riscaldamento spento: `binary_sensor.heating_should_run = off`, `switch.heating_master = off`.
- Allineamento UI VMC:
  - `input_boolean.vmc_manual = off`
  - `input_select.vmc_mode = auto`
- Residui non bloccanti per VMC/riscaldamento:
  - `localtuya` non raggiunge `192.168.178.171:6668`, quindi grid/dual meter restano `unavailable`;
  - `sensor.t_in_notte2` e `sensor.ur_in_notte2` restano indisponibili lato Tuya;
  - `switch.ac_giorno` e `switch.ac_notte` restano `unknown`, ma `climate.ac_giorno` e `climate.ac_notte` sono presenti.

## Guardia estiva VMC 2026-05-26

- Motivo: con `t_out` circa 7 C sopra `t_in_med`, `vel_2` per sola differenza UR rischia di aumentare la temperatura interna.
- Patch runtime su `/config/packages/climate_ventilation.yaml`, backup in `/config/_ha_runtime_backups/step120_vmc_summer_guard_<timestamp>/`.
- Regola: in stagione calda, se `delta_t_in_out <= -2` e il vantaggio di umidita` assoluta e` sotto `input_number.vent_deltaah_min`, la priorita` `P1_delta_ur` viene degradata a baseline.
- Check config: PASS.
- Verifica post-restart:
  - `input_boolean.vmc_manual = off`
  - `input_select.vmc_mode = auto`
  - `sensor.ventilation_priority = P4_baseline`
  - `sensor.ventilation_reason = P4 - baseline vel_1`
  - `sensor.vmc_vel_target = 1`
  - `sensor.vmc_vel_index = 1`
  - `switch.vmc_vel_1 = on`
  - `switch.vmc_vel_2 = off`
  - campione termico: `t_in_med = 25.3`, `t_out = 32.8`, `delta_t_in_out = -7.5`, `delta_ah_in_out = -0.23`.

## Root cause accesso

Il README e `AGENTS.md` locali documentavano ancora il vecchio runtime:

- `root@192.168.178.84:2222`
- config path `/homeassistant`

Il runtime corrente e` invece Docker/Core:

- API `192.168.178.110:8123`
- config path `/config`
- deploy file da eseguire via bind mount Docker o SSH sul Linux host.

La chiave attiva lato Linux host non e` ricostruibile dal workspace senza leggere `~/.ssh/authorized_keys` sul host o senza accesso al sistema che lo gestisce.

## Chiave deploy proposta

Chiave pubblica generata nel workspace per autorizzazione esplicita sul Linux host:

```text
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO7acbQK0Rfx79nqb2j5dGCzQ1b+UCBlEDTxBBZY0yWR codex-ha-110-deploy-2026-05-26
```

## Next action

Sul Linux host che esegue Docker:

1. identificare utente SSH effettivo e chiavi autorizzate;
2. autorizzare la chiave deploy sopra oppure fornire il path della chiave gia` autorizzata;
3. riconciliare source/runtime drift tra package split locali e package monolitici ancora attivi sul runtime;
4. sostituire i job scheduler che usano `.tmp\ha_ed25519.safe` non leggibile con la chiave attiva `dscomparin`;
5. aggiornare gli script `ops/*runtime*` che assumono `/homeassistant` o `.84:2222`.
