# Ventilation — Overview

## Titolo
Ventilation — ventilazione naturale + VMC.

## Obiettivo
- Gestire con un unico modulo la ventilazione naturale e la VMC, coordinando night-flush estivo e ricambio aria in sicurezza.
- Massimizzare il raffrescamento passivo evitando ingressi di umidità, vento forte, pioggia o PM elevati e rispettando le priorità core VMC.

## Entrypoints
- YAML: `packages/climate_ventilation.yaml`, `packages/climate_ventilation_windows.yaml`.
- Lovelace tecnica: `lovelace/climate_ventilation_plancia.yaml` (con fallback `lovelace/climate_ventilation_plancia_v2.yaml`).
- Entrypoint utente corrente: `lovelace/climate_casa_unified_plancia.yaml`.

## KPI / Entità principali
### Input (sensori, KPI, stati)
- Meteo: `binary_sensor.vent_condizioni_meteo_ok`, `binary_sensor.vent_pioggia`, velocità vento, PM2.5 (`input_number.vent_vento_max`, `input_number.vent_pm25_max`).
- Termo-igrometria: `sensor.delta_t_in_out`, `sensor.delta_ah_in_out`, `sensor.ur_in_media`, `sensor.ur_out`, `sensor.t_out`, `sensor.ah_in`, `sensor.ah_out`.
- Bagno: `sensor.ur_in_bagno` con soglie `input_number.vmc_bagno_on/off` e ΔUR.
- Stato VMC e controlli: `sensor.ventilation_priority`, `sensor.ventilation_reason`, `sensor.vmc_vel_target`, `sensor.vmc_freecooling_status`, `binary_sensor.vmc_sensors_ok`.
- Manuale/override: `input_boolean.vmc_manual`, `input_select.vmc_manual_speed`, `timer.vmc_manual_timeout`, `input_boolean.vent_override_estate`, `input_boolean.vent_notifiche_attive`.
- Fasce e timer: `input_datetime.vent_night_flush_start/end`, timer lock freecooling (`vmc_freecooling_max_run`, `vmc_freecooling_cooldown`) e anti-secco/boost (`vmc_anti_secco_lock`, `vmc_boost_lock`).

### Output (switch, scene)
- Attuatori VMC: relè vel_0/vel_1/vel_2/vel_3 pilotati dal reason calcolato nel package.
- Notifiche/consigli: `binary_sensor.vent_recommend_open`, `binary_sensor.vent_recommend_close`, testo `input_text.vent_messaggio_consiglio`.

### KPI usati e soglie
- ΔT/ΔAH minimi regolabili: `input_number.vent_deltat_min`, `input_number.vent_deltaah_min` per consigli apertura; `input_number.vmc_freecooling_delta` e `input_number.vmc_freecooling_delta_ah` per free-cooling VMC.
- Anti-secco: soglia `input_number.vmc_anti_secco_ur_min` con isteresi; duty vel_0 con impulsi vel_1 notturni/invernali.
- Boost bagno: UR on/off e ΔUR interno/esterno; max_run/cooldown tramite timer dedicati.
- Night-flush: finestra `vent_night_flush_start/end`, meteo ok e ΔT/ΔAH favorevoli; max_run 120m, rispetto lock min_on/min_off.

### Regole core (sintesi)
- **P0_failsafe**: sensori `unknown/unavailable` → disattiva consigli, forza profilo sicuro (vel_0/vel_1) finché `binary_sensor.vmc_sensors_ok` è false.
- **P1_boost_bagno**: UR bagno sopra soglia o ΔUR alto → VMC vel_3 con downgrade a vel_2 se aria esterna troppo secca; applica max_run/cooldown.
- **P2_anti_secco**: UR interna bassa + stagione fredda + fascia 23–07 → duty vel_0/vel_1, blocca DRY e limita free-cooling.
- **P3_freecooling**: ΔT/ΔAH favorevole + stagione calda + AC OFF + meteo ok → VMC vel_2, attiva `hook_vmc_request_ac_block`, abilita night-flush serramenti.
- **P1_night_flush (Vent)**: finestra 21:00–08:00 e ΔT/ΔAH favorevoli → suggerisce apertura serramenti e mantiene VMC vel_2 tramite hook.
- **Manuale**: `input_boolean.vmc_manual` + velocità scelta → scavalca altre priorità finché il timer manuale scade, rispettando lock hardware.
- **Idle/baseline**: nessun trigger → VMC vel_1 continua, consigli serramenti disattivi salvo meteo critico.

### Modalità manuali / override
- Modalità VMC: `input_select.vmc_mode` (auto/manual/off) con `input_select.vmc_manual_speed`; timer `vmc_manual_timeout` per rientro automatico.
- Ventilazione: `input_boolean.vent_override_estate` forza stagione estiva; `input_boolean.vent_notifiche_attive` abilita/disabilita i messaggi.

### Edge cases / protezioni
- Anti-smog/vento/pioggia: sospende consigli e night-flush se PM2.5 o vento superano soglia o se piove.
- Backup sensori: uso di `input_number.vent_backup_t_in` e `vent_backup_ur_in` in caso di assenza sensori interni.
- Lock anti on/off: timer min_on/min_off per boost e anti-secco; cooldown free-cooling per evitare ping-pong.
- Watchdog: se nessun evento per lungo tempo, `sensor.ventilation_reason` torna a baseline garantendo ricambio minimo.

## Hook / Dipendenze
- `hook_vent_enable_night_flush` per night-flush serramenti/VMC vel_2.
- `hook_vmc_request_ac_block` quando free-cooling/ΔAH favorevole richiede blocco DRY/COOL.
- `hook_ac_request_vmc_low` coordinato con AC per mantenere VMC low durante DRY.

## Riferimenti
- [docs/logic/core/regole_core_logiche.md](../core/regole_core_logiche.md)
- [docs/logic/core/README_sensori_clima.md](../core/README_sensori_clima.md)
- [docs/logic/core/regole_plancia.md](../core/regole_plancia.md)
- [README_ClimaSystem.md](../../../README_ClimaSystem.md)

> Revisione documentazione clima Vent – allineata a implementazione attuale.
