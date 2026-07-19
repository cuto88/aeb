# Ventilation — Plancia

Obiettivo: descrivere la plancia dominio corrente `lovelace/02_air_loop.yaml` e distinguere la copia legacy conservata.

Stato sidebar:
- `02-vmc` registra `lovelace/02_air_loop.yaml` come `2 Air Loop`, visibile in sidebar.
- `lovelace/_archive/legacy_dashboards/02_air_loop_legacy.yaml` e` conservata per confronto e rollback, ma non e` registrata in `configuration.yaml`.
- `lovelace/01_eclss_casa.yaml` (`01-clima-casa`) resta l'entrypoint operativo cross-modulo.

Struttura del dominio:
- "Stato generale": `sensor.ventilation_priority`, `sensor.ventilation_reason`, `binary_sensor.vmc_sensors_ok`.
- "KPI aria": `sensor.t_in_med`, `sensor.ur_in_media`, `sensor.delta_t_in_out`, `sensor.delta_ah_in_out`.
- "Freecooling Passivhaus": stato e indicatori `delta_*` + `sensor.clima_open_windows_recommended`.
- "Controlli manuali": `input_select.vmc_mode`, `input_boolean.vmc_manual`, `input_select.vmc_manual_speed`, `input_boolean.vmc_boost_bagno`.
- "Velocità reali": `sensor.vmc_vel_target`, `sensor.vmc_vel_index`, `switch.vmc_vel_0/1/2/3`.
- "Finestre": `binary_sensor.windows_all_closed`, `sensor.vent_finestre_state`, `sensor.clima_open_windows_recommended`.
- "Messaggi": `input_text.vent_messaggio_consiglio`.

Note:
- La sezione finestre non contiene più placeholder TODO; usa gli aggregati runtime del modulo `packages/climate_ventilation_windows.yaml`.
- La plancia corrente usa una view `sections`; il file legacy mantiene il precedente layout a card semplici solo come riferimento storico.
- La card `ClimateOps Cutover` e i relativi toggle sono stati rimossi dalla `v2` per ridurre rumore operativo UI.

## Riferimenti logici
- [Modulo Ventilation](README.md)
- [Regole plancia](../core/regole_plancia.md)
- [Regole core logiche](../core/regole_core_logiche.md)
