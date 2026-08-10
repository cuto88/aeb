# STEP127 - AEB TV dashboard v2.0.0

Data avvio: 2026-07-30  
Baseline consolidata: 2026-08-10

## Esito

La dashboard AEB TV `v2.0.0` e` stata collaudata realmente su TV TCL a
1920 x 1080. Il test sul dispositivo e la documentazione fotografica
confermano un forte miglioramento della leggibilita` rispetto alla versione
precedente.

La `v2.0.0` e` giudicata una base architetturale valida per la dashboard
TV-first: consente di comprendere rapidamente lo stato della casa e separa
in modo esplicito supervisione e azioni domestiche. Questo rilascio viene
cristallizzato senza ulteriori modifiche grafiche o funzionali.

## Contratti dati e sicurezza

- comfort: `sensor.t_in_med`, `sensor.t_out_effective`,
  `sensor.ur_in_media`;
- energia: `sensor.pv_power_now`,
  `sensor.global_consumption_estimated_w`, `sensor.grid_power_w`,
  `sensor.grid_direction`;
- VMC: `sensor.ventilation_state_reason`, `sensor.vmc_vel_index`,
  `sensor.vmc_vel_target`, `binary_sensor.vmc_sensors_ok`,
  `binary_sensor.vmc_freecooling_active`;
- anomalie: failsafe AC/heating, stale outdoor, copertura sensori VMC e fault
  code MIRAI gia` esistenti.

Il package `packages/aeb_tv_supervision.yaml` contiene esclusivamente sensori
di presentazione. Non introduce soglie operative, bypass, automazioni o
comandi tecnici. Le azioni esposte dalla dashboard riusano soltanto helper e
controlli Home Assistant gia` mediati dalle logiche esistenti.

## Layout e navigazione v2.0.0

La dashboard `13-stato-casa-tv` adotta una home HMI TV-first Full HD e
subview dedicate a Stato generale, Clima, Energia, VMC, ACS e Azioni. La home
mantiene la supervisione prioritaria; i comandi quotidiani sono separati
visivamente dagli indicatori e raccolti nelle subview operative.

Path previsto: `/13-stato-casa-tv/stato-casa`.

Asset della baseline:

- `lovelace/13_stato_casa_tv.yaml`;
- `packages/aeb_tv_supervision.yaml`;
- `themes/aeb_tv.yaml`;
- `www/aeb-tv/home-v2.svg`.

## Collaudo reale TCL

- dispositivo: TV TCL;
- risoluzione: 1920 x 1080;
- caricamento dashboard: riuscito dopo riavvio dell'app Home Assistant;
- assenza di dipendenza dallo scroll: confermata;
- leggibilita`: forte miglioramento confermato da test reale e foto;
- valutazione complessiva: `v2.0.0` approvata come baseline architetturale,
  con polish visivo e di navigazione rinviato alla `v2.0.1`.

## Polish residuo v2.0.1

- eliminare header e sidebar Home Assistant tramite modalita`
  kiosk/fullscreen compatibile con Android TV;
- rendere human-readable gli stati `AC idle`, `RISC idle` e `P0_off`;
- correggere la semantica del colore FV quando la produzione e` 0 W o e`
  notte;
- rendere molto evidente il focus D-pad;
- rifinire footer e navigazione.

Questi punti non bloccano il congelamento della `v2.0.0` e non sono inclusi
nel presente intervento.

## Provenienza operativa

- macchina operativa: workspace Windows `C:\2_OPS\aeb`;
- runtime target verificato: `mercurio-edge` (`192.168.178.110`), Home
  Assistant Core Docker, container `homeassistant`, bind mount
  `/opt/data/homeassistant` -> `/config`;
- macchina legacy: non contattata;
- accesso: filesystem locale, GitHub connector, LAN/SSH e Docker;
- deploy originario `v2.0.0`: si`, chirurgico sugli asset TV;
- backup runtime `v2.0.0`: `/config/_aeb_tv_backup_20260810_v200_hmi`;
- deploy durante il congelamento: no;
- modifiche runtime durante il congelamento: no;
- verifica di corrispondenza: hash SHA-256 locale/runtime identici per tutti
  e quattro gli asset della baseline;
- verifica runtime: container `homeassistant` running, check configurazione
  Home Assistant ed endpoint HTTP verificati;
- source of truth: branch `feat/aeb-tv-dashboard`, PR `#468`;
- merge: non eseguito.
