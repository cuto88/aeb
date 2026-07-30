# STEP127 - AEB TV dashboard

Data: 2026-07-30

## Obiettivo

Dashboard Lovelace read-only per supervisione AEB su TV TCL Full HD. La vista
privilegia stato casa, comfort, energia, VMC e un solo avviso prioritario.

## Contratti dati

- comfort: `sensor.t_in_med`, `sensor.t_out_effective`,
  `sensor.ur_in_media`;
- energia: `sensor.pv_power_now`,
  `sensor.global_consumption_estimated_w`, `sensor.grid_power_w`,
  `sensor.grid_direction`;
- VMC: `sensor.ventilation_state_reason`, `sensor.vmc_vel_index`,
  `sensor.vmc_vel_target`, `binary_sensor.vmc_sensors_ok`,
  `binary_sensor.vmc_freecooling_active`;
- anomalie: failsafe AC/heating, stale outdoor, VMC sensor coverage e fault
  code MIRAI gia` esistenti.

Il package `packages/aeb_tv_supervision.yaml` aggiunge soltanto tre sensori di
presentazione: stato sintetico, avviso prioritario e scambio rete testuale.
Non introduce soglie operative, automazioni o comandi.

## Layout e navigazione

La dashboard `13-stato-casa-tv` espone una sola view `stato-casa`, usa
`type: sections` con massimo quattro colonne e sei blocchi principali.
Le sole azioni disponibili sono quattro link verso dashboard operative
esistenti; tutte le card informative disabilitano tap e pressione prolungata.

Path previsto: `/13-stato-casa-tv/stato-casa`.

## Provenienza operativa

- macchina operativa: workspace Windows `C:\2_OPS\aeb`;
- runtime target: `mercurio-edge`, Home Assistant Core Docker, non toccato;
- macchina legacy: non contattata;
- accesso: filesystem locale e GitHub connector;
- deploy: no;
- modifiche runtime: no.
