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

La calibrazione Recorder ha prodotto `ON = 80 W`, `OFF = 30 W`: nello standby
osservato il massimo è 16,98 W, mentre le finestre certamente attive hanno
campioni da 101,4 W a 426,99 W. Il margine evita di classificare ventilazione
o standby come compressore. La misura è campionata circa ogni 30 secondi; il
ritardo ON/OFF implementato è temporale, pari a 60 secondi; non equivale a una
garanzia di due campioni consecutivi.
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

## Pre-mortem

- Picco transitorio: soglia ON a 80 W e conferma dopo 1 minuto; il picco deve
  superare due campioni consecutivi.
- Standby/ventilazione: ricavare la banda OFF/ON da campioni con compressore
  sicuramente fermo e attivo; mantenere la banda isteretica.
- Misuratore guasto: `unknown`/`calibration_required`, mai `off`; la
  disponibilità del binary sensor diventa falsa.
- Misura condivisa: non attribuire `confirmed_*` a giorno o notte senza un
  secondo misuratore o una correlazione esclusiva comando→potenza.

## Provenienza operativa

- macchina operativa: workstation Windows condivisa, repository `C:\2_OPS\aeb`;
- runtime target: Casa Mercurio HA Docker/Core su `mercurio-edge` via Tailscale
  (`100.97.27.122`), container `homeassistant` e DB Recorder letto in sola lettura;
- legacy `.84:2222`: non usato;
- accesso: SSH read-only da DS-WORK via alias `mercurio-edge`;
- deploy package M65: sì, dal merge `26480ef357e9d66073b3ede047addaa042ab418a`;
  nessun comando al clima e nessun aggiornamento Sonoff LAN;
- Quality Gates PR #483: PASS prima del merge;
- trace: `trace.saved_traces` disponibile ma fermo al 2026-08-21; non contiene
  trace del 22 settembre, quindi la correlazione event-level della trace non è
  disponibile oltre la timeline Recorder.

## Addendum post-deploy PR #483

Il merge `26480ef357e9d66073b3ede047addaa042ab418a` ha deployato il package
moderno. L’hash del file sul runtime è
`6030603304dfcdbefbf051fa54f75a487962bd7ef823fec561ac4e06b35bccfb`, uguale
all’hash atteso del merge. Le entità moderne risultano attive.

La finestra Recorder visualizzata in sola lettura (Europe/Rome,
2026-09-23 21:40–21:50) mostra:

- `binary_sensor.ac_notte_comfort_request`: `on` per tutta la finestra;
- `switch.ac_notte`: `off`, con una breve transizione `unknown` e ritorno a
  `off` intorno alle 21:44–21:47;
- `sensor.ac_power_w`: circa 12–13 W fino alle 21:46, picco naturale di circa
  310 W e poi 400 W intorno alle 21:46–21:47, quindi ritorno a circa 13 W;
- `binary_sensor.ac_branch_power_confirmed`: `off`/“Non in esecuzione” per
  l’intervallo visualizzato;
- `sensor.ac_branch_operating_state`: `off` prima e dopo il picco, senza una
  transizione runtime dimostrabile a `confirmed_on`;
- `sensor.ac_notte_operating_state`: `off`, con una breve fase `unknown`,
  senza `confirmed_on` dimostrato.

Conclusione: il picco naturale dimostra che il ramo ha assorbito potenza, ma
non dimostra la conferma ON dopo 60 secondi perché il binary sensor di
conferma è rimasto OFF nella finestra disponibile. Il rilascio sotto 30 W è
coerente con lo stato OFF osservato successivamente, ma la sequenza completa
ON → banda → OFF non è dimostrata dal Recorder. Campioni runtime nella banda
30–80 W: non osservati; comportamento verificato dai test logici.

La UI HA Repairs non mostra avvisi pendenti. I tre ID legacy ancora presenti
nel registro persistente sono record storici del primo deploy e non issue aperti
nella UI; non sono stati modificati direttamente. La mancata lettura del
filesystem via SSH non impedisce di verificare il package attivo: check_config,
hash di deploy ed entità attive sono coerenti; resta però un limite di audit
del filesystem runtime, non una prova aggiuntiva del comportamento ON.

Questa conclusione è superata dal ciclo naturale documentato più avanti; il
heartbeat Modbus indipendente resta comunque rischio accettato e attività
separata.

## Verifica modalità manuale ClimateOps

La modalità esposta dalla plancia è `input_boolean.ac_manual`, con
`input_select.ac_manual_mode` e `timer.ac_manual_timeout` dichiarati in
`packages/climate_ac_mapping.yaml`. Nel codice attuale, però, il percorso
canonico `automation.climateops_system_actuate` non legge `input_boolean.ac_manual`
né `input_select.ac_manual_mode`; la modalità manuale documentata è quindi un
helper legacy/non collegato e non garantisce l’isolamento dall’automazione.

Il controllo effettivamente usato dall’attuatore è
`input_boolean.ac_auto_pause`. Si attiva nello spegnimento manuale di uno
switch, avvia `timer.ac_auto_pause_timeout` per 90 minuti, spegne entrambe le
unità e impedisce a `climateops_system_actuate` di riaccenderle durante la
pausa. Restano attivi i lock min-on/min-off, il failsafe e il writer-authority
check; il rientro avviene allo scadere del timer o tramite
`script.ac_resume_automatic`, che cancella il timer e spegne la pausa.

Stato HA letto prima di qualsiasi prova: `input_boolean.ac_manual=off`,
`input_boolean.ac_auto_pause=off`, entrambi gli switch AC `off`, richiesta
giorno `off`, richiesta notte `off`, priorità AC `idle`, motivo `idle`.
Non è stata attivata alcuna modalità e non è stato inviato alcun comando:
poiché `ac_manual` non isola realmente l’automazione, il test M65 resta
bloccato finché non esiste un percorso manuale verificato o un isolamento
operativo esplicito che preservi le protezioni.

## Evento naturale post-deploy osservato il 23 settembre 2026

Osservazione HA/Recorder in sola lettura, senza comandi, modalità, setpoint o
riavvii. L’unità notte era la sola richiesta/attuata (`COOL_NIGHT`); giorno e
relativi proxy sono rimasti spenti. Il ramo resta condiviso e la potenza non è
attribuita alla singola unità.

- `2026-09-23 22:13:01 CEST` (`20:13:01Z`):
  `sensor.ac_power_w` circa 218 W; richiesta notte e switch/proxy notte attivi,
  giorno spento.
- `2026-09-23 22:14:42.510 CEST` (`20:14:42.510Z`):
  `binary_sensor.ac_branch_power_confirmed=on`,
  `sensor.ac_branch_operating_state=confirmed_on`, stato operativo ramo
  “In esecuzione”; la potenza era ancora sopra 80 W (circa 216 W nella
  lettura Recorder immediatamente precedente).
- `2026-09-23 22:15:46 CEST` e `22:16:58 CEST`: conferma ancora attiva; la
  potenza Recorder era circa 211–216 W. Nessun campione 30–80 W osservato.
- `2026-09-23 22:19:13 CEST`: conferma ancora attiva; il ciclo naturale non
  era ancora rientrato. Il pannello mostrava un lock minimo ON di 45 minuti.

La conferma ON è quindi dimostrata dopo il ritardo temporale previsto e il ramo
è rimasto sopra 80 W. Il rilascio sotto 30 W e la conferma OFF sono documentati
nella successiva ricostruzione del ciclo completo.

Aggiornamento Recorder in sola lettura, finestra consultata da `22:41` a
`22:57 CEST`: il ciclo è poi rientrato, ma la finestra contiene anche un calo
intermedio mentre `switch.ac_notte` era ancora acceso.

- Alle `22:41:03 CEST` (`20:41:03Z`) la potenza era circa 219 W e la
  conferma era ancora attiva.
- Nella vista 22:47–22:57 CEST si osserva un primo calo a circa 20–25 W verso
  `22:50`, seguito da un secondo picco naturale di circa 100–175 W verso
  `22:53–22:54`; il primo calo non è quindi il comando OFF finale.
- La banda di `switch.ac_notte` e del proxy passa visivamente a OFF circa alle
  `22:54`; la potenza torna nell’ordine di 20 W e la vista mostrava 16 W alle
  `22:56:17.671 CEST` (`20:56:17.671Z`). Questo è un riferimento osservato,
  non un timestamp evento esatto.
- Alle `22:57:07 CEST` (`20:57:07Z`) la dashboard mostrava entrambe le
  richieste/switch/proxy OFF, `binary_sensor.ac_branch_power_confirmed=off`
  ("Non in esecuzione") e `sensor.ac_branch_operating_state=off`
  ("Spento").

La superficie Recorder disponibile tramite UI espone il grafico e gli stati
finali, ma non i timestamp `last_updated` dei singoli cambi. Non è quindi
possibile calcolare in modo riproducibile né il tempo comando OFF → primo
campione sotto 30 W, né primo campione sotto 30 W → conferma OFF, né provare
il ritardo temporale di 60 secondi per il rilascio. Il solo dato mancante
necessario è un export/event-level Recorder o API in sola lettura con i
timestamp di: switch/proxy OFF, primo valore stabilmente sotto 30 W,
`ac_branch_power_confirmed=off` e `ac_branch_operating_state=off`.

La conferma ON resta dimostrata. La conferma OFF è osservata nello stato
finale entro le 22:57:07, ma il suo ritardo non è dimostrato; M65 resta
`ACTIVE`. La banda 30–80 W non è stata osservata runtime. La funzione
post-OFF e il consumo intermedio sono descritti separatamente nella sezione
manuale seguente e non vengono inferiti dai soli watt osservati.

## Manuali e comportamento dopo OFF

È stato letto il manuale d’uso ufficiale Toshiba, collegato dalla pagina
prodotto [Toshiba R32 RAS Multi-split Ducted](https://www.toshiba-aircon.co.uk/en/products/r32-split-systems/residential/multi-split/ras-ducted.html),
PDF “Owner’s Manual R32 or R410A”, che include esplicitamente i modelli
`RAS-M07U2DVG-E`, `RAS-M10U2DVG-E` e `RAS-M13U2DVG-E` (pagina 1 del PDF).
La sezione “Self Cleaning Operation (Cool and Dry Operation Only)” indica
che, se attivata durante COOL o DRY, la ventola può continuare per altri 30
minuti per ridurre l’umidità nell’unità interna; se il precedente
funzionamento COOL/DRY è durato meno di 10 minuti, l’autopulizia non viene
eseguita. Il manuale indica anche il comando per arrestare immediatamente la
funzione. È evidenza della possibilità di funzionamento residuo, non prova
che la funzione fosse attiva nel ciclo M65.

È stato inoltre letto il documento originale disponibile in Dropbox:
`C:\Users\ds\Dropbox\1_Privato\1_Casa\Casa_Mercurio_71C\2_Materiali_tecnici\1_Impianti\Progetti impianti\T01 CLIMA.PDF`.
È un disegno esecutivo dell’impianto, non un manuale d’uso/manutenzione. Identifica
la famiglia Toshiba delle unità interne canalizzabili
`RAS-M07U2DVG-E`, `RAS-M10U2DVG-E`, `RAS-M13U2DVG-E` e le unità esterne
`RAS-2M14U2AVG-E` / `RAS-2M18U2AVG-E`; non assegna in modo esplicito il singolo
modello alle entità giorno/notte.

Il manuale ufficiale documenta la possibilità e la durata massima nominale
della funzione di autopulizia, ma non fornisce una potenza elettrica
caratteristica. I circa 20 W osservati verso le 22:54 non sono quindi
attribuiti automaticamente all’autopulizia: manca la prova che la funzione
fosse attiva e la misura è del ramo condiviso.

Gli eventi M65 restano distinti:

1. comando OFF o transizione dello switch/proxy a OFF;
2. eventuale funzionamento residuo dopo OFF, che può includere autopulizia ma
   non è identificabile dai soli 20 W;
3. discesa stabile sotto 30 W, dalla quale decorre il `delay_off` M65 di 60
   secondi fino alla conferma OFF.

Un eventuale consumo post-OFF non viene chiamato automaticamente compressore
o ventilazione; servono correlazione temporale, stato della funzione e/o
misura compatibile. Valori prossimi allo standby non distinguono da soli
autopulizia e standby.

Il rischio di un valore Modbus fermo ma ancora disponibile resta accettato
soltanto per l’uso diagnostico corrente; `confirmed_on` non deve alimentare
automazioni, comandi o funzioni di sicurezza finché non esiste un heartbeat
indipendente della lettura Modbus.

## Chiusura M65 e limiti residui

Il ciclo naturale ha verificato sul runtime l’obiettivo originario di M65:
richiesta/comando SwitchBot e proxy restano distinti dal funzionamento
fisico del ramo condiviso. Sono stati osservati `confirmed_on` durante il
ciclo naturale e il successivo stato `off` con potenza sotto 30 W. La potenza
non è attribuita alla singola unità.

Il `delay_off` esatto di 60 secondi e la banda 30–80 W sono verificati dalla
logica e dai test riproducibili, ma non sono stati misurati con precisione nel
ciclo Recorder perché la UI disponibile non espone i timestamp event-level.
Il rilascio OFF runtime è quindi un’evidenza di stato finale sotto soglia,
non una misura più precisa del timer.

Davide ha osservato direttamente la spia arancione durante l’autopulizia. La
testimonianza è coerente con la funzione Self Cleaning documentata dal manuale
Toshiba, ma non collega automaticamente i circa 20 W osservati alle 22:54 a
quella funzione. L’`off` del ramo sotto soglia certifica il rilascio della
conferma elettrica M65, non l’arresto della ventola interna.

In sola lettura, il `2026-09-24`, HA Repairs mostrava: “Al momento non ci sono
riparazioni in sospeso”. I tre identificativi legacy storici non sono quindi
issue aperti.

Stato governance: `M65 = CLOSED`, archiviabile. Restano espliciti questi
limiti: misura elettrica condivisa; banda 30–80 W non osservata runtime; durata
del funzionamento dopo OFF non misurata; rischio di valore Modbus stale accettato
solo per diagnostica. Senza heartbeat indipendente, `confirmed_on` non deve
essere usato per controllo, comandi o sicurezza.

