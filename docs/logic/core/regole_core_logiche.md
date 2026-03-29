# Regole core logiche

Documento di riferimento condiviso per tutti i moduli logici (ventilation, heating, ac, energy_pm, surplus, debug/test). Qui si definiscono convenzioni, priorità trasversali, lock e hook incrociati: ogni modulo deve rimandare a queste sezioni evitando duplicazioni locali.

## Convenzioni di nomenclatura
- **Prefissi di modulo**: `1_vent`, `2_vmc`, `3_heat`, `4_ac`, `5_pm`, `6_surplus`, `9_debug`. Usarli sia nei file logici sia nelle entità HA (sensor/switch/input_boolean/input_number).
- **Entità sensori/attuatori standard**: suffissi `_in_giorno`, `_in_notte`, `_in_bagno` per ambienti; `*_out` per meteo esterno; `switch.<modulo>_*` per attuatori; `binary_sensor.<modulo>_*` per flag logici; `input_number.<modulo>_*` per soglie regolabili; `timer.<modulo>_*` per lock/timeout.
- **Manual override**: ogni modulo espone `input_boolean.<modulo>_manual` e, se serve, `input_select.<modulo>_manual_mode` con `timer.<modulo>_manual_timeout` per il rientro automatico.
- **Nomi hook**: sempre snake_case con prefisso `hook_` e indicazione sorgente→target (es. `hook_vmc_request_ac_block`).

## Schema delle priorità (P0–P4)
Arbitraggio top-down: si valuta dal livello più alto al più basso; la prima condizione vera imposta l’azione e applica i lock indicati.

| Priorità | Trigger tipici | Azione standard | Condizione di uscita | Lock applicati | Note cross-modulo |
| --- | --- | --- | --- | --- | --- |
| **P0 – Emergenza/failsafe** | Sensori offline, allarme fumi/allagamento, manual OFF hard | Forzare OFF/vel_0, disabilitare automazioni | Ripristino sensori + ack manuale | min_off di sicurezza | Può essere forzata da 9_debug via `hook_debug_force_state` |
| **P1 – Sicurezza/anti-secco** | UR interna < soglia o rischio condensa; override notturno | Limitare VMC (vel_0/vel_1), preferire DRY minimo, sospendere free-cooling/COOL | UR rientra + timeout lock | min_on/min_off anti-secco | `hook_vmc_request_ac_block` blocca AC se ΔAH sfavorevole |
| **P2 – Comfort** | Boost bagno, richiesta riscaldamento, COOL/DRY attivi, ventilazione estiva | Impostare setpoint/velocità operative del modulo | Uscita da trigger principale + max_run | min_on/min_off specifici | `hook_ac_request_vmc_low` per sincronizzare DRY con VMC low |
| **P3 – Efficienza/ottimizzazione** | Free-cooling, sfruttamento PV, pre-carica heating da surplus | Attivare modalità efficienti (vel_2 VMC, night-flush, pre-carica pavimento, carichi surplus) | Condizione meteo/energia non più valida | max_run efficiency | `hook_surplus_heating_precharge` abilita finestra di carica |
| **P4 – Diagnostica/monitoraggio** | Modalità debug/test attiva | Esporre stati e KPI senza modificare attuatori (read-only) | Manuale | Nessuno | `hook_debug_force_state` può simulare priorità inferiori |

## Tabella lock (min_on / min_off / max_run)
| Modulo | Scenario | min_on | min_off | max_run | Note |
| --- | --- | --- | --- | --- | --- |
| **VMC** | Anti-secco/anti-condensa | 5m | 10m | — | Limitare cicli vel_0/vel_1 in P1 |
| | Free-cooling / night-flush | — | — | 120m | Interrompere se ΔT/ΔAH non più favorevole |
| **AC** | DRY | 10m | 10m | 60m | Richiede ΔAH favorevole o VMC low |
| | COOL | 15m | 15m | 90m | Blocchi notturni 23–7 gestiti come P0 locale |
| **Heating** | Pavimento inerziale | 15m | 30m | 180m | Fascia attiva 10:00–18:00 salvo emergenza |
| **Surplus** | Carichi a step | 20m | 20m | 180m | Coordinare con PV/batteria e pre-carica heating |

## Heating — Pavimento, lock e priorità
| Aspetto | Regola/Obiettivo | Note/Hook |
| --- | --- | --- |
| **T_target giorno/notte** | Comfort 21 °C di default, modulabile via input_number; riduzione notturna ammessa ma senza spegnere inerzia | Le plance mostrano T_target e T_in; differenze zona bagno gestite nel modulo locale |
| **Finestra prioritaria** | 10:00–18:00: valutata prima di altri slot per sfruttare PV/guadagni solari | Derogabile da P0/P1 o override manuale; se `hook_surplus_heating_precharge` è attivo può partire a inizio finestra |
| **Lock pavimento** | min_on 15m, min_off 30m, max_run 180m | Applicati all’uscita `heating_should_run` per evitare cicli brevi; rispettati anche in manual/force-on |
| **Ingresso** | Accende se almeno una zona attiva è sotto T_target−isteresi **e** fascia 10–18 valida **e** surplus/energia ok (se richiesto) | In assenza di surplus non anticipa la partenza prima di 10:00 salvo comfort critico |
| **Uscita** | Spegne quando T_target raggiunta, fine finestra o mancanza surplus se usato come vincolo; max_run forza uscita se tutto il giorno | Lock min_off mantiene il pavimento spento abbastanza da sfruttare inerzia |
| **Interazione surplus** | Surplus P3 abilita pre-carica in finestra utile; `hook_surplus_heating_precharge` sblocca anticipi e priorità rispetto ad altri carichi | Se PV insufficiente, heating resta subordinato a comfort minimo e lock |

## Regole stagionali e orarie
- **Fasce notte/giorno**: AC blocco 23:00–07:00 salvo override manuale; ventilazione night-flush 21:00–08:00.
- **Finestre pavimento**: heating prioritizza 10:00–18:00 per sfruttare PV/guadagni solari, con deroga P0/P1.
- **Ventilazione estiva**: preferire aperture quando ΔT_out<in e ΔAH_out<in; sospendere con vento forte/pioggia/PM alti.

## Glossario soglie condivise
- **ΔT**: differenza T_in−T_out; **ΔAH**: differenza AH_in−AH_out.
- **UR_max**: soglia igrometrica che separa anti-secco (bassa UR) da condensa (alta UR).
- **T_target giorno/notte**: setpoint comfort; modulabile per heating/AC.
- **Soglia surplus PV**: potenza minima disponibile per attivare carichi step (rif. docs/logic/surplus/README.md).

## Vent — Ventilazione naturale & night-flush
| Aspetto | Regola core | Note/Hook |
| --- | --- | --- |
| **Obiettivo** | Raffrescare passivamente in estate consigliando apertura/chiusura serramenti e gestendo night-flush 21:00–08:00 | Valido su finestre apribili; inverno demandato a VMC |
| **Criteri apertura (giorno/sera)** | Apri/consiglia se **ΔT_out<in** e **ΔAH_out<in** superano soglie minime; meteo OK (no pioggia, vento sotto soglia, PM accettabile) | Se uno dei due Δ non è favorevole → nessun consiglio di apertura |
| **Criteri chiusura** | Chiudi/sconsiglia se T_out ≥ T_in, AH_out ≥ AH_in o meteo avverso (pioggia/vento forte/PM alti) | Ripristina stato baseline finché condizioni non tornano favorevoli |
| **Night-flush** | Fascia 21:00–08:00: se T_out < T_in **e** AH_out < AH_in con meteo OK → attiva ciclo di flush; preferire serramenti aperti + VMC vel_2 | Bloccare AC/COOL durante flush; evitare con vento forte/pioggia/PM alti |
| **Lock** | Durata minima ciclo night-flush e max_run 120m; tempo tra cicli per evitare ping-pong; meteo deve restare valido per mantenere il flush | Se ΔT/ΔAH si annullano → uscita anticipata e rispetto min_off |
| **Coordinamento VMC/AC** | Con night-flush/free-cooling inviare `hook_vent_enable_night_flush` verso VMC/AC: VMC → vel_2, AC → blocco COOL | VMC può continuare anti-secco in inverno senza attivare flush |

## Surplus — Energia FV, carichi e hook
| Aspetto | Regola core | Note/Hook |
| --- | --- | --- |
| **Obiettivo** | Massimizzare uso PV attivando carichi a priorità progressiva e abilitando pre-carica heating se c'è margine energetico | Evitare import da rete salvo carichi critici |
| **Criteri surplus/deficit** | Calcolo su potenza FV istantanea vs consumo casa (e batteria se presente): **Surplus** se PV−carichi ≥ soglia e batteria non in carica prioritaria; **Deficit** se import prolungato o PV sotto soglia | Soglie configurabili via input_number; evitare oscillazioni usando media breve |
| **Sequenza carichi a step** | Step ordinati per priorità: es. Step1 boiler/presa lenta, Step2 carico opzionale/EV veloce, Step3 eventuali extra; ogni step entra solo se surplus stabile sopra soglia (eventualmente 2× per step successivi) | Disattivazione inversa quando deficit; nessun salto diretto se lock attivi |
| **Lock** | `min_on`/`min_off` 20m e `max_run` 180m per gli step; lock applicati per evitare cicli rapidi e sovraccarico | Lock condivisi con tabella lock; timeout rientri gestito da timer locali |
| **Hook heating** | `hook_surplus_heating_precharge` alto quando surplus stabile e fascia heating utile: abilita pre-carica pavimento o anticipo accensione | Heating usa l'hook come abilitazione, ma rispetta i propri lock e comfort |
| **Interazione AC** | Surplus non forza COOL: se comfort già raggiunto non alimentare carichi AC aggiuntivi; evitare che surplus mantenga AC attiva oltre max_run | DRY/COOL seguono regole AC e possono ignorare surplus se blocchi attivi |
| **Uscita da P3** | Se deficit persistente o batteria prioritaria → spegnere progressivamente gli step e abbassare hook heating | Rientro in P3 solo dopo rispetto min_off e nuova validazione surplus |

## Pattern funzionali
- **Anti-secco**: se UR_in < UR_min → VMC in vel_0/vel_1 e DRY minimo; rientro quando UR_in ≥ UR_min+isteresi. Priorità P1, applica lock anti-secco.
- **Free-cooling**: attivo se ΔT_out<in < −ΔT_fc e ΔAH_out<in < −ΔAH_fc con meteo ok; eleva VMC (vel_2) e blocca COOL tramite `hook_vmc_request_ac_block`. Max_run 120m.
- **Override AC↔VMC**: AC in DRY richiede VMC low (`hook_ac_request_vmc_low`); AC in COOL può bloccare VMC se ΔAH sfavorevole; VMC in anti-secco può bloccare DRY.

## AC — Modalità, lock e interazioni
Tabella riassuntiva DRY/COOL con trigger termo-igrometrici, vincoli orari e lock. Le soglie numeriche puntuali sono definite nel modulo AC.

| Modalità | Trigger principali | Condizioni d’ingresso | Uscita/stop | Lock applicati | Note/hook |
| --- | --- | --- | --- | --- | --- |
| **DRY** | UR alta o ΔAH_out<in favorevole (aria esterna più secca) con Tin sotto soglia COOL | Fascia consentita, sensori validi, richiesta VMC low disponibile | UR ≤ UR_target oppure Tin ≤ T_target_giorno/notte oppure max_run 60m | min_on 10m, min_off 10m, max_run 60m | Richiede `hook_ac_request_vmc_low`; se `hook_vmc_request_ac_block` attivo sospende l’ingresso |
| **COOL** | Tin > setpoint_giorno/notte + isteresi oppure richiesta comfort caldo+umido; fascia oraria 07–23 | Fascia OK (`ac_fascia_ok`), nessun blocco notturno salvo emergenza/manuale | Tin ≤ T_target + isteresi oppure blocco notturno 23–07 oppure max_run 90m | min_on 15m, min_off 15m, max_run 90m | Blocchi notturni applicati come P0 locale; può sospendere VMC alta umidità con `hook_vmc_request_ac_block` |

### Regole comuni AC
- **Setpoint giorno/notte**: T_target e isteresi sono differenziate per zona; di notte si privilegia comfort minimo e blocco COOL salvo override manuale/emergenza.
- **Blocco notturno 23–07**: COOL disabilitato nella fascia, DRY ammesso solo se richiesto da emergenza UR e coordinato con VMC; override manuale può forzare eccezioni.
- **Anti on/off**: gli switch/climate applicano min_on/min_off e max_run (vedi tabella lock) con contatori runtime; `ac_should_run` viene filtrato da questi lock per evitare cicli rapidi.
- **Hook VMC**: `hook_vmc_request_ac_block` blocca DRY/COOL quando free-cooling/ΔAH sfavorevole; `hook_ac_request_vmc_low` forza VMC in vel_0/vel_1 durante DRY. Gli hook sono bidirezionali e rispettano i lock attivi.
- **Setpoint DRY**: DRY attiva un setpoint conservativo (no raffrescamento spinto) mantenendo Tin sotto soglia COOL per evitare sovrapposizioni.

## VMC — Priorità, lock e schemi
Tabella riassuntiva delle priorità specifiche VMC (top-down). Le soglie numeriche seguono i valori standard Casa Mercurio: UR bagno ON≈75%, OFF≈65%, soglia UR bassa≈40%; free-cooling con T_in>24 °C, T_out<T_in, AH_out<AH_in. Il trigger boost su ΔUR bagno/esterno e` opzionale (default OFF) e configurabile.

| Priorità | Trigger | Azione | Uscita | Lock applicati | Note |
| --- | --- | --- | --- | --- | --- |
| **P0 – Failsafe/override AC** | Sensori critici mancanti/allarmi; AC notte in DRY → richiesta vel_0 | Forza vel_0 e disabilita automazioni | Ripristino sensori o AC esce da DRY | min_off sicurezza | Watchdog ripristina vel_1 se inattivo >10m |
| **P1 – Boost bagno** | UR bagno sopra soglia; opzionale: ΔUR bagno/esterno sopra soglia se trigger ΔUR abilitato | Vel_3 (boost), downgrade a vel_2 se esterno molto più secco | UR rientra sotto soglia + ΔUR ridotto; rilascio anche se aria esterna piu` umida (ΔUR fortemente negativo) | min_on 10m, cooldown 5m | Scavalca free-cooling; può attivare escalation DRY |
| **P1-lite – ΔUR interno/esterno** | UR_media >50% e ΔUR_media≥10pt con bagno non in boost | Vel_2 | ΔUR_media <8pt o UR_media ≤48% o runtime 8m o AH_out≥AH_in | min_on 5m | Subordinato a P1 e P2 |
| **P1B – Supporto AC DRY** | Boost bagno attivo da lungo tempo e UR ancora alta | Richiede AC in DRY mantenendo VMC vel_1 | UR sotto isteresi o max_run 120m | min_on AC 30m | Usa `hook_vmc_request_ac_block` al rilascio |
| **P2 – Free-cooling** | Condizioni termo-igrometriche favorevoli (vedi schema) | Vel_2 e blocco COOL/DRY se ΔAH sfavorevole | ΔT/ΔAH non più validi | min_on 15m, max_run 120m | Prevale schema PASSIVHAUS se valido |
| **P3 – Anti-secco notturno** | Nov–Mar, 23–07, UR_in_min ≤40% e nessun boost bagno | Vel_0 con duty vel_1 5m ogni 30m; blocca richieste DRY | Fine finestra o UR >42% | min_on 5m, min_off 10m | Può inibire AC DRY tramite hook |
| **P4 – Baseline** | Nessun trigger attivo | Vel_1 continuo | Pre-emption da priorità superiori | — | Funzione anche da fallback watchdog |

### Schema free-cooling VMC
- **Passivhaus (preferito)**: T_in >24 °C, T_out < T_in, AH_out < AH_in; uscita con T_in ≤23.2 °C oppure T_out ≥ T_in oppure AH_out ≥ AH_in.
- **Modalità macchina (solo termico)**: T_in >24 °C, T_out < T_in e >20 °C; uscita con T_in ≤23.2 °C oppure T_out ≤20 °C oppure T_out ≥ T_in.
- **Meteo valido**: vento/pioggia/PM fuori soglia disabilitano; max_run 120m, lock ingressi 15m.
- **Interazione AC**: se free-cooling attivo o ΔAH esterno più secco → `hook_vmc_request_ac_block` per sospendere COOL/DRY.

### Schema anti-secco
- Attivo in fascia invernale/notturna con UR interna bassa: riduce VMC a vel_0 con brevi impulsi vel_1 per mantenere ricambio minimo.
- Blocca richieste DRY e limita free-cooling se ΔAH sfavorevole; uscita quando UR risale sopra isteresi o termina la finestra.
- Lock anti-secco: min_on 5m, min_off 10m per evitare cicli rapidi.

### Regole di interazione AC↔VMC
- **VMC limita/blocca AC**: in free-cooling o ΔAH esterno più secco invia hook di blocco COOL/DRY; in anti-secco sospende DRY per non sottrarre ulteriore umidità.
- **AC limita VMC**: in DRY richiede vel_0/vel_1 (`hook_ac_request_vmc_low`); in COOL con aria esterna umida può inibire elevazione velocità.
- **Lock VMC**: min_on 10m (boost), 5m (anti-secco/pulse ΔUR), min_off 10m (anti-secco), ingressi free-cooling con lock 15m e max_run 120m.

## Hook cross-modulo
Ogni hook definisce: sorgente, target, evento, payload (boolean/priority), timeout.

| Hook | Sorgente → Target | Evento/Payload | Timeout | Effetto atteso |
| --- | --- | --- | --- | --- |
| `hook_vmc_request_ac_block` | VMC → AC | boolean `ac_block` per ΔAH sfavorevole o free-cooling attivo | fino a fine max_run VMC | AC sospende COOL/DRY |
| `hook_ac_request_vmc_low` | AC → VMC | richiesta `vmc_low` durante DRY per evitare condensa | lock DRY | VMC forza vel_0/vel_1 |
| `hook_surplus_heating_precharge` | Surplus → Heating | boolean `precharge_enable` quando PV > soglia e batteria ok | 180m | Heating anticipa accensione in fascia utile |
| `hook_vent_enable_night_flush` | Vent → VMC/AC | flag `night_flush` per aprire serramenti/vel_2 VMC con meteo ok | 120m | Favorisce free-cooling serale |
| `hook_debug_force_state` | Debug → Tutti | payload `priority_override` per simulazioni/test | 15m | Plancia debug forza priorità e traccia effetti |

## Uso del core nei moduli
- Ogni file logico locale descrive solo eccezioni/parametri specifici (sensori, soglie custom). Le regole comuni rimandano a questo documento.
- Le plance devono citare le sezioni **Priorità**, **Lock** e **Hook** senza ripeterne i dettagli numerici.
