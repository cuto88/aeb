# Ventilation — Plancia

Obiettivo: descrivere la plancia legacy `lovelace/climate_ventilation_plancia.yaml`.

Stato sidebar:
- `configuration.yaml` mantiene la plancia legacy registrata come `1-ventilazione`, ma con `show_in_sidebar: false`.
- La plancia operativa esposta resta `lovelace/climate_ventilation_plancia_v2.yaml`.

Struttura (legacy):
- "Stato generale": `sensor.ventilation_priority`, `sensor.ventilation_reason`, `binary_sensor.vmc_sensors_ok`.
- "KPI aria": `sensor.t_in_med`, `sensor.ur_in_media`, `sensor.delta_t_in_out`, `sensor.delta_ah_in_out`.
- "Freecooling Passivhaus": stato e indicatori `delta_*` + `sensor.clima_open_windows_recommended`.
- "Controlli manuali": `input_select.vmc_mode`, `input_boolean.vmc_manual`, `input_select.vmc_manual_speed`, `input_boolean.vmc_boost_bagno`.
- "Velocità reali": `sensor.vmc_vel_target`, `sensor.vmc_vel_index`, `switch.vmc_vel_0/1/2/3`.
- "Finestre": `binary_sensor.windows_all_closed`, `sensor.vent_finestre_state`, `sensor.clima_open_windows_recommended`.
- "Messaggi": `input_text.vent_messaggio_consiglio`.

Note:
- La sezione finestre non contiene più placeholder TODO; usa gli aggregati runtime del modulo `packages/climate_ventilation_windows.yaml`.
- Layout legacy a cards semplici; la versione `v2` resta il riferimento principale per uso quotidiano.

## Riferimenti logici
- [Modulo Ventilation](README.md)
- [Regole plancia](../core/regole_plancia.md)
- [Regole core logiche](../core/regole_core_logiche.md)
