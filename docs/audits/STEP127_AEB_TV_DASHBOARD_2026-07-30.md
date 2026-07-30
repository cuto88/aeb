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

Il primo collaudo reale sulla TCL ha rilevato due vincoli bloccanti: sidebar
incompleta e scrolling non affidabile con telecomando. La versione `v1.0.1`
non dipende piu` da sidebar, swipe o scroll.

La dashboard `13-stato-casa-tv` espone tre view native `type: panel`:

- `stato-casa`: griglia fissa 4 colonne con i nove indicatori essenziali,
  un solo pulsante `Tutte le dashboard` e versione discreta;
- `menu-1`: sei dashboard operative, `Pagina successiva` e `Stato casa`;
- `menu-2`: le altre sei dashboard operative, `Pagina precedente` e
  `Stato casa`.

I due menu sono `subview: true` con `back_path` verso la home, ma il ritorno
primario resta sempre il pulsante visibile. Tutti i launcher usano card native
`button` con `tap_action: navigate`; hold e doppio tap sono disabilitati.
Ogni menu contiene otto pulsanti in una griglia 4 x 2 e non richiede scroll
nel target Full HD.

Path previsto: `/13-stato-casa-tv/stato-casa`.

## Provenienza operativa

- macchina operativa: workspace Windows `C:\2_OPS\aeb`;
- runtime target: `mercurio-edge`, Home Assistant Core Docker, container
  `homeassistant`, bind mount `/opt/data/homeassistant` -> `/config`;
- macchina legacy: non contattata;
- accesso: filesystem locale, GitHub connector, LAN/SSH e Docker;
- deploy: si`, chirurgico sui tre file
  `configuration.yaml`, `packages/aeb_tv_supervision.yaml` e
  `lovelace/13_stato_casa_tv.yaml`;
- modifiche runtime: si`, backup
  `/config/_aeb_tv_backup_20260730_225505`, controllo configurazione PASS e
  riavvio del solo container `homeassistant`;
- source of truth: branch `feat/aeb-tv-dashboard`, PR `#468`;
- verifica post-riavvio: container `running`, endpoint HTTP `200`, tre nuove
  entita` template presenti nel registry;
- deploy correttivo `v1.0.1`: solo
  `lovelace/13_stato_casa_tv.yaml`, backup
  `/config/_aeb_tv_backup_20260730_231415`, check configurazione pre e
  post-deploy PASS, container `running`, endpoint HTTP `200`, nessun riavvio
  richiesto;
- secondo collaudo visuale TCL: ancora manuale.
