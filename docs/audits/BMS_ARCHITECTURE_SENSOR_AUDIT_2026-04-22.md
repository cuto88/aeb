# BMS Architecture + Sensor Audit (2026-04-22)

Date: 2026-04-22 11:08 +02:00  
Scope: audit tecnico architetturale Casa Mercurio / AEB con focus BMS residenziale, affidabilita`, sensori, fieldbus, HVAC, energia e rollout.

## Fonti usate

- `README.md`
- `README_ClimaSystem.md`
- `docs/SOT_ENTITIES.md`
- `docs/logic/core/README_sensori_clima.md`
- `docs/logic/core/runtime_hardware_profiles.md`
- `docs/audits/CURRENT_RUNTIME_STATUS_2026-04-08.md`
- `docs/audits/STEP18_HARDWARE_AUDIT_ROI_PLAN_2026-02-27.md`
- `docs/audits/STEP19_WAVE1_BOM_INSTALL_PLAN_2026-02-27.md`
- `tmp_core.device_registry`
- `tmp_core.entity_registry`

## SEZIONE 1 - EXECUTIVE SUMMARY

FACT  
Casa Mercurio/AEB e` gia` un BMS domestico evoluto basato su Home Assistant, package modulari, ClimateOps, SOT `cm_*`, policy layer, driver proxy, Modbus/RS485 per MIRAI/SDM120, SolarEdge, VMC, riscaldamento, AC, ACS/EHW e osservabilita` Lovelace.

IPOTESI (confidenza alta)  
Il livello di maturita` e` "advanced retrofit BMS": logica e governance sono molto piu` mature dell'hardware sensoriale. Il software ha gia` una struttura da sistema, mentre parte dei sensori e attuatori resta ancora da ecosistema misto Tuya/SwitchBot/Meross/Sonoff.

DECISIONE  
Non sostituire tutto. Prima consolidare il modello dati, chiudere le authority aperte, poi sostituire solo i sensori critici che limitano affidabilita`, controllo e diagnosi.

Punti forti:
- FACT: esiste Single Source of Truth per entita` clima e layer canonico `cm_*`.
- FACT: ClimateOps ha contratti, policy, planner, proxy driver e KPI.
- FACT: VMC/heating/AC hanno priorita`, reason, lock anti-ciclo e failsafe sensori.
- FACT: SDM120 su RS485/Modbus TCP e` gia` validato per rete elettrica.
- FACT: ACS/EHW ha percorso read/write validato in modo conservativo.
- FACT: dashboard e audit runtime sono gia` parte del processo operativo.

Punti deboli:
- FACT: sensori T/RH principali sono SwitchBot/Tuya, quindi cloud/batteria/radio.
- FACT: CO2 assente.
- FACT: presenza/occupancy non risulta usata come segnale BMS.
- FACT: contatti finestra sono ancora modellati via `input_boolean`, non come feedback fisico affidabile.
- FACT: AC single-writer cleanup e` ancora aperto.
- FACT: MIRAI runtime truth e` parziale, non ancora chiuso su finestra reale `OFF -> RUN`.

Rischio principale:
- IPOTESI (confidenza alta): il rischio non e` la mancanza di automazioni, ma che decisioni sofisticate siano alimentate da segnali deboli, batteria/cloud o feedback fisici incompleti.

Opportunita` principale:
- DECISIONE: portare progressivamente i segnali BMS critici su cablato/PoE/RS485 e lasciare wireless solo dove il dato non e` safety/control-critical.

## SEZIONE 2 - INVENTORY LOGICO

| sistema | funzione | protocollo | stato attuale | read/write | criticita` | priorita` |
|---|---|---|---|---|---|---|
| Home Assistant | runtime BMS | LAN/local | operativo, gate PASS | R/W | SPOF logico se mancano fallback/manuale | alta |
| ClimateOps | orchestrazione clima/energia | template/HA | maturo, contratti e SOT presenti | R/W governato | alcune authority ancora aperte | alta |
| VMC | ventilazione, freecooling, boost bagno | Sonoff LAN / switch | integrata con `switch.vmc_vel_0..3` | W + feedback proxy | dipendenza custom integration, feedback non industriale | alta |
| Heating master | consenso riscaldamento | Tuya relay 4CH | `switch.4_ch_interruttore_3` dietro `switch.heating_master` | W | hardware consumer usato come attuatore critico | alta |
| AC giorno/notte | split via SwitchBot IR/cloud | SwitchBot cloud | operativo, cleanup single-writer aperto | W + stato logico | IR/cloud, feedback stato debole | alta |
| MIRAI/PDC | telemetry idronica/PDC | RS485 Modbus TCP | osservabile, truth parziale | R, potenziale W futuro | validazione RUN non chiusa | alta |
| EHW/ACS | tank, setpoint, writer ACS | Modbus | read/write validato conservativo | R/W | trasporto da governare bene per bootstrap e readiness | alta |
| SDM120 | misura rete | RS485 Modbus TCP `192.168.178.191:502`, 9600 8E1, slave 2 | validato | R | bus condiviso con MIRAI, topologia da proteggere | alta |
| SolarEdge | FV produzione | integrazione SolarEdge | attivo | R | forecast/produzione dipende da feed esterno | media |
| Dual Meter Tuya | misura legacy rete/FV | LocalTuya/Tuya | fallback transitorio | R | custom/cloud/consumer, non target BMS | media |
| Meross PM1/PM2/PM3 | plug energy metering | Meross cloud custom | presenti | R/W | cloud/custom, non ideale per carichi critici | media |
| T/RH indoor giorno/notte/out | comfort e controllo | SwitchBot cloud | presenti | R | batteria/cloud/radio | alta |
| T/RH bagno/notte2 | comfort e VMC bagno | Tuya | presenti | R | batteria/cloud/radio; bagno e` segnale critico VMC | alta |
| contatti finestre | stato apertura | input_boolean | logico/manuale | R virtuale | manca feedback fisico reale | alta |
| CO2 | IAQ/VMC | assente | mancante | R | VMC guidata da UR/AH, non da IAQ reale | alta |
| presenza | occupancy/scheduling | non evidente | assente/non usata | R | logiche basate su fasce, non presenza affidabile | media |
| osservabilita` | KPI, reason, dashboard | HA/Lovelace/Grafana/Influx | forte | R | manca fault tree hardware/sensori unificato | media |

## SEZIONE 3 - ANALISI ARCHITETTURALE

FACT  
La parte logica e` gia` separata in layer: contratti, policy, planner, driver proxy, actuators. Questo e` corretto per un BMS domestico robusto.

IPOTESI (confidenza alta)  
Il collo di bottiglia attuale e` il field/sensor layer, non il control layer.

DECISIONE  
Non aggiungere nuove automazioni finche` non sono chiusi: qualita` dato, writer authority e feedback fisico.

Bottleneck:
- FACT: T/RH critici arrivano da SwitchBot/Tuya.
- FACT: CO2 assente.
- FACT: finestre virtuali, non contatti reali.
- FACT: VMC e heating dipendono da attuatori consumer.
- DECISIONE: classificare i segnali in `control-grade`, `advisory-grade`, `diagnostic-grade`.

Dependency:
- FACT: HA e` il cervello.
- FACT: ClimateOps e` gia` il layer di decisione.
- FACT: Modbus e` usato per PDC/ACS/metering.
- IPOTESI (confidenza media): rete LAN, gateway RS485 e custom integration sono dependency operative piu` importanti dei singoli sensori.
- DECISIONE: documentare e monitorare gateway, bus, alimentazioni, UPS, Wi-Fi e cloud dependency.

State model:
- FACT: esistono reason/priority per VMC, heating e AC.
- FACT: `cm_*` crea un modello canonico.
- FACT: alcuni stati reali sono proxy/logici, non feedback elettrico/fisico.
- DECISIONE: per ogni attuatore critico serve comando + feedback reale o almeno feedback energetico.

Feedback loop:
- FACT: VMC usa T/RH/AH ed e` quindi buona sul comfort igrometrico, ma non ancora IAQ-grade.
- FACT: heating usa T ambiente e logiche temporali/energia; MIRAI e` ancora da chiudere come truth runtime.
- FACT: AC usa SwitchBot/IR/cloud e cicli ricostruiti via history.
- FACT: ACS/EHW e` il load piu` vicino a un controllo governato perche` ha Modbus e writer validato.

Failure mode principali:
- Sensore T/RH batteria scarica: controllo comfort degrada.
- SwitchBot/Tuya cloud down: dato stale o unavailable.
- IR AC non ricevuto: stato logico diverso da stato reale.
- RS485 bus disturbato: MIRAI/SDM120 non leggibili.
- Rele` consumer bloccato: comando HA non coincide con attuazione reale.
- HA down: logiche automatiche ferme, serve manual override chiaro.

Punti di conflitto:
- FACT: AC single-writer cleanup aperto.
- DECISIONE: nessun nuovo writer su AC, heating, VMC, ACS finche` ogni attuatore ha una authority unica dichiarata.

Margini di semplificazione:
- DECISIONE: eliminare sensori legacy/fallback quando SDM120 e` stabile.
- DECISIONE: ridurre dipendenza da plug cloud per metering permanente.
- DECISIONE: spostare contatti e ingressi critici su moduli DI cablati.
- DECISIONE: separare dashboard operative da debug.

## SEZIONE 4 - ANALISI SENSORI

| categoria | stato attuale | problema | impatto | tieni / sostituisci / integra / elimina | priorita` | motivazione tecnica |
|---|---|---|---|---|---|---|
| T/RH indoor giorno | SwitchBot cloud/batteria | radio/cloud/batteria | alto su comfort/AC/VMC | sostituisci o affianca gradualmente | alta | segnale control-grade |
| T/RH notte1 | SwitchBot cloud/batteria | radio/cloud/batteria | alto su comfort notte/AC | sostituisci o affianca gradualmente | alta | zona critica comfort |
| T/RH notte2 | Tuya batteria/cloud | radio/cloud/batteria | medio-alto | sostituisci o affianca gradualmente | alta | riduce affidabilita` medie |
| T/RH bagno | Tuya batteria/cloud | bagno guida boost VMC | alto | sostituisci prima | immediata/breve | failure mode diretto su VMC |
| T/RH outdoor | SwitchBot cloud/batteria | esterno guida DeltaT/DeltaAH | alto | sostituisci o affianca cablato/PoE | alta | dato critico per freecooling |
| CO2 giorno/notte | assente | VMC non vede IAQ reale | alto | integra | alta | driver BMS primario per ventilazione |
| VOC/PM | non evidenti come driver | IAQ incompleta | medio | integra solo se utile | medio termine | meno prioritari di CO2 |
| contatti finestra | input_boolean | nessun feedback fisico | alto | integra cablato dove possibile | alta | blocchi AC/VMC/freecooling dipendono da aperture |
| presenza/occupancy | assente/non usata | fasce orarie al posto di stato reale | medio | integra solo in zone chiave | media | utile, ma non safety-critical |
| energia rete | SDM120 Modbus validato + legacy Tuya | dual path transitorio | alto | tieni SDM120, declassa Tuya | alta | Modbus e` target piu` robusto |
| energia FV | SolarEdge + forecast | feed esterno | medio | tieni, aggiungi qualita` feed | media | buono per policy, non safety |
| energia carichi HVAC | heating/ACS presenti, AC/VMC gap | metering incompleto | alto | integra metering dedicato | alta | serve feedback reale attuatori |
| idronica MIRAI | Modbus parziale | runtime truth non chiusa | alto | consolida prima di attuare | alta | necessario per PDC/load dispatch |
| ACS/EHW sonde | Modbus validato | complessita` mapping/readiness | alto | tieni e governa | alta | buon segnale BMS |
| batterie sensori | varie | manutenzione e drift | alto cumulativo | riduzione progressiva | alta | TCO e affidabilita` peggiorano |

FACT  
I sensori T/RH attuali sono sufficienti per un sistema funzionante, ma non per un BMS robusto a lungo termine.

IPOTESI (confidenza alta)  
Il primo collo di bottiglia sensoriale non e` precisione assoluta, ma disponibilita`, alimentazione, latenza e ownership del dato.

DECISIONE  
I segnali da portare fuori da batteria/cloud prima degli altri sono: bagno T/RH, T/RH esterna, CO2 giorno/notte, finestre aggregate, metering AC/VMC.

## SEZIONE 5 - PIANO DI SOSTITUZIONE SENSORI

| fase | obiettivo | cosa sostituire | cosa mettere al posto | protocollo consigliato | motivazione | beneficio atteso | costo relativo | complessita` | priorita` |
|---|---|---|---|---|---|---|---|---|---|
| Fase 0 | razionalizzare senza acquisti | niente | classificazione sensori + SOT fisico | software | separare fisico/logico | chiarezza, meno conflitti | basso | bassa | immediata |
| Fase 0 | pulire authority | writer AC/VMC/heating ambigui | single-writer dichiarato | HA/SOT | ridurre conflitti | meno attuazioni incoerenti | basso | media | immediata |
| Fase 0 | qualificare dati | sensori legacy/fallback | health score per sensore | HA template/observability | rilevare stale/drift | diagnosi migliore | basso | bassa | immediata |
| Fase 1 | rendere VMC IAQ-grade | assenza CO2 | CO2 giorno + notte | PoE o cablato/ESPHome alimentato; RS485 se adatto | VMC basata su aria reale | controllo VMC migliore | medio | media | breve |
| Fase 1 | chiudere feedback finestre | input_boolean finestre | contatti reali su zone aggregate | cablato DI/RS485 se possibile; wireless solo dove impossibile | feedback reale aperture | blocchi AC/freecooling affidabili | medio | media | breve |
| Fase 1 | stabilizzare bagno | Tuya T/RH bagno | T/RH alimentato | RS485/1-Wire/ESPHome cablato/PoE | boost VMC dipende dal bagno | VMC piu` stabile | basso-medio | media | breve |
| Fase 1 | feedback energia attuatori | gap AC/VMC | metering AC giorno/notte/VMC | DIN Modbus/RS485 o Ethernet/PoE meter | verificare stato reale | kWh e fault detection | medio | media | breve |
| Fase 2 | consolidare clima ambiente | SwitchBot/Tuya T/RH | sensori room alimentati | PoE/ESPHome cablato o RS485 room sensors | ridurre batterie/cloud | meno manutenzione | medio | media-alta | medio termine |
| Fase 2 | fieldbus stabile | bus MIRAI/SDM120 condiviso | documentazione topologia, terminazioni, protezioni | RS485 Modbus TCP gateway industriale | ridurre errori bus | Modbus piu` robusto | medio | media | medio termine |
| Fase 2 | idronica decision-grade | MIRAI parziale | validazione RUN + mandata/ritorno affidabili | Modbus/sonde cablate | heating diagnosticabile | controllo piu` difendibile | medio | media | medio termine |
| Fase 3 | presenza robusta | assente/non usata | presenza per zone chiave | PoE/mmWave cablato dove sensato | affinare comfort | migliore tradeoff comfort/energia | medio-alto | media | backlog |
| Fase 3 | IAQ avanzata | solo CO2 | PM/VOC selettivi | PoE/cablato | diagnosi aria | insight, non controllo primario | medio-alto | media | backlog |
| Fase 3 | BMS premium | sensori consumer residui | moduli I/O DIN, sensori industriali | RS485/Modbus, DI, 0-10V | robustezza massima | manutenzione ridotta | alto | alta | backlog |

FACT  
Fase 0 non richiede sostituzioni.

IPOTESI (confidenza alta)  
La maggior parte del ROI tecnico arriva prima da CO2, contatti finestre reali, T/RH bagno/esterna e metering AC/VMC, non da sostituire ogni sensore esistente.

DECISIONE  
Fase 1 deve essere selettiva: pochi segnali ad alto impatto, nessun nuovo writer.

## SEZIONE 6 - PROPOSTA TARGET ARCHITECTURE

FACT  
La target architecture realistica 2026 deve mantenere Home Assistant/ClimateOps come brain, ma rendere il field layer meno consumer.

Cosa resta:
- Home Assistant come supervisore.
- ClimateOps, SOT `cm_*`, policy/contract/driver model.
- SDM120 Modbus come fonte canonica rete.
- SolarEdge come fonte FV.
- ACS/EHW Modbus, con writer governato.
- Dashboard diagnostiche e audit runtime.

Cosa va consolidato:
- AC single-writer.
- MIRAI runtime truth.
- Sensor registry fisico.
- Health score per sensori critici.
- Feedback reale attuatori tramite energia/stato.

Cosa va spostato su RS485:
- Metering DIN energia HVAC.
- Moduli ingressi digitali per finestre/porte se cablaggio possibile.
- Eventuali sensori T/RH tecnici in quadro/locale tecnico.
- Sonde idroniche o I/O HVAC dove compatibile.

Cosa puo` andare su PoE:
- CO2 giorno/notte.
- Sensori IAQ alimentati.
- Presenza evoluta se davvero utile.
- Gateway/bridge locali stabili.
- Piccoli nodi ESPHome cablati se la posa Ethernet e` piu` semplice del bus.

Cosa lasciare wireless:
- Segnali non critici.
- Stanze dove cablare costa troppo.
- Sensori temporanei di confronto/calibrazione.
- Advisory non usati per attuazione diretta.

Cosa centralizzare:
- Attuazione heating/VMC/ACS in quadro o locale tecnico.
- Ingressi finestra aggregati per zona.
- Metering HVAC.
- Naming e ownership.

Cosa non toccare ora:
- Logica ClimateOps gia` funzionante.
- Writer ACS validato, salvo consolidamento osservabilita`.
- SDM120 se continua stabile.
- Dashboard operative, salvo separare debug/operativo.

IPOTESI (confidenza media)  
Una dorsale ideale e`: HA + UPS + rete cablata + gateway RS485/Ethernet + moduli DIN + PoE per sensori IAQ/room, con wireless solo periferico.

DECISIONE  
Target non e` "tutto Modbus". Target e`: Modbus/RS485 per campo tecnico e quadro, PoE per sensori ambientali evoluti, wireless solo dove il dato non blocca il BMS.

## SEZIONE 7 - ROADMAP

1. Analisi  
   FACT: SOT logico esiste.  
   DECISIONE: creare SOT fisico sensori/attuatori con protocollo, alimentazione, criticita`, fallback, owner.

2. Consolidamento  
   FACT: AC single-writer e MIRAI truth sono aperti.  
   DECISIONE: chiudere prima questi due fronti, senza nuovi acquisti.

3. Sostituzione sensori  
   IPOTESI (confidenza alta): sostituire prima i segnali che guidano attuazione.  
   DECISIONE: priorita` a bagno T/RH, esterno T/RH, CO2 giorno/notte, finestre reali, metering AC/VMC.

4. Integrazione fieldbus  
   FACT: RS485/Modbus e` gia` operativo con SDM120/MIRAI.  
   DECISIONE: non espandere il bus a caso; prima progettare topologia, indirizzi, terminazioni, alimentazioni, separazione potenza/segnale.

5. Espansione futura  
   IPOTESI (confidenza media): presenza e IAQ avanzata daranno beneficio solo dopo avere dati base affidabili.  
   DECISIONE: presenza, VOC/PM e sensori premium restano backlog finche` i segnali base non sono stabili.

## SEZIONE 8 - DECISIONI FINALI

5 decisioni nette:
- DECISIONE: tenere Home Assistant + ClimateOps come cervello BMS.
- DECISIONE: classificare ogni sensore come `control-grade`, `advisory-grade` o `diagnostic-grade`.
- DECISIONE: sostituire prima sensori batteria/cloud che influenzano attuazione.
- DECISIONE: usare RS485/Modbus per quadro, energia, I/O e HVAC tecnico.
- DECISIONE: usare PoE/alimentato per CO2 e sensori ambiente critici.

5 errori da evitare:
- DECISIONE: non comprare sensori wireless in massa.
- DECISIONE: non aggiungere writer prima di chiudere single-writer authority.
- DECISIONE: non usare CO2/VOC/PM consumer cloud come base di controllo critico.
- DECISIONE: non espandere RS485 senza progetto bus.
- DECISIONE: non confondere stato logico HA con feedback fisico reale.

3 quick wins:
- FACT: SOT logico gia` presente.  
  DECISIONE: aggiungere inventario fisico sensori/attuatori.
- FACT: finestre oggi sono virtuali.  
  DECISIONE: separare chiaramente `manual/advisory` da `real contact`.
- FACT: SDM120 e` validato.  
  DECISIONE: promuoverlo come fonte rete primaria e declassare Tuya legacy a fallback temporaneo.

3 elementi da NON comprare ora:
- DECISIONE: non comprare sensori T/RH wireless aggiuntivi a batteria.
- DECISIONE: non comprare attuatori smart plug/cloud per carichi HVAC critici.
- DECISIONE: non comprare gateway o moduli RS485 prima di definire topologia, indirizzi, alimentazioni e quadro I/O.

## Prossimo deliverable consigliato

DECISIONE  
Creare un inventario fisico separato dei sensori/attuatori, non una modifica runtime:

| entity_id | zona | funzione | protocollo | alimentazione | criticita` BMS | stato dato | azione consigliata |
|---|---|---|---|---|---|---|---|

IPOTESI (confidenza alta)  
Questo inventario e` il prerequisito tecnico per scegliere sostituzioni sensate senza acquisti impulsivi.
