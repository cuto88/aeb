# Ownership delle card Home Assistant

Data censimento: 2026-07-19
Ambito: 12 dashboard operative registrate in `configuration.yaml` dopo la Tranche 2A.
Metodo: censimento statico di tutte le viste, sezioni e card top-level. Le card omogenee della stessa sezione sono raggruppate nella stessa riga, ma ogni card e` nominata. Le heading sono rappresentate dal nome della sezione e non costituiscono contenuto autonomo.

Copertura verificata: 12 dashboard, 18 viste, 92 sezioni e 310 card top-level. Le card annidate nei grid sono censite tramite il nome funzionale del grid e l'elenco dei contenuti riportato nella stessa riga.

## Legenda

- Ruolo: `overview`, `domain`, `observability`, `fieldbus`.
- Tipo: `state`, `command`, `trend`, `tuning`, `diagnostic`, `raw`.
- Frequenza: `daily`, `weekly`, `incident`.
- Decisione: `keep`, `move`, `merge`, `remove` per la futura Tranche 2B; questo documento non applica spostamenti.

## 1 ECLSS Casa

| Vista | Sezione | Card censite | Owner | Ruolo | Tipo | Frequenza | Decisione | Target | Motivazione |
|---|---|---|---|---|---|---|---|---|---|
| ECLSS | Stato generale | griglia priorita`/readiness; Diagnosi rapida | Cross-domain / Observability | overview | state/diagnostic | daily | merge | ECLSS + Observability | Tenere sintesi; spostare il dettaglio failsafe/lock |
| ECLSS | Stato generale | Apri dominio | Cross-domain | overview | command | daily | keep | ECLSS | Navigazione canonica |
| ECLSS | KPI ambientali | T interna media; UR interna media; T esterna; UR esterna; Delta T; Delta AH | Clima casa | overview | state | daily | keep | ECLSS | Sintesi ambientale cross-domain |
| ECLSS | KPI ambientali | Temperature 12h; Confronto UR 24h | Clima casa | overview | trend | weekly | merge | Air Loop | Nell'overview basta un trend sintetico |
| ECLSS | Zona giorno | T giorno; UR giorno; AC giorno; Finestra giorno1; Finestra giorno2; Portoncino | Clima giorno | overview | state/command | daily | merge | Air Loop / Cooling | Ridurre a stato zona sintetico |
| ECLSS | Zona notte | T notte media; UR notte media; AC notte; Finestra notte1/2/3 | Clima notte | overview | state/command | daily | merge | Air Loop / Cooling | Ridurre a stato zona sintetico |
| ECLSS | Bagno e boost | T bagno; UR bagno; Finestra bagno; Boost manuale; Boost auto; ETA boost | Ventilation | overview | state/command | daily | merge | Air Loop | Tenere boost sintetico; dettaglio nel dominio |
| ECLSS | VMC | Modalita`; Manuale; Vel target; Vel attuale; Freecooling attivo/stato; Reason | Ventilation | overview | state/command | daily | merge | Air Loop | Tenere modo, attuazione e reason |
| ECLSS | AC | card entities AC | Cooling | overview | state/command | daily | merge | Cooling | Tenere stato/attuazione/reason, non diagnostica |
| ECLSS | Heating | card entities Heating | Heating | overview | state/command | daily | merge | Heating | Tenere stato/attuazione/reason, non lock dettagliati |
| ECLSS | DHW / EHW | Stato rapido | DHW | overview | state/diagnostic | daily | merge | DHW / Observability | Tenere stato macchina; readiness dettagliata altrove |
| ECLSS | Timeline decisioni | VMC 12h; AC 12h; Heating 12h | Cross-domain | overview | trend | weekly | keep | ECLSS | Timeline comparativa cross-domain |
| ClimateOps | Stato rapido | Vacation; System mode/reason; Actuators ready; stagione; request heat/cool | ClimateOps | overview | state/diagnostic | daily | merge | ClimateOps / Observability | Readiness completa appartiene a Observability |
| ClimateOps | Ramo AC | Power posture; Runtime | Cooling/ClimateOps | domain | state/diagnostic | weekly | merge | Cooling | Dettaglio branch nel dominio |
| ClimateOps | Ramo MIRAI | Power posture; Runtime | MIRAI/ClimateOps | domain | state/diagnostic | weekly | merge | MIRAI | Dettaglio branch nella macchina |
| ClimateOps | Contratti | entities | Observability | observability | diagnostic | incident | move | Observability | Ownership esplicita dei contratti |
| ClimateOps | Timeline | System 12h; Branch posture 12h | ClimateOps | overview | trend | weekly | keep | ClimateOps | Correlazione orchestratore |
| AEB | Stato rapido | Vacation; Forecast ready/reason; Shift load; AEB MVP | AEB | overview | state | daily | keep | AEB | Sintesi policy |
| AEB | Forecast & policy | Forecast runtime; Policy contracts | AEB/Observability | domain | diagnostic | weekly | merge | Power Runtime / Observability | Runtime energia nel dominio, readiness in Observability |
| AEB | Planner & AEB | Planner dry-run; AEB MVP DHW | AEB/DHW | domain | tuning/diagnostic | weekly | move | Power Runtime / DHW | Non e` overview quotidiana |
| AEB | Trend | Forecast and grid 24h; Planner and AEB 24h | AEB | domain | trend | weekly | move | Power Runtime | Ownership energia/ottimizzazione |
| Passive House | Sintesi operativa | griglia guida; Scuri; AC; Scuri attivi; vantaggio umidita`; ETA apertura/chiusura; Inputs; markdown | Envelope | domain | state/diagnostic | daily | merge | Envelope | Tenere solo segnale e azione sintetici |
| Passive House | Rischio e azione | Stanza peggiore; Rischio; Scuri consigliati; Candidabili; Stanze schermate | Envelope | domain | state | daily | move | Envelope | Duplicazione diretta della dashboard Envelope |
| Passive House | Rischio e azione | Apri 10 Involucro | Cross-domain | overview | command | daily | keep | Passive House | Accesso al dettaglio |
| Passive House | Trend | Involucro 24h; Solare e scuri 24h | Envelope | domain | trend | weekly | move | Envelope | Trend di building physics |

## 2 Air Loop

| Vista | Sezione | Card censite | Owner | Ruolo | Tipo | Frequenza | Decisione | Target | Motivazione |
|---|---|---|---|---|---|---|---|---|---|
| 2 Air Loop | Runtime VMC | entities runtime | Ventilation | domain | state/diagnostic | daily | keep | Air Loop | Stato semantico del dominio |
| 2 Air Loop | Zona giorno | T; UR; Finestra giorno1/2 | Ventilation | domain | state/command | daily | keep | Air Loop | Input e comandi del dominio |
| 2 Air Loop | Zona notte | T/UR camera1/2; finestre camera1/2; camera3/finestra | Ventilation | domain | state/command | daily | keep | Air Loop | Input e comandi del dominio |
| 2 Air Loop | Bagno | T; UR; soglia boost ON/OFF; Boost manuale | Ventilation | domain | state/tuning/command | weekly | keep | Air Loop | Tuning specifico del boost |
| 2 Air Loop | VMC Velocita` | Vel 0/1/2/3; target; indice; T interna; T esterna | Ventilation | domain | state/command | daily | keep | Air Loop | Attuazione VMC |
| 2 Air Loop | VMC Velocita` | Velocita` target 24h | Ventilation | domain | trend | weekly | keep | Air Loop | Trend attuazione |
| 2 Air Loop | Freecooling | Delta T; Delta AH; attivo; candidabile; stato; finestre consigliate | Ventilation | domain | state | daily | keep | Air Loop | Decisione freecooling |
| 2 Air Loop | Logica & trigger | entities; markdown | Ventilation | domain | diagnostic | weekly | merge | Air Loop + docs logic | Rimuovere soglie narrative duplicate, non la spiegazione |

## 3 Heating Loop

| Vista | Sezione | Card censite | Owner | Ruolo | Tipo | Frequenza | Decisione | Target | Motivazione |
|---|---|---|---|---|---|---|---|---|---|
| Heating | Runtime | griglia stato; entities | Heating | domain | state/command | daily | keep | Heating | Stato e controllo principali |
| Heating | Setpoint e comandi | entities; Zone incluse | Heating | domain | tuning/command | weekly | keep | Heating | Tuning autorizzato del dominio |
| Heating | Grafici | Temperature 12h; Errori setpoint 7 giorni | Heating | domain | trend | weekly | keep | Heating | Trend specifici del dominio |
| Heating | Runtime e cicli | entities | Heating | domain | diagnostic | weekly | keep | Heating | KPI operativi del dominio |
| Heating | Timeline decisioni | history graph | Heating | domain | trend | weekly | keep | Heating | Explainability storica |

## 4 Cooling Loop

| Vista | Sezione | Card censite | Owner | Ruolo | Tipo | Frequenza | Decisione | Target | Motivazione |
|---|---|---|---|---|---|---|---|---|---|
| Cooling | Zona giorno | griglia stato; entities | Cooling | domain | state/command | daily | keep | Cooling | Stato e controllo zona |
| Cooling | Zona notte | griglia stato; entities | Cooling | domain | state/command | daily | keep | Cooling | Stato e controllo zona |
| Cooling | Andamento giorno | Richiesta/split; Clima zona giorno | Cooling | domain | trend | weekly | keep | Cooling | Trend zona |
| Cooling | Andamento notte | Richiesta/split; Clima zona notte | Cooling | domain | trend | weekly | keep | Cooling | Trend zona |
| Cooling | Decisione e attuazione | Catena decisionale | Cooling | domain | diagnostic | daily | keep | Cooling | Explainability operativa |
| Cooling | Pausa e protezioni | entities | Cooling | domain | command/diagnostic | daily | keep | Cooling | Protezioni specifiche |
| Cooling | Parametri comfort | Valori correnti; Apri modifica parametri | Cooling | domain | tuning/command | weekly | keep | Cooling | Tuning separato correttamente |
| Cooling | Istruzioni e note | Come funziona; Quando parte/ferma; Comandi/target/protezioni | Cooling | domain | diagnostic | weekly | merge | docs logic AC | Evitare soglie numeriche duplicate nella UI |
| Parametri AC | Modifica parametri | markdown; entities | Cooling | domain | tuning | weekly | keep | Parametri AC | Vista dedicata al tuning |

## 5 PV Array

| Vista | Sezione | Card censite | Owner | Ruolo | Tipo | Frequenza | Decisione | Target | Motivazione |
|---|---|---|---|---|---|---|---|---|---|
| PV Array | Stato attuale | Potenza istantanea; Stato | PV | domain | state | daily | keep | PV Array | Stato fonte energetica |
| PV Array | Energia | Produzione; Produzione giornaliera 7 giorni | PV | domain | state/trend | weekly | keep | PV Array | KPI fonte |
| PV Array | Trend 24h | Potenza FV 24h | PV | domain | trend | weekly | keep | PV Array | Trend fonte |

## 6 Power Runtime

| Vista | Sezione | Card censite | Owner | Ruolo | Tipo | Frequenza | Decisione | Target | Motivazione |
|---|---|---|---|---|---|---|---|---|---|
| Power Runtime | Runtime energia | Ruolo plancia; Approfondimenti | Energy | domain | diagnostic/command | daily | keep | Power Runtime | Contesto e navigazione |
| Power Runtime | Runtime energia | Quote oggi; Potenze istantanee | Energy | domain | state | daily | keep | Power Runtime | Sintesi consumi |
| Power Runtime | Consumi oggi | kWh/giorno | Energy | domain | state | daily | keep | Power Runtime | KPI giornaliero |
| Power Runtime | Contatori cumulati | Prelevata cumulata | Energy | domain | state | weekly | keep | Power Runtime | KPI cumulato |
| Power Runtime | Trend e KPI | Potenze 24h; KPI AEB 24h; Consumi 7 giorni | Energy/AEB | domain | trend | weekly | keep | Power Runtime | Ownership energia e ottimizzazione |

## 7 DHW / ACS

| Vista | Sezione | Card censite | Owner | Ruolo | Tipo | Frequenza | Decisione | Target | Motivazione |
|---|---|---|---|---|---|---|---|---|---|
| DHW | Runtime | Stato operativo; Ultimo aggiornamento | DHW | domain | state/diagnostic | daily | keep | DHW | Stato macchina semantico |
| DHW | Runtime | Apri Fieldbus EHW | DHW | domain | command | incident | keep | DHW | Navigazione raw |
| DHW | Active policy | AEB MVP DHW; Writer boundary | DHW/AEB | domain | state/tuning/diagnostic | weekly | keep | DHW | Policy e writer appartengono alla macchina |
| DHW | Active policy | Policy/writer 24h; Docce proxy 7 giorni | DHW | domain | trend | weekly | keep | DHW | Trend semantico |
| DHW | Diagnostica | Ruolo plancia; Note | DHW | domain | diagnostic | incident | keep | DHW | Contesto operatore |
| DHW | Diagnostica | Sonde semantiche | DHW | domain | state | daily | keep | DHW | Valori macchina interpretati |
| DHW | Diagnostica | Temperature e consumi 24h | DHW | domain | trend | weekly | keep | DHW | Trend semantico |

## 8 MIRAI Plant

| Vista | Sezione | Card censite | Owner | Ruolo | Tipo | Frequenza | Decisione | Target | Motivazione |
|---|---|---|---|---|---|---|---|---|---|
| MIRAI | Runtime macchina | Ruolo plancia; Apri Fieldbus | MIRAI | domain | diagnostic/command | daily | keep | MIRAI | Contesto e navigazione |
| MIRAI | Runtime macchina | Stato macchina; Corroborazione | MIRAI | domain | state/diagnostic | daily | keep | MIRAI | Stato semantico e conferme |
| MIRAI | Diagnostica | Diagnostica rapida | MIRAI/Observability | observability | diagnostic | incident | merge | Observability | Tenere solo fault sintetico nella macchina |
| MIRAI | Diagnostica | Runtime truth closure | MIRAI | domain | diagnostic | weekly | keep | MIRAI | Validazione semantica macchina |
| MIRAI | History 24h | history graph | MIRAI | domain | trend | weekly | keep | MIRAI | Trend macchina |

## 9 Fieldbus

| Vista | Sezione | Card censite | Owner | Ruolo | Tipo | Frequenza | Decisione | Target | Motivazione |
|---|---|---|---|---|---|---|---|---|---|
| SDM120 raw | Bus health | Ruolo; SSOT energia; Misure raw; Contatori | SDM120 | fieldbus | raw/diagnostic | incident | keep | Fieldbus | Ownership canonica raw |
| SDM120 raw | History | Trend elettrici; Energia 7 giorni | SDM120 | fieldbus | trend | incident | keep | Fieldbus | Evidenza bus |
| MIRAI raw | Bus health | Ruolo; Link e postura; Raw e registri effettivi; Probe e raw candidati | MIRAI fieldbus | fieldbus | raw/diagnostic | incident | keep | Fieldbus | Ownership canonica raw, consolidata in Tranche 2B.1 |
| MIRAI raw | Diagnostica | Snapshot operativo | MIRAI fieldbus | fieldbus | raw/diagnostic | incident | keep | Fieldbus | Evidenza snapshot |
| MIRAI raw | History | history graph | MIRAI fieldbus | fieldbus | trend | incident | keep | Fieldbus | Evidenza bus |
| EHW raw | Bus health | Ruolo; Readiness e mapping; Ultimo aggiornamento | EHW fieldbus | fieldbus | raw/diagnostic | incident | keep | Fieldbus | Ownership canonica raw |
| EHW raw | Debug | Raw registers; Vendor reg diagnostici; Sonde semantiche; Temperature 24h | EHW fieldbus | fieldbus | raw/trend | incident | keep | Fieldbus | Forensic EHW consolidato in Tranche 2B.1 |

## 10 Envelope

| Vista | Sezione | Card censite | Owner | Ruolo | Tipo | Frequenza | Decisione | Target | Motivazione |
|---|---|---|---|---|---|---|---|---|---|
| Envelope | Sintesi | griglia guida; Guadagno passivo; AC giustificata; stanza/rischio; scuri; candidabili | Envelope | domain | state | daily | keep | Envelope | Sintesi building physics |
| Envelope | Contesto | Finestra esterna; tempo; rimbalzo; scuri attivi; stanze schermate; stanze | Envelope | domain | state | daily | keep | Envelope | Contesto decisionale |
| Envelope | Notifiche | Consensi; markdown | Envelope | domain | command/diagnostic | weekly | keep | Envelope | Controllo notifiche specifiche |
| Envelope | Finestre manuale | Stato e comandi | Envelope | domain | command/state | daily | keep | Envelope | Attuazione manuale |
| Envelope | Trend | Temperature; Dinamica | Envelope | domain | trend | weekly | keep | Envelope | Trend building physics |
| Envelope | Zone | Giorno; Notte1; Notte2; Bagno | Envelope | domain | state/diagnostic | weekly | keep | Envelope | Modello stanza dettagliato |

## 11 Observability

| Vista | Sezione | Card censite | Owner | Ruolo | Tipo | Frequenza | Decisione | Target | Motivazione |
|---|---|---|---|---|---|---|---|---|---|
| Observability | Runtime health | MIRAI; EHW; VMC; AC; Heat; T_out; truth/envelope/solar inputs | Platform observability | observability | diagnostic | incident | keep | Observability | Health board canonico |
| Observability | Runtime health | Apri dominio | Platform observability | observability | command | incident | keep | Observability | Navigazione di remediation |
| Observability | Contracts | State; Reasons | ClimateOps | observability | diagnostic | incident | keep | Observability | Ownership contratti |
| Observability | Notifications | Canali attivi; markdown | Platform observability | observability | command/diagnostic | weekly | keep | Observability | Stato canali |
| Observability | Sensor hygiene | Outdoor fallback; Policy/KPI inputs; Bathroom T/RH; markdown | Sensor platform | observability | diagnostic/raw | incident | keep | Observability | Igiene e provenienza sensori |
| Observability | Unavailable/unknown | Critical runtime; Battery/radio missing; Known gaps | Platform observability | observability | diagnostic | incident | keep | Observability | Gap espliciti |
| Observability | Battery/radio risk | Battery telemetry; Wireless dependency map; markdown | Sensor platform | observability | diagnostic | incident | keep | Observability | Rischio telemetria |
| Observability | Proxy vs physical | Driver truth | Actuator platform | observability | diagnostic | incident | keep | Observability | Verita` attuatori |
| Observability | Climate diagnostics | Heating Diagnostica; Heating Debug | Heating | observability | diagnostic/raw | incident | keep | Observability | Diagnostica clima rimossa dal drill-down operativo |
| Observability | Energy diagnostics | PV Debug sensori; Host locale ds-01 | PV / Platform | observability | diagnostic/raw | incident | keep | Observability | Provenienza energia e health host |
| Observability | Domestic diagnostics | Sorgenti effettive; Entita` candidate grezze | Domestic Ops / Sensor platform | observability | diagnostic/raw | incident | keep | Observability | Mapping e sorgenti domestiche grezze |
| Observability | Legacy mappings | Heating Termostati reali TEMP; Heating Legacy TEMP/remap | Heating legacy diagnostics | observability | diagnostic/raw/tuning | incident | keep | Observability | Evidenza e mapping legacy non operativi |

## 12 Domestic Ops

| Vista | Sezione | Card censite | Owner | Ruolo | Tipo | Frequenza | Decisione | Target | Motivazione |
|---|---|---|---|---|---|---|---|---|---|
| Domestic Ops | Plancia attiva | Versione | Domestic Ops | domain | diagnostic | incident | keep | Domestic Ops | Identifica versione/cache |
| Domestic Ops | Stato rapido | Modulo; notifiche; slot; pausa pranzo; running; stesura/rientro | Domestic Ops | domain | state/command | daily | keep | Domestic Ops | Stato operativo |
| Domestic Ops | Stato rapido | Energia | Domestic Ops | domain | command | daily | keep | Domestic Ops | Navigazione energia |
| Domestic Ops | Motore decisionale | Consigli attivi; Contesto meteo/FV | Domestic Ops | domain | state/diagnostic | daily | keep | Domestic Ops | Decision support |
| Domestic Ops | Bucato appena finito | Asciugatura adesso; Come leggerlo | Domestic Ops | domain | state/diagnostic | daily | keep | Domestic Ops | Workflow operativo |
| Domestic Ops | Elettrodomestici | Lavastoviglie/lavatrice/asciugatrice; Routine operativa | Domestic Ops | domain | state/diagnostic | daily | keep | Domestic Ops | Workflow operativo |
| Domestic Ops | Programmi consigliati | Lavatrice/asciugatrice; Base manuali | Domestic Ops | domain | state/diagnostic | weekly | keep | Domestic Ops | Raccomandazioni |
| Domestic Ops | Casa Mercurio | Carichi reali; Detersivi e dosi | Domestic Ops | domain | state | weekly | keep | Domestic Ops | Contesto domestico |
| Domestic Ops | Helper e soglie | Abilitazioni; Soglie energia e drying | Domestic Ops | domain | tuning/command | weekly | keep | Domestic Ops | Tuning del dominio |
| Domestic Ops | Storico | DomesticOps 24h; Contesto 24h; Cicli 7 giorni | Domestic Ops | domain | trend | weekly | keep | Domestic Ops | Trend dominio |
| Domestic Ops | Routine domestiche | Reminder schedulati; Script notifica | Domestic Ops | domain | command/diagnostic | weekly | keep | Domestic Ops | Routine specifiche |

## Candidati esatti per la Tranche 2B

Le voci 7-16 sono state implementate nella Tranche 2B.1 senza cambiare entity ID, template o navigation path. Le voci 1-6 restano candidate per tranche successive:

1. ECLSS / ClimateOps / `Contratti` / card `entities` -> Observability / Contracts.
2. ECLSS / AEB / `Planner & AEB` / `Planner dry-run` -> Power Runtime.
3. ECLSS / AEB / `Planner & AEB` / `AEB MVP DHW` -> DHW / Active policy.
4. ECLSS / AEB / `Trend` / `Forecast and grid 24h` e `Planner and AEB 24h` -> Power Runtime.
5. ECLSS / Passive House / `Rischio e azione` / `Stanza peggiore`, `Rischio`, `Scuri consigliati`, `Candidabili raffrescamento notturno`, `Stanze schermate` -> Envelope / Sintesi.
6. ECLSS / Passive House / `Trend` / `Involucro 24h`, `Solare e scuri 24h` -> Envelope / Trend.
7. `[DONE 2B.1]` Heating / `Termostati reali (TEMP)` / markdown -> Observability / Legacy mappings.
8. `[DONE 2B.1]` Heating / `Diagnostica` / entities -> Observability / Climate diagnostics.
9. `[DONE 2B.1]` Heating / `Debug` / entities -> Observability / Climate diagnostics.
10. `[DONE 2B.1]` Heating / `Legacy TEMP / remap` / entities -> Observability / Legacy mappings.
11. `[DONE 2B.1]` PV Array / `Debug sensori` / entities -> Observability / Energy diagnostics.
12. `[DONE 2B.1]` Power Runtime / `Runtime energia` / `Host locale ds-01` -> Observability / Energy diagnostics.
13. `[DONE 2B.1]` DHW / `Diagnostica` / `Raw registers` e `Vendor reg diagnostici` -> Fieldbus / EHW raw.
14. `[DONE 2B.1]` MIRAI / `Runtime macchina` / `Probe e raw candidati` -> Fieldbus / MIRAI raw.
15. `[DONE 2B.1]` MIRAI / `Diagnostica` / `Snapshot operativo` -> Fieldbus / MIRAI raw.
16. `[DONE 2B.1]` Domestic Ops / `Diagnostica e mapping` / `Sorgenti effettive` e `Entita candidate grezze` -> Observability / Domestic diagnostics.

Le card marcate `merge` richiedono invece una decisione contenutistica prima di essere cambiate; non sono ingressi automatici alla 2B.

## Provenienza operativa

- Macchina: workspace locale Windows `C:\2_OPS\aeb`.
- Runtime target: `mercurio-edge` / Home Assistant Docker, non contattato.
- Macchina legacy: non contattata.
- Accesso: filesystem locale.
- Deploy: no.
- Modifiche runtime: no.
- Commit/GitHub Actions: nessuno.
