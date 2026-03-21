# STEP36 SwitchBot Timeout Fix Deploy Verification (2026-03-13)
Date: 2026-03-13
Scope: deploy chirurgico del fix `continue_on_error` sugli attuatori AC cloud-dependent e verifica runtime post-deploy.

## Operazioni eseguite (FACT)
1. Copia file aggiornati sul nodo HA
   - File caricati in `/tmp/` via SCP:
     - `climate_ac_mapping.yaml`
     - `system_actuator.yaml`

2. Backup remoto pre-replace
   - Eseguito backup dei file runtime precedenti sotto `/homeassistant/_ha_runtime_backups/` prima della sostituzione.

3. Deploy runtime dei file
   - Aggiornati sul nodo:
     - `/homeassistant/packages/climate_ac_mapping.yaml`
     - `/homeassistant/packages/climateops/actuators/system_actuator.yaml`

4. Verifica presenza fix sul runtime
   - `grep continue_on_error` conferma il fix nei due file deployati:
     - `climate_ac_mapping.yaml`: 2 occorrenze
     - `system_actuator.yaml`: 6 occorrenze

5. Verifica stato core post-deploy
   - `ha core info`:
     - host: `core-ssh`
     - data host: `Fri Mar 13 20:40:34 CET 2026`
     - `version: 2026.3.1`
     - `boot: true`
   - `ha core check` -> `Command completed successfully.`

## Note operative
- Il comando combinato deploy+restart e' andato in timeout lato client dopo `64s`, ma i controlli successivi confermano che:
  - i file runtime sono stati aggiornati
  - il core e' raggiungibile
  - la configurazione e' valida
- In questa verifica non e' stata ancora dimostrata a runtime la scomparsa definitiva dell'errore `climateops_system_actuate`; serve osservazione successiva su nuovi cicli reali.

## Decisione
- Deploy fix runtime: **PASS**
- Config validation post-deploy: **PASS**
- Runtime availability post-deploy: **PASS**
- Chiusura forense del problema: **PARZIALE** fino a nuova evidenza log/trace senza abort vendor-induced

## Next step operativo
1. Monitorare il prossimo ciclo reale di attuazione AC.
2. Verificare che eventuali timeout cloud non abortiscano piu' l'automation madre.
3. Se i log restano puliti o degradano in errore isolato non bloccante, chiudere il fix con un ultimo step di osservazione runtime.

## Esito finale
- Fix deployato sul runtime: **SI**
- Verifica configurazione: **OK**
- Stato corrente: **in osservazione post-deploy**
