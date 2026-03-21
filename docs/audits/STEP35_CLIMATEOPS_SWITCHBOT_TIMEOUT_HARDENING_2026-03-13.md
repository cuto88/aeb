# STEP35 ClimateOps SwitchBot Timeout Hardening (2026-03-13)
Date: 2026-03-13
Scope: analisi root-cause dell'errore `automation.climateops_system_actuate` emerso in Step34 e hardening repo-side per evitare abort dell'automation su timeout transienti vendor cloud.

## Evidenze raccolte (FACT)
1. Log runtime errore
   - Timestamp: `2026-03-13 15:25:00.527`
   - Automation coinvolta: `automation.climateops_system_actuate`
   - Traceback: timeout HTTPS verso `apigw.tuyaeu.com:443` con `ReadTimeoutError(read timeout=60)`.

2. Punto di failure nel call stack
   - Il traceback attraversa:
     - `automation.climateops_system_actuate`
     - `script`
     - `service call`
     - `template switch async_turn_off`
   - Questo indica che il failure non nasce dalla logica ClimateOps in se', ma dalla chiamata al device/driver sottostante durante un `turn_on/turn_off`.

3. Mapping runtime attuatori AC
   - Da `core.entity_registry` runtime:
     - `switch.ac_giorno` -> platform `switchbot_cloud`
     - `switch.ac_notte` -> platform `switchbot_cloud`
   - Quindi l'attuazione AC dipende da integrazione cloud vendor.

4. Repo-side path coinvolti
   - `packages/climateops/actuators/system_actuator.yaml`
   - `packages/climate_ac_mapping.yaml`
   - In entrambi i file, i punti che chiamano `switch.ac_giorno` / `switch.ac_notte` erano suscettibili ad abort in caso di timeout cloud.

## Root cause
- Root cause tecnica: timeout del vendor cloud AC durante una chiamata runtime agli switch `switchbot_cloud`.
- Impatto: l'automation `climateops_system_actuate` puo' fallire rumorosamente anche quando la logica decisionale ClimateOps e' corretta.
- Classificazione: **dipendenza esterna instabile**, non regressione primaria della policy ClimateOps.

## Hardening applicato nel repo
### File modificati
- `packages/climate_ac_mapping.yaml`
- `packages/climateops/actuators/system_actuator.yaml`

### Modifica
- Aggiunto `continue_on_error: true` sui punti AC cloud-dependent:
  - `switch.turn_on` in `script.ac_giorno_apply`
  - `switch.turn_on` in `script.ac_notte_apply`
  - `switch.turn_off` su `switch.ac_giorno`
  - `switch.turn_off` su `switch.ac_notte`
  - chiamate `script.ac_giorno_apply` / `script.ac_notte_apply` dal system actuator
  - revert authority ON non autorizzato su `switch.ac_giorno` / `switch.ac_notte`

## Effetto atteso
- Un timeout transient su SwitchBot cloud non deve piu' abortire l'intera automation ClimateOps.
- Il sistema mantiene:
  - trace e stato generale aggiornabili
  - prosecuzione delle altre azioni non dipendenti dal vendor
- Resta possibile che l'attuatore AC non esegua il comando in caso di timeout; l'hardening riduce il blast radius logico, non elimina la fragilita' cloud.

## Limiti
- Fix non ancora deployato/verificato sul runtime in questo step.
- `ops/validate.ps1` non e' eseguibile in questo workspace perche' i gate cercano una root git non risolvibile qui.

## Next step operativo
1. Deployare le modifiche sul runtime HA.
2. Eseguire `ha core check` post-deploy.
3. Monitorare i log per verificare:
   - assenza di abort completi di `automation.climateops_system_actuate`
   - eventuale persistenza dei timeout cloud vendor come warning/failure isolati
4. Valutare nel medio termine una riduzione della dipendenza cloud per gli attuatori AC.

## Esito finale
- Root cause identificata: **SwitchBot/Tuya cloud timeout lato attuatore AC**
- Hardening repo applicato: **SI**
- Deploy runtime: **NO**
- Stato: **READY FOR DEPLOY**
