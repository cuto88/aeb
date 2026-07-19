# Audit dashboard Home Assistant

Data audit: 2026-07-19
Ambito: repository locale `C:\2_OPS\aeb`
Metodo: analisi statica in sola lettura di `configuration.yaml`, file Lovelace e governance documentata. Il runtime Home Assistant non e` stato interrogato.

## Executive summary

Il repository conteneva 15 file Lovelace: 12 dashboard operative, 2 file legacy registrati ma nascosti e 1 dashboard storica non registrata. `configuration.yaml` registrava inoltre `0-lovelace`, il cui target `ui-lovelace.yaml` non esisteva. La tassonomia dichiarata da `STEP108` era sostanzialmente applicata, ma la documentazione di modulo presentava drift su ID, visibilita` e ruolo delle dashboard.

Le 12 dashboard correnti referenziavano 566 occorrenze-entita` e 131 entita` erano condivise da almeno due superfici. La maggior parte delle ripetizioni tra overview e drill-down e` intenzionale; le sovrapposizioni principali riguardano invece ECLSS/Envelope, ECLSS/Observability, MIRAI/Fieldbus ed EHW/Fieldbus.

## 1. Elenco completo dei file dashboard

| Stato al momento dell'audit | ID registrato | File | Sidebar | Viste | Entita` uniche |
|---|---|---|---:|---:|---:|
| target mancante | `0-lovelace` | `ui-lovelace.yaml` | no | - | - |
| operativa | `01-clima-casa` | `lovelace/01_eclss_casa.yaml` | si | 4 | 152 |
| operativa | `02-vmc` | `lovelace/02_air_loop.yaml` | si | 1 | 42 |
| operativa | `03-riscaldamento` | `lovelace/03_heating_loop.yaml` | si | 1 | 43 |
| operativa | `04-ac` | `lovelace/04_cooling_loop.yaml` | si | 2 | 42 |
| operativa | `05-fv-solaredge` | `lovelace/05_pv_array.yaml` | si | 1 | 9 |
| operativa | `06-consumi` | `lovelace/06_power_runtime.yaml` | si | 1 | 31 |
| operativa | `07-ehw-acs` | `lovelace/07_dhw_acs.yaml` | si | 1 | 40 |
| operativa | `08-mirai` | `lovelace/08_mirai_plant.yaml` | si | 1 | 38 |
| operativa | `09-modbus` | `lovelace/09_fieldbus.yaml` | si | 3 | 51 |
| operativa | `10-involucro` | `lovelace/10_envelope.yaml` | si | 1 | 61 |
| operativa | `11-observability` | `lovelace/11_observability.yaml` | si | 1 | 57 |
| operativa | `12-domestic-ops` | `lovelace/12_domestic_ops.yaml` | si | 1 | 47 |
| legacy archiviata dopo l'audit | - | `lovelace/_archive/legacy_dashboards/02_air_loop_legacy.yaml` | no | 1 | 25 |
| legacy archiviata dopo l'audit | - | `lovelace/_archive/legacy_dashboards/04_cooling_loop_legacy.yaml` | no | 1 | 36 |
| archivio non registrato | - | `lovelace/_archive/climateops_step7_plancia.yaml` | - | 3 | 40 |

La baseline storica dichiarata in `STEP87` non era presente nella working copy analizzata. Prima della tranche 1 e` stata quindi creata `lovelace/_baseline/2026-07-19_dashboard_pre_refactor/`.

## 2. Struttura dashboard, viste e sezioni/card

### 1 ECLSS Casa

- `climate_casa`: Stato generale; KPI ambientali; Zona giorno; Zona notte; Bagno e boost; VMC; AC; Heating; DHW/EHW; Timeline decisioni.
- `climateops`: Stato rapido; Ramo AC; Ramo MIRAI; Contratti; Timeline.
- `aeb`: Stato rapido; Forecast e policy; Planner e AEB; Trend.
- `passive-house`: guida operativa/scuri; sintesi stanza peggiore; trend involucro.

### 2 Air Loop

- `climate_vmc_v2`: Runtime VMC; Zona giorno; Zona notte; Bagno; velocita` VMC; Freecooling Passivhaus; Logica e trigger.

### 3 Heating Loop

- `heating`: Runtime; termostati reali TEMP; setpoint e comandi; diagnostica; grafici; runtime e cicli; debug; timeline; legacy TEMP/remap.

### 4 Cooling Loop

- `ac_v2`: Zona giorno; Zona notte; andamento giorno; andamento notte; decisione e attuazione; pause e protezioni; parametri comfort; istruzioni.
- `ac_parameters`: modifica dei parametri comfort.

### 5 PV Array

- `pv_solaredge`: Stato attuale; Energia; Trend 24h; Debug sensori.

### 6 Power Runtime

- `consumi`: Runtime energia; Consumi oggi; Contatori cumulati; Trend e KPI.

### 7 DHW / ACS

- `ehw`: Runtime; Active policy; Diagnostica.

### 8 MIRAI Plant

- `8-mirai`: Runtime macchina; Diagnostica; History 24h.

### 9 Fieldbus

- `modbus-sdm120`: Bus health; History 24h.
- `modbus-mirai`: Bus health; Diagnostica; History 24h.
- `modbus-ehw`: Bus health; Debug.

### 10 Envelope

- `involucro`: Sintesi; Contesto; Notifiche; Finestre manuali; Trend; Zone.

### 11 Observability

- `observability`: Runtime health; Contracts; Notifications; Sensor hygiene; Unavailable/unknown; Battery/radio risk; Proxy vs physical.

### 12 Domestic Ops

- `domestic_ops`: Plancia attiva; Stato rapido; Motore decisionale; Bucato appena finito; Elettrodomestici; Programmi; Casa Mercurio; Helper e soglie; Storico; Routine; Diagnostica e mapping.

### Superfici non operative

- Legacy VMC `vmc`: vecchio drill-down compatto a card classiche.
- Legacy AC `ac`: vecchio drill-down con stato, setpoint, KPI, runtime e debug.
- Step7 archivio: viste `executive`, `diagnostics`, `step7` per il precedente layer ClimateOps/AEB.

## 3. Funzione presunta di ogni dashboard

| Dashboard | Funzione ricostruita |
|---|---|
| ECLSS | overview operativa e accesso cross-domain; contiene anche ClimateOps, AEB e sintesi involucro |
| Air Loop | drill-down VMC e ventilazione naturale |
| Heating | drill-down riscaldamento, tuning e diagnostica |
| Cooling | drill-down raffrescamento e parametri comfort |
| PV Array | produzione FV e stato delle sorgenti |
| Power Runtime | sintesi energetica locale e KPI AEB |
| DHW/ACS | stato EHW, policy AEB, writer e diagnostica macchina |
| MIRAI Plant | stato macchina e runtime truth semantico |
| Fieldbus | registri raw, mapping e forensic bus |
| Envelope | building physics, ombreggiamento e night flush |
| Observability | fault board, readiness, contratti e igiene sensori |
| Domestic Ops | decisioni e routine domestiche |
| Legacy VMC/AC | rollback e confronto storico, non entrypoint |
| Step7 | evidenza storica della precedente plancia ClimateOps/AEB |

## 4. Entita` utilizzate per dashboard

Le famiglie sotto distinguono entita` operative, helper e segnali diagnostici; i numeri sono conteggi unici per file.

| Dashboard | Conteggio | Famiglie principali |
|---|---:|---|
| ECLSS | 152 | clima, VMC, AC, heating, EHW, MIRAI, forecast, planner, AEB, envelope |
| Air Loop | 42 | temperatura/UR, finestre, boost, velocita`, freecooling |
| Heating | 43 | domanda, lock, setpoint, zone, cicli, TEMP/LDR |
| Cooling | 42 | climate/switch AC, comfort request, dew point, lock, pausa e soglie |
| PV Array | 9 | potenza ed energia FV, sorgenti SolarEdge/LocalTuya |
| Power Runtime | 31 | rete, PM1/2/3, DS01, MIRAI, EHW, quote e consumi |
| DHW/ACS | 40 | setpoint, sonde, writer, mapping e registri vendor |
| MIRAI Plant | 38 | readiness, power, stato macchina, probe, raw e snapshot |
| Fieldbus | 51 | registri SDM120, MIRAI ed EHW |
| Envelope | 61 | rischio termico, scuri, night flush, finestre e trend |
| Observability | 57 | readiness, failsafe, contratti, missing entity, batterie e proxy |
| Domestic Ops | 47 | lavaggio, asciugatura, meteo, FV, soglie e reminder |

## 5. Entita` duplicate tra dashboard

Sono state rilevate 131 entita` condivise tra almeno due dashboard operative. Le sovrapposizioni principali sono:

| Coppia | Entita` comuni | Interpretazione |
|---|---:|---|
| ECLSS / Air Loop | 29 | overview e drill-down, ma finestre/KPI sono ripetuti in profondita` |
| ECLSS / Envelope | 27 | duplicazione rilevante della vista Passive House |
| ECLSS / Observability | 27 | readiness e diagnostica troppo presenti nell'overview |
| MIRAI Plant / Fieldbus | 21 | confine raw/semantico permeabile |
| Air Loop / Observability | 15 | sensori ambientali e switch VMC ripetuti |
| DHW/ACS / Fieldbus | 14 | registri e sonde raw duplicati |
| ECLSS / Cooling | 12 | principalmente overview/drill-down |
| Cooling / Observability | 12 | stato fisico e diagnostica ripetuti |
| ECLSS / Heating | 11 | principalmente overview/drill-down |
| ECLSS / DHW | 11 | AEB/writer duplicato |
| Air Loop / Envelope | 11 | finestre e temperature condivise |
| ECLSS / MIRAI | 10 | runtime truth duplicata |
| Envelope / Observability | 10 | consensi/notifiche e sensori ripetuti |

Entita` con maggiore diffusione:

- `sensor.t_in_bagno`, `sensor.t_in_giorno`: 6 dashboard.
- `sensor.t_in_notte1`, `sensor.t_in_notte2`, `sensor.t_out`: 5 dashboard.
- `binary_sensor.cm_modbus_ehw_ready`, `binary_sensor.cm_modbus_mirai_ready`, `sensor.ehw_setpoint`, `input_boolean.vent_finestra_notte3_aperta`: 4 dashboard.
- Temperature/UR di zona, switch AC/heating, readiness e notifiche: 3-4 dashboard.

La duplicazione e` accettabile quando l'overview espone un indicatore sintetico e il drill-down lo contestualizza. Non e` accettabile quando due superfici espongono lo stesso blocco raw, di tuning o forensic.

## 6. Blocchi/card duplicati o quasi duplicati

- ECLSS `Passive House` e Envelope raccontano entrambi guadagno passivo, rischio, scuri e night flush.
- MIRAI Plant `Probe e raw candidati`/`Diagnostica rapida` replica parte di Fieldbus MIRAI.
- DHW `Raw registers`/`Sonde semantiche` replica parte di Fieldbus EHW.
- ECLSS `Diagnosi rapida`/`Contratti` replica Observability `Runtime health`/`Contracts`.
- I blocchi VMC di ECLSS ripetono runtime, velocita` e freecooling di Air Loop.
- Il blocco AEB di ECLSS si sovrappone a DHW e alla dashboard Step7 archiviata.
- Badge e trend temperatura/UR ricorrono in ECLSS, Air Loop, Cooling, Heating, Envelope e Observability.
- Lo stato notifiche ricorre in Envelope, Observability e Domestic Ops.
- Le sorgenti PV raw/fallback ricorrono in PV Array e nella diagnostica Domestic Ops.

Non sono presenti template Lovelace esterni o `!include`: le card sono inline. Non risultano copie testuali complete governate da un template comune; la duplicazione e` prevalentemente semantica.

## 7. Navigation path e collegamenti mancanti

Path canonici rilevati:

- `/01-clima-casa/climate_casa`, `/01-clima-casa/climateops`, `/01-clima-casa/aeb`, `/01-clima-casa/passive-house`
- `/02-vmc/climate_vmc_v2`
- `/03-riscaldamento/heating`
- `/04-ac/ac_v2`, `/04-ac/ac_parameters`
- `/05-fv-solaredge/pv_solaredge`
- `/06-consumi/consumi`
- `/07-ehw-acs/ehw`
- `/08-mirai/8-mirai`
- `/09-modbus/modbus-sdm120`, `/09-modbus/modbus-mirai`, `/09-modbus/modbus-ehw`
- `/10-involucro/involucro`
- `/11-observability/observability`
- `/12-domestic-ops/domestic_ops`

Al momento dell'audit esistevano solo due navigazioni esplicite: Passive House verso Envelope e Cooling verso la propria vista parametri. Mancavano i link ECLSS-domini, Energy-PV/Fieldbus, macchina-Fieldbus, Observability-domini e Domestic Ops-energia. `0-lovelace` puntava inoltre al file inesistente `ui-lovelace.yaml`.

## 8. Elementi di debug nelle dashboard operative

- Heating: sezioni `Debug` e `Legacy TEMP / remap`.
- PV Array: `Debug sensori` con sorgenti raw/fallback.
- DHW: writer enable, dry-run, request, raw calc e registri vendor.
- MIRAI Plant: `mirai_debug_enable`, probe raw, registri U1 e snapshot.
- Fieldbus: raw/forensic per ruolo, incluso il toggle debug MIRAI.
- Envelope: `climate_debug_telegram`.
- Observability: canali debug/notifica, unavailable/unknown e gap noti.
- Domestic Ops: versione/cache marker, mapping ed entita` candidate grezze.
- ECLSS: contratti, missing entities, runtime truth MIRAI e writer/AEB.

Fieldbus e Observability sono sedi coerenti per questi contenuti. ECLSS, Heating, Envelope e Domestic Ops richiedono valutazione nella tranche 2, senza anticipare spostamenti in questa fase.

## 9. Violazioni delle regole documentate

- Solo Air Loop contiene i tre riferimenti richiesti da `docs/logic/core/regole_plancia.md` direttamente nella dashboard.
- Il pattern obbligatorio Stato/Comandi, KPI, Trend/Lock/Diagnostica non e` uniforme.
- Cooling duplica soglie numeriche in Markdown (`0,5 C`, `62%`, `58%`, dew point, 5 e 90 minuti).
- Air Loop descrive soglie numeriche fisse del freecooling (`24 C`, `20 C`).
- Heating conserva debug e remap legacy nella superficie operativa.
- ECLSS svolge contemporaneamente overview, tuning, diagnostica, AEB e building physics.
- La documentazione di Ventilation, Heating, AC e `README_struttura_sistemi.md` riportava ID e visibilita` sidebar obsoleti.
- `STEP108` dichiarava ruoli non concorrenti, mentre permanevano sovrapposizioni raw/semantiche.
- La baseline di rollback dichiarata da `STEP87` non era disponibile nella working copy.

## 10. Matrice KEEP / MERGE / MOVE / REMOVE

| Elemento | Decisione target | Nota |
|---|---|---|
| ECLSS `climate_casa` | KEEP | overview quotidiana |
| ECLSS `climateops` | KEEP | orchestrazione cross-domain |
| ECLSS `aeb` | KEEP, ridurre | solo sintesi AEB |
| ECLSS `passive-house` | MERGE | sintesi e accesso a Envelope |
| Air Loop | KEEP | drill-down VMC canonico |
| Heating | KEEP | drill-down canonico |
| Heating debug/remap | MOVE | Observability o vista tecnica |
| Cooling e parametri | KEEP | drill-down e tuning separato |
| PV Array | KEEP | fonte e produzione PV |
| PV raw fallback | MOVE | Observability/Fieldbus se forensic |
| Power Runtime | KEEP | sintesi energia |
| DHW/ACS | KEEP | stato macchina e policy |
| DHW raw registers | MOVE | Fieldbus EHW |
| MIRAI Plant | KEEP | stato macchina semantico |
| MIRAI raw/probe | MOVE | Fieldbus MIRAI |
| Fieldbus | KEEP | unica sede raw/forensic |
| Envelope | KEEP | unica sede building physics completa |
| Observability | KEEP | unica sede fault/readiness/debug |
| Domestic Ops | KEEP | dominio indipendente |
| registrazioni legacy | REMOVE | file conservati fuori dalla navigazione attiva |
| Step7 | KEEP in archivio | evidenza storica |
| `0-lovelace` orfana | REMOVE o restore | nessun file o ruolo corrente |

## 11. Architettura target proposta

1. Overview: ECLSS con stato, reason, attuazione, fault sintetici e navigazione.
2. Domini operativi: Air Loop, Heating, Cooling, Envelope, Domestic Ops.
3. Energia e macchine: PV, Power Runtime, DHW, MIRAI.
4. Tecnico: Fieldbus esclusivamente raw; Observability esclusivamente health, fault, readiness, debug e gap.
5. Storico: file legacy e Step7 non registrati.

Ownership: l'overview espone al massimo indicatori sintetici; il drill-down possiede stato semantico, comandi e trend; Observability possiede health e debug; Fieldbus possiede registri e mapping raw. Una stessa entita` puo` apparire in piu` livelli solo se cambia la funzione informativa.

## Esito Tranche 2B.1 - separazione raw, debug e diagnostica

La Tranche 2B.1 applica il perimetro `move` gia` approvato, senza cambiare registrazioni, viste o navigation path:

- Heating conserva runtime, comandi, trend e cicli; diagnostica, debug e mapping TEMP sono ora in Observability.
- PV Array conserva stato, produzione e trend; `Debug sensori` e` ora in Observability.
- Power Runtime conserva sintesi e KPI energia; `Host locale ds-01` e` ora in Observability.
- DHW conserva stato macchina, policy, sonde semantiche e trend; `Raw registers` e `Vendor reg diagnostici` sono ora in Fieldbus / `modbus-ehw`.
- MIRAI conserva stato macchina, corroborazione, runtime truth e trend; probe/raw e snapshot sono ora in Fieldbus / `modbus-mirai`.
- Domestic Ops conserva workflow, comandi, tuning e trend; sorgenti effettive e candidate grezze sono ora in Observability.
- Observability espone quattro sezioni esplicite: `Climate diagnostics`, `Energy diagnostics`, `Domestic diagnostics`, `Legacy mappings`.

I duplicati semantici preesistenti `Snapshot operativo` MIRAI e `Raw registers` EHW sono stati sostituiti dalle versioni complete provenienti dalle dashboard di dominio; non sono state create copie parallele.

Baseline dedicata: `lovelace/_baseline/2026-07-19_dashboard_tranche_2b1_pre_move/`.

## 12. File potenzialmente coinvolti

- `configuration.yaml`
- i file top-level sotto `lovelace/`
- `lovelace/_archive/climateops_step7_plancia.yaml` solo per gestione archivio
- `docs/logic/core/regole_plancia.md`
- `docs/logic/README_struttura_sistemi.md`
- `docs/logic/ventilation/plancia.md`
- `docs/logic/heating/plancia.md`
- `docs/logic/ac/plancia.md`
- documenti storici `STEP87`, `STEP92`, `STEP93`, `STEP108`
- `docs/architecture/ADR-HA-DASH-001.md`

## Provenienza operativa

- Macchina operativa: workspace locale Windows `C:\2_OPS\aeb`.
- Runtime target dichiarato dalla governance: `mercurio-edge`, Home Assistant Core in Docker, non verificato o toccato durante l'audit.
- Macchina legacy: non contattata.
- Accesso usato: filesystem locale in lettura.
- Deploy eseguito: no.
- Modifiche runtime: no.
- Commit o run GitHub Actions: nessuno.
