# Diagnostica AC Casa Mercurio — 2026-09-23

## Esito

Il repository contiene una distinzione incompleta tra richiesta e funzionamento:
`climate.ac_giorno` / `climate.ac_notte` e `switch.ac_giorno` /
`switch.ac_notte` rappresentano il comando/feedback del bridge SwitchBot. Il
proxy `binary_sensor.ac_*_is_on_proxy` copia quello switch, con il solo gate
del consenso manuale `binary_sensor.cm_ac_branch_powered`; non legge una
misura elettrica. Perciò uno switch rimasto `on` può mostrare AC acceso anche
con unità fisicamente spenta.

La misura elettrica canonica presente nel codice è `sensor.ac_power_w`, alias
del contatore `sensor.sdm120_ch3_active_power_w_raw` (SDM120 CH3, ramo AC).
Non è presente nel repository alcuna entità `ADM`; non è quindi dimostrabile
che “ADM” e `sensor.ac_power_w` siano la stessa misura.

## Percorso canonico

1. Comfort/temperature/umidità producono `binary_sensor.ac_*_comfort_request`.
2. Planner e gerarchia producono `sensor.cm_system_mode_suggested`, con
   `COOL_DAY`, `COOL_NIGHT` o `COOL_BOTH`.
3. `automation.climateops_system_actuate` invoca `script.ac_giorno_apply` o
   `script.ac_notte_apply` dopo i lock min-on/min-off.
4. Lo script imposta `climate.ac_*`, accende `switch.ac_*` e invoca il driver
   `script.ac_hw_press`.
5. UI e proxy mostrano lo stato del comando/switch; il dato elettrico è
   separato e non era usato come conferma del funzionamento.

## Correzione reversibile

`packages/climate_ac_observability.yaml` aggiunge tre stati osservabili senza
modificare alcun comando:

- `sensor.ac_branch_operating_state`: `confirmed_on`, `off`,
  `indeterminate_hysteresis_band`, `unknown` o `calibration_required`;
- `sensor.ac_giorno_operating_state`;
- `sensor.ac_notte_operating_state`.

Il binary sensor del ramo usa isteresi reale: richiede almeno 80 W per
accendersi, resta confermato nella banda 30–80 W e perde la conferma solo sotto
30 W, con `delay_on` e `delay_off` temporali di 1 minuto. Se la misura non è
disponibile o HA è in riavvio, l’entità diventa `unavailable`/`unknown`, mai
`off`.

La calibrazione Recorder ha prodotto `ON = 80 W`, `OFF = 30 W`: nello standby
osservato il massimo è 16,98 W, mentre le finestre certamente attive hanno
campioni da 101,4 W a 426,99 W. Il margine evita di classificare ventilazione
o standby come compressore. La misura è campionata circa ogni 30 secondi; il
ritardo temporale ON/OFF implementato è di 1 minuto. Il ritardo è temporale: non garantisce un numero esatto di campioni Recorder.
Anche dopo la calibrazione la misura CH3 potrà confermare solo il ramo AC, non
la singola unità quando giorno e notte sono contemporaneamente richiesti.

Finestre di calibrazione osservate il 22 settembre (ora italiana):

- `00:43–01:30`: `switch.ac_notte` ON, potenza attiva fino a 426,99 W;
- `02:53–03:40`: `switch.ac_notte` ON, potenza attiva fino a 285,04 W;
- `16:13–20:13`: `switch.ac_notte` ON ma potenza 7,93–16,98 W;
- `20:13` `switch.ac_giorno` ON; fino alla fine dei dati osservati la potenza
  resta 8,47–15,85 W.

Il sensore `sensor.ac_power_w` e il raw
`sensor.sdm120_ch3_active_power_w_raw` hanno gli stessi 68.684 campioni e gli
stessi valori nella finestra verificata: nel runtime sono lo stesso canale
derivato, non due misure indipendenti. Il ramo è condiviso.

## Evidenza live e limiti

Acquisiti direttamente dal Recorder, in Europe/Rome, dal 2026-09-22 15:30:

- history/export di `climate.ac_giorno`, `climate.ac_notte`,
  `switch.ac_giorno`, `switch.ac_notte`, i due proxy, i due driver;
- `sensor.ac_power_w` e `sensor.sdm120_ch3_active_power_w_raw`, con timestamp,
  stato di disponibilità e intervallo di campionamento;
- la timeline Recorder dell’automazione e degli script è disponibile solo come
  cambio stato; le trace complete non sono disponibili per il 22 settembre;
- `input_boolean.cm_ac_branch_powered`, `binary_sensor.cm_ac_branch_powered`
  e il relativo contesto/evento;
- configurazione/identità del sensore chiamato ADM, se esiste nel runtime: non
  trovata né nel repository né negli entity/state registrati esaminati.

La retention Recorder parte dal 21 agosto 2026 e quindi copre l’intervallo.
`/config/.storage/trace.saved_traces` contiene invece trace fino al 21 agosto
2026, non quelle del 22 settembre.

Il primo mismatch dimostrabile è il 2026-09-22 16:13:04 CEST: `switch.ac_notte`
passa ON, seguito dal proxy e dal driver, mentre `sensor.ac_power_w` resta
10,27–13,67 W. Questo è lo stesso livello del periodo standby precedente
(7,93–16,98 W), quindi il comando è stato dichiarato acceso senza conferma
fisica. La misura è disponibile in quel periodo: non è un caso `unknown`.

La PR draft #482 contiene cinque file M65 (package, rapporto, README sensori e le due viste); il merge e il deploy non sono stati eseguiti.

## Matrice di evidenza

- **Standby**: verificato dai dati, 4.928 campioni nel periodo esteso a `<=30 W`;
- **funzionamento confermato del ramo**: verificato dai dati, 174 campioni a `>=80 W` nelle finestre attive storiche;
- **isteresi 30–80 W**: nessun campione osservato nella retention; transizioni ON → banda → OFF provate con test della logica candidata, non dal Recorder;
- **misura assente (`unknown`/`unavailable`)**: nessun caso osservato nella retention; ramo verificato solo staticamente nella logica candidata e dal `check_config`;
- **ramo condiviso**: verificato dai dati, `sensor.ac_power_w` e `sensor.sdm120_ch3_active_power_w_raw` hanno 3.194 campioni ciascuno e valori coincidenti nella finestra post-guasto; non consentono attribuzione alla singola unità.

`unknown` copre una misura dichiarata indisponibile (`unknown`/`unavailable`). Un misuratore fermo sull’ultimo valore ma ancora disponibile non viene rilevato da questa logica: richiede un controllo di freschezza separato, da introdurre solo dopo aver verificato dati e comportamento.

### Riavvio HA e freschezza della misura

La logica operativa ora controlla prima lo stato del binary sensor di conferma:
se è `unknown` o `unavailable`, `sensor.ac_branch_operating_state` è
`unknown` anche quando `sensor.ac_power_w` espone temporaneamente un numero
ripristinato. La transizione è stata provata con test mirato della logica, senza
inviare comandi al clima; non è stata osservata nel Recorder storico.

Nel repository non esiste un heartbeat o timestamp indipendente che attesti una
lettura Modbus SDM120 riuscita: `packages/sdm120_modbus.yaml` aggiorna le
entità derivate con un trigger periodico di 30 secondi, ma non espone l'esito
della lettura. Nel runtime, le ultime 24 ore del canale raw hanno 2.855
campioni, gap mediano 30,064 s, p95 30,066 s e massimo 60,178 s; non ci sono
stati `unknown` e non risultano coppie consecutive identiche nel Recorder.
Questo non dimostra che un valore fermo venga rilevato: il Recorder registra il
valore, non il successo della lettura Modbus.

Il punto d'integrazione corretto è il produttore Modbus/SDM120: esporre un
`last_success_timestamp` o contatore monotono aggiornato solo dopo una lettura
riuscita, insieme a disponibilità, errori e intervallo. Servono 24–48 ore di
raccolta passiva di questi segnali; il timeout va scelto dal p99/massimo dei gap
normali e dal numero di poll persi documentato. Non è stato introdotto un
surrogato basato su `last_changed`/valore di potenza né un timeout arbitrario.

## Pre-mortem

- Picco transitorio: soglia ON a 80 W e conferma dopo un minuto continuo sopra soglia;
- Standby/ventilazione: ricavare la banda OFF/ON da campioni con compressore
  sicuramente fermo e attivo; mantenere la banda isteretica.
- Misuratore guasto: `unknown`/`calibration_required`, mai `off`; la
  disponibilità del binary sensor diventa falsa.
- Misura condivisa: non attribuire `confirmed_*` a giorno o notte senza un
  secondo misuratore o una correlazione esclusiva comando→potenza.

## Provenienza operativa

- macchina operativa: workstation Windows condivisa, repository `C:\2_OPS\aeb`;
- runtime target: Casa Mercurio HA Docker/Core su `mercurio-edge` via Tailscale
  (`100.97.27.122`), container `homeassistant` e DB Recorder letto in sola
  lettura;
- legacy `.84:2222`: non usato;
- accesso: SSH read-only da DS-WORK via alias `mercurio-edge`;
- deploy/modifiche runtime/comandi impianto: no;
- commit/PR: PR draft #482 sul branch `codex/m65-ac-feedback-20260923-v3`; il merge e il deploy non sono stati eseguiti; GitHub Actions: nessun check pubblicato al momento della verifica;
- trace: `trace.saved_traces` disponibile ma fermo al 2026-08-21; non contiene
  trace del 22 settembre, quindi la correlazione event-level della trace non è
  disponibile oltre la timeline Recorder.

