# BMS Physical Sensor + Actuator Inventory (2026-04-22)

Date: 2026-04-22  
Scope: inventario fisico ragionato di sensori, attuatori e sorgenti campo Casa Mercurio / AEB.  
Companion report: `docs/audits/BMS_ARCHITECTURE_SENSOR_AUDIT_2026-04-22.md`.

## Fonti usate

- `tmp_core.device_registry`
- `tmp_core.entity_registry`
- `docs/logic/core/README_sensori_clima.md`
- `docs/logic/core/runtime_hardware_profiles.md`
- `docs/SOT_ENTITIES.md`
- `docs/audits/CURRENT_RUNTIME_STATUS_2026-04-08.md`

## Legenda decisionale

FACT  
La tabella distingue entita` fisiche, proxy logici e segnali derivati.

IPOTESI (confidenza media)  
Per i device consumer cloud/radio la colonna alimentazione/protocollo e` dedotta da piattaforma HA e modello dispositivo, non da ispezione fisica in campo.

DECISIONE  
Usare questa tabella come base per razionalizzazione e sostituzioni progressive. Non e` una lista acquisti.

Classi BMS:
- `control-grade`: puo` influenzare attuazione o blocchi.
- `diagnostic-grade`: utile per verifica, KPI, fault detection.
- `advisory-grade`: utile per consiglio/plancia, non deve comandare da solo.
- `legacy/fallback`: mantenere solo durante transizione.

## Inventory

| area | entity_id / device | zona | funzione | protocollo / integrazione | alimentazione | classe BMS | stato dato | criticita` | azione consigliata |
|---|---|---|---|---|---|---|---|---|---|
| T/RH | `sensor.t_in_giorno`, `sensor.ur_in_giorno` / Sensore T/UR Giorno | giorno | temperatura/umidita` comfort | SwitchBot cloud, WoIOSensor | batteria | control-grade | operativo | cloud/radio/batteria su segnale clima | affiancare o sostituire con sensore alimentato PoE/cablato |
| T/RH | `sensor.t_in_notte1`, `sensor.ur_in_notte1` / Sensore T/UR Notte1 | notte 1 | temperatura/umidita` comfort | SwitchBot cloud, WoIOSensor | batteria | control-grade | operativo | cloud/radio/batteria su zona comfort | affiancare o sostituire con sensore alimentato |
| T/RH | `sensor.t_in_notte2`, `sensor.ur_in_notte2` / Sensore T/UR Notte2 | notte 2 | temperatura/umidita` comfort | Tuya T & H Sensor | batteria | control-grade | operativo | cloud/radio/batteria | affiancare o sostituire con sensore alimentato |
| T/RH | `sensor.t_in_bagno`, `sensor.ur_in_bagno` / Sensore T/UR Bagno | bagno | comfort + boost VMC | Tuya T & H Sensor | batteria | control-grade | operativo | segnale guida boost VMC ma consumer/batteria | priorita` alta: sostituire/affiancare con T/RH alimentato |
| T/RH | `sensor.t_out`, `sensor.ur_out` / Sensore T/UR Esterna | esterno | DeltaT/DeltaAH, freecooling, heating | SwitchBot cloud, WoIOSensor | batteria | control-grade | operativo | dato esterno critico ma cloud/batteria | priorita` alta: sensore esterno alimentato o cablato |
| batteria | `sensor.batteria_giorno` | giorno | stato batteria T/RH | SwitchBot cloud | batteria | diagnostic-grade | operativo | manutenzione sensore | usare per allarmi sostituzione |
| batteria | `sensor.batteria_cam1` | notte 1 | stato batteria T/RH | SwitchBot cloud | batteria | diagnostic-grade | operativo | manutenzione sensore | usare per allarmi sostituzione |
| batteria | `sensor.batteria_cam2` | notte 2 | stato batteria T/RH | Tuya | batteria | diagnostic-grade | operativo | manutenzione sensore | usare per allarmi sostituzione |
| batteria | `sensor.bagno_stato_della_batteria` | bagno | stato batteria T/RH | Tuya | batteria | diagnostic-grade | operativo | manutenzione sensore critico | allarme prioritario, poi rimozione dopo upgrade |
| batteria | `sensor.batteria_esterna` | esterno | stato batteria T/RH | SwitchBot cloud | batteria | diagnostic-grade | operativo | manutenzione sensore esterno critico | allarme prioritario, poi rimozione dopo upgrade |
| IAQ | `sensor.co2_giorno` | giorno | CO2 | assente | n/a | control-grade target | mancante | VMC non IAQ-grade | integrare in Fase 1 |
| IAQ | `sensor.co2_notte` | notte | CO2 | assente | n/a | control-grade target | mancante | VMC non IAQ-grade notte | integrare in Fase 1 |
| finestre | `binary_sensor.finestre_zona_giorno_aperte` | giorno | stato aperture aggregato | template da `input_boolean` | virtuale | advisory/control target | logico/manuale | non feedback fisico | sostituire input con contatti reali |
| finestre | `binary_sensor.finestre_zona_notte_aperte` | notte | stato aperture aggregato | template da `input_boolean` | virtuale | advisory/control target | logico/manuale | non feedback fisico | sostituire input con contatti reali |
| finestre | `binary_sensor.finestre_bagno_aperte` | bagno | stato apertura bagno | template da `input_boolean` | virtuale | advisory/control target | logico/manuale | non feedback fisico | sostituire input con contatto reale |
| VMC attuazione | `switch.vmc_vel_0..3` / VMC CK-BL602-4SW-HS | tecnico | velocita` VMC | Sonoff LAN/custom | rete | control-grade | operativo | custom integration, feedback proxy | tenere ora, valutare I/O cablato/DIN in Fase 2 |
| VMC feedback | `binary_sensor.vmc_is_running_proxy`, `sensor.vmc_active_speed_proxy` | tecnico | stato VMC logico | template/proxy | virtuale | diagnostic-grade | operativo | proxy, non feedback elettrico diretto | integrare feedback energia o stato reale |
| heating attuatore fisico | `switch.4_ch_interruttore_3` / Tuya 4CH | quadro/riscaldamento | rele` heating downstream | Tuya | rete | control-grade | operativo | consumer cloud/local su attuatore critico | mantenere con single-writer, target futuro rele` DIN/cablato |
| heating comando logico | `switch.heating_master` | logico | comando riscaldamento | template | virtuale | control-grade | operativo | deve restare unica authority | mantenere come astrazione canonica |
| heating feedback | `binary_sensor.heating_master_is_on_proxy` | logico | stato heating | template/proxy | virtuale | diagnostic-grade | operativo | proxy, non corrente reale | affiancare con metering/feedback fisico |
| AC giorno | `climate.ac_giorno`, `switch.ac_giorno` / AC Giorno | giorno | split AC | SwitchBot cloud/IR | rete + IR | control-grade | operativo | IR/cloud, stato non garantito | chiudere single-writer, aggiungere feedback energia |
| AC notte | `climate.ac_notte`, `switch.ac_notte` / AC Notte | notte | split AC | SwitchBot cloud/IR | rete + IR | control-grade | operativo | IR/cloud, stato non garantito | chiudere single-writer, aggiungere feedback energia |
| AC feedback | `binary_sensor.ac_giorno_is_on_proxy`, `binary_sensor.ac_notte_is_on_proxy` | giorno/notte | stato AC ricostruito | template/proxy | virtuale | diagnostic-grade | operativo | non misura stato fisico | usare metering dedicato AC |
| energia rete | `sensor.grid_power_w`, `sensor.grid_direction`, `sensor.grid_energy_import_kwh` | quadro | rete import/export | SDM120 via RS485 Modbus TCP | rete/quadro | control-grade | validato | bus condiviso da proteggere | tenere come sorgente primaria |
| energia rete legacy | `sensor.sensor_grid_power_w`, `sensor.sensor_grid_direction` / Dual Meter | quadro | rete import/export fallback | LocalTuya/Tuya | rete | legacy/fallback | transitorio | consumer/custom, duplicazione | declassare e rimuovere quando SDM120 stabile |
| FV | `sensor.solaredge_potenza_attuale`, `sensor.pv_power_now` | FV | produzione solare | SolarEdge + template | rete/cloud/API | control/advisory-grade | operativo | feed esterno, latenza/availability | mantenere con quality monitor |
| FV forecast | `sensor.power_production_next_hour`, bridge forecast | FV | previsione FV | Forecast.Solar / weather bridge | cloud/API | advisory-grade | operativo con fallback | qualita` previsionale variabile | usare per policy, non per safety |
| Meross PM1 | `sensor.pm1_mss310_*`, `switch.pm1_mss310_main_channel` | carico non specificato | power plug/meter | Meross cloud custom | rete | diagnostic/advisory-grade | operativo | custom/cloud, non DIN | usare per misure non critiche |
| Meross PM2 | `sensor.pm2_mss310_*`, `switch.pm2_mss310_main_channel` | carico non specificato | power plug/meter | Meross cloud custom | rete | diagnostic/advisory-grade | operativo | custom/cloud, non DIN | usare per misure non critiche |
| Meross PM3 | `sensor.pm3_mss310_*`, `switch.pm3_mss310_main_channel` | carico non specificato | power plug/meter | Meross cloud custom | rete | diagnostic/advisory-grade | operativo | custom/cloud, non DIN | usare per misure non critiche |
| Tuya plug | `sensor.t34_smart_plug_*`, `switch.t34_smart_plug_interruttore_1` | carico non specificato | plug/meter | Tuya | rete | diagnostic/advisory-grade | operativo | consumer/cloud/local | non usare per carichi BMS critici |
| MIRAI Modbus | `sensor.mirai_l161_*`, `sensor.mirai_l162_*`, `sensor.mirai_l163_*`, `sensor.mirai_status_*` | PDC/idronica | stati e temperature PDC | RS485 Modbus TCP | rete/quadro | diagnostic/control target | parziale | truth runtime non chiusa | chiudere validazione RUN prima di policy attuativa |
| MIRAI power | `sensor.mirai_power_w` | PDC/heating | potenza heating | template/bridge | derivato | diagnostic-grade | operativo | dipende da fonte sottostante | usare per feedback, verificare origine |
| EHW Modbus | `sensor.ehw_tank_top`, `sensor.ehw_tank_bottom`, `sensor.ehw_setpoint`, raw T01..T06 | ACS | tank, setpoint, sonde | Modbus | rete/quadro | control-grade | validato | mapping/readiness da governare | tenere, con health readiness |
| EHW feedback | `binary_sensor.ehw_running`, `sensor.ehw_power_w` | ACS | stato/potenza ACS | template/bridge | derivato | diagnostic/control-grade | operativo | dipende da mapping e power source | mantenere nel path governato |
| porta/lock | `binary_sensor.kkk_porta`, `sensor.kkk_batteria` / SwitchBot Smart Lock Pro | porta | porta/lock | SwitchBot cloud | batteria | advisory/security-grade | operativo | cloud/batteria, non BMS HVAC | non usare per controllo HVAC critico |
| ESPHome legacy | LDR Camera1/Camera2 | termostati TEMP legacy | ingressi/letture legacy | ESPHome | rete | legacy/fallback | disabilitato/smontato | hardware non presente | non reintegrare senza nuovo piano |

## Sintesi criticita` per famiglia

### Sensori ambiente T/RH

FACT  
Le entita` canoniche clima dipendono da sensori SwitchBot/Tuya a batteria/cloud/radio.

IPOTESI (confidenza alta)  
Sono accettabili come baseline, ma non come fondazione definitiva di un BMS affidabile.

DECISIONE  
Priorita` sostituzione: bagno, esterno, notte/giorno in base a cablaggio disponibile e criticita` comfort.

### CO2 / IAQ

FACT  
Non risultano entita` CO2 operative nel registry/package climate.

IPOTESI (confidenza alta)  
La VMC sta lavorando soprattutto su umidita` e DeltaAH, quindi non vede direttamente il carico biologico/occupazione.

DECISIONE  
Integrare CO2 giorno e notte in Fase 1 come segnali alimentati e stabili.

### Finestre

FACT  
Lo stato finestre e` modellato con input boolean e template aggregati.

IPOTESI (confidenza alta)  
Questo e` corretto come placeholder, ma non e` feedback fisico.

DECISIONE  
Portare almeno gli aggregati zona giorno, zona notte e bagno su contatti reali prima di usarli come blocchi forti.

### Energia e feedback attuatori

FACT  
SDM120 Modbus e` validato come sorgente rete primaria. AC/VMC hanno gap di metering dedicato.

IPOTESI (confidenza alta)  
Il feedback energia e` il modo piu` pragmatico per verificare se AC/VMC/heating stanno davvero operando.

DECISIONE  
Aggiungere metering dedicato AC/VMC prima di aumentare automazione multi-load.

### Fieldbus RS485 / Modbus

FACT  
Il bus MIRAI + SDM120 e` attestato su `192.168.178.191:502`, 9600 8E1, slave 1/2.

IPOTESI (confidenza media)  
Il bus puo` diventare dorsale affidabile solo se topologia, terminazioni, GND, separazione cavi e polling sono documentati.

DECISIONE  
Non aggiungere nuovi slave RS485 prima di produrre una mappa bus fisica.

## Azioni prioritarie

1. FACT: esiste SOT logico `cm_*`.  
   DECISIONE: creare anche SOT fisico sensori/attuatori.

2. FACT: CO2 assente.  
   DECISIONE: definire due entity target stabili: `sensor.co2_giorno`, `sensor.co2_notte`.

3. FACT: finestre sono virtuali.  
   DECISIONE: distinguere in UI e policy tra `manual_window_state` e `physical_window_contact`.

4. FACT: AC usa SwitchBot/IR/cloud.  
   DECISIONE: chiudere single-writer e aggiungere feedback energia prima di nuove policy.

5. FACT: Modbus e` gia` presente.  
   DECISIONE: creare mappa fisica RS485 prima di espansioni.

## Prossimo file consigliato

DECISIONE  
Creare un documento operativo separato:

`docs/audits/BMS_FIELD_LAYER_RS485_TOPOLOGY_PLAN_2026-04-22.md`

Contenuto minimo:
- gateway
- indirizzi slave
- baud/parity
- cavo
- lunghezza stimata
- terminazioni
- GND
- separazione da potenza
- polling HA
- failure mode
- regole per aggiungere nuovi slave
