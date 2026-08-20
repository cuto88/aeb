# Mercurio — Energy Intelligence Roadmap

**Status:** design / direction document  
**Scope:** Home Assistant + SSOT Mercurio + n8n  
**Goal:** trasformare il monitoraggio energetico esistente in un sistema capace di misurare, spiegare e ridurre i consumi reali della casa.

## 1. Executive decision

Mercurio dispone già di una base energetica avanzata in Home Assistant: sotto-contatori, utility meter giornalieri/mensili, statistiche di potenza, produzione FV, quote per carico, KPI di comfort/cicli HVAC, VMC e analisi advisory dell'involucro.

Il gap principale non è aggiungere altri grafici o altri sensori. Il gap è costruire una catena di misura chiusa:

`contatore generale -> allocazione carichi -> contesto meteo/presenza -> baseline -> automazione -> risparmio verificato -> report mensile`

La metrica primaria deve diventare il **consumo elettrico netto reale della casa, riconciliato con il contatore/bolletta e confrontato con un baseline normalizzato**. Le metriche dei singoli dispositivi servono a spiegare il totale e a individuare le azioni.

## 2. Perché serve ora

Dal registro bollette SSOT, il confronto omogeneo febbraio-luglio mostra:

| Periodo | 2025 | 2026 | Delta |
| --- | ---: | ---: | ---: |
| feb-mar | 299 kWh | 514 kWh | +215 kWh |
| apr-mag | 167 kWh | 299 kWh | +132 kWh |
| giu-lug | 184 kWh | 247 kWh | +63 kWh |
| **Totale feb-lug** | **650 kWh** | **1.060 kWh** | **+410 kWh / +63%** |

Il gap mensile si sta riducendo, ma non esiste ancora una catena analitica sufficiente per attribuire il miglioramento recente alle automazioni HA oppure a meteo, presenza, abitudini o altri carichi.

**Conclusione:** non è possibile oggi dimostrare il ROI energetico delle automazioni in modo robusto.

## 3. Stato attuale verificato nel repository canonico

### 3.1 Metering e disaggregazione

`packages/energy_pm.yaml` contiene:

- utility meter giornalieri e mensili per Mirai, EHW, PM1, PM2, PM3;
- statistiche di potenza media 15 min e picco 24 h;
- monitoraggio cicli di lavatrice, asciugatrice e carichi dedicati;
- somma delle potenze dei misuratori locali;
- stima del consumo globale istantaneo come `PV + grid`;
- somma energetica giornaliera dei carichi locali;
- quota percentuale giornaliera dei singoli carichi.

Questa è già una buona base di **sub-metering operativo**.

### 3.2 Fotovoltaico

`packages/energy_pv_solaredge.yaml` normalizza:

- potenza FV istantanea;
- energia FV totale;
- produzione giornaliera, mensile e annuale;
- fallback di sorgente per la potenza.

### 3.3 VMC

`packages/energy_vmc_reallocation.yaml` fornisce:

- potenza media VMC a 15 min;
- potenza massima VMC 24 h;
- baseline storici legati alla riallocazione del misuratore PM1.

La parte energetica VMC è però ancora soprattutto descrittiva: manca un KPI che metta in relazione kWh, portata/velocità, qualità aria e beneficio termico.

### 3.4 ClimateOps

`packages/climateops_phase1_kpi.yaml` misura:

- percentuale di tempo nella comfort band;
- cicli riscaldamento;
- cicli AC;
- minuti di VMC boost.

Sono KPI utili per qualità del controllo, ma **non misurano direttamente l'efficienza energetica**.

### 3.5 Policy energetica

`packages/climate_policy_energy.yaml` dispone già dei concetti per:

- surplus FV;
- forecast FV;
- forecast temperatura esterna;
- prezzo energia;
- import/export rete;
- soglie di import elevato;
- policy fail-safe.

Quindi esiste già il layer per passare in futuro da analisi a ottimizzazione predittiva.

### 3.6 Involucro

`packages/envelope_efficiency_advisory.yaml` calcola, durante finestre di free-decay:

- drift termico interno;
- cooldown rate;
- perdita normalizzata su delta-T;
- retention score;
- solar utilization score;
- livello qualitativo di efficienza involucro.

È un'analisi interessante e avanzata, ma oggi rimane separata dal bilancio elettrico e dal consumo HVAC.

## 4. Limite della verifica attuale

Questa analisi è verificata sul **repository GitHub canonico**. `AGENTS.md` segnala esplicitamente un possibile drift tra package split nel repository e runtime Home Assistant, dovuto a patch chirurgiche applicate sul runtime monolitico.

Di conseguenza, prima di considerare qualsiasi KPI come operativo deve essere eseguito un **runtime audit read-only** per verificare:

1. entità effettivamente presenti;
2. entity_id correnti;
3. continuità delle long-term statistics;
4. sorgenti del pannello Energy;
5. utility meter realmente attivi;
6. data di inizio dello storico affidabile;
7. eventuali duplicazioni tra meter fisici e template.

Fino a quel gate, distinguere sempre:

- `REPO_VERIFIED`
- `RUNTIME_VERIFIED`
- `DATA_QUALITY_VERIFIED`

## 5. Architettura target

### Layer L0 — Truth meter

Obiettivo: una sola verità del consumo totale.

Entità canoniche target:

- `sensor.energy_grid_import_total_kwh`
- `sensor.energy_grid_export_total_kwh`
- `sensor.energy_pv_total_kwh`
- `sensor.energy_house_consumption_total_kwh`
- `sensor.energy_house_power_w`

Formula di controllo:

`house consumption ~= grid import + PV production - grid export`

Il risultato deve essere riconciliabile con le letture del distributore e con le bollette.

### Layer L1 — Load allocation

Gerarchia consigliata:

1. HVAC / Mirai
2. ACS / EHW
3. VMC
4. lavatrice
5. asciugatrice
6. IT / server / workstation
7. altri carichi misurati
8. **residuo non attribuito**

KPI principale:

`unattributed_energy_pct = 100 * residual_kWh / house_kWh`

**Target proposto:** attribuzione >= 80% iniziale, >= 90% a regime. Non aggiungere sotto-contatori se non riducono materialmente il residuo o abilitano una decisione.

### Layer L2 — Time aggregation

Per totale casa e principali carichi:

- 15 min;
- ora;
- giorno;
- mese;
- anno.

Il minuto serve al controllo; giorno/mese servono alla valutazione del risparmio.

### Layer L3 — Context normalization

Registrare insieme ai consumi:

- temperatura esterna media/min/max;
- HDD/CDD o degree-hours;
- umidità esterna;
- irradianza/produzione FV;
- casa occupata / ore-presenza;
- giorni fuori casa;
- comfort indoor;
- finestre aperte significative;
- modalità HVAC;
- eventuali eventi eccezionali.

Questo layer evita di chiamare "risparmio" una semplice differenza di clima o presenza.

### Layer L4 — KPI Energy Intelligence

#### Casa

- kWh/giorno;
- kWh/mese;
- kWh/m²;
- base load notturno W;
- picco massimo kW;
- ore sopra soglia di potenza;
- YoY kWh;
- YoY %;
- YoY normalizzato meteo/presenza;
- costo reale €/mese;
- residuo non attribuito %.

#### HVAC

- kWh/giorno e mese;
- kWh/HDD in riscaldamento;
- kWh/CDD in raffrescamento;
- kWh per ora in comfort;
- cicli/giorno;
- durata media ciclo;
- consumo standby;
- COP operativo solo quando l'energia termica utile è misurabile o stimabile con sufficiente qualità.

#### ACS

- kWh/giorno;
- kWh/persona-giorno;
- cicli/giorno;
- perdite standby stimate;
- quota coperta da surplus FV.

#### VMC

- kWh/giorno;
- Wh/m³ se la portata è disponibile/affidabile;
- kWh per modalità/velocità;
- minuti boost;
- relazione con CO2/UR/IAQ;
- costo energetico del boost;
- beneficio termico, solo dopo sensori temperatura/portata validati.

#### FV

- produzione kWh;
- autoconsumo %;
- autosufficienza %;
- export kWh;
- energia flessibile spostata su surplus;
- valore economico autoconsumato.

## 6. Baseline e misura del risparmio

### Baseline primaria

Usare 2025 come riferimento YoY dove i dati sono completi, ma non considerarlo automaticamente un baseline normalizzato.

Per ogni mese:

`delta_raw_kWh = kWh_current - kWh_baseline`

Successivamente introdurre:

`delta_normalized_kWh = actual - expected(weather, occupancy, season)`

### Metodo MVP

Per partire senza over-engineering:

1. confronto stesso mese anno precedente;
2. normalizzazione semplice HDD/CDD per HVAC;
3. correzione esplicita per giorni di assenza;
4. separazione dei principali carichi misurati;
5. residuo.

Solo dopo almeno 6-12 mesi di dati puliti valutare regressioni più sofisticate.

## 7. Misura del valore delle automazioni

Ogni automazione energetica deve avere una scheda esperimento minima:

- `automation_id`
- ipotesi;
- carico interessato;
- KPI primario;
- comfort/safety guardrail;
- baseline;
- data attivazione;
- periodo di osservazione;
- kWh evitati stimati;
- euro evitati;
- confidenza: LOW / MEDIUM / HIGH.

Esempio:

> Ridurre VMC da velocità 2 a 1 durante finestre IAQ-safe dovrebbe ridurre i kWh VMC senza superare le soglie di qualità aria.

Il KPI non è "automazione eseguita" ma `kWh evitati con guardrail rispettati`.

## 8. Reconciliation con bollette

Una volta al mese n8n deve confrontare:

- consumo HA del periodo;
- lettura/consumo fatturato;
- differenza assoluta kWh;
- errore percentuale.

KPI:

`meter_reconciliation_error_pct`

**Gate proposto:** <= 3% è verde; 3-5% da verificare; >5% blocca analisi ROI finché la causa non è spiegata.

Le bollette Dropbox e il tab `Bollette` della SSOT Mercurio diventano il riferimento indipendente di validazione, non la sorgente realtime.

## 9. Dashboard target

Creare una sola dashboard nuova: **Energy Intelligence**.

### View 1 — Executive

- oggi / mese / anno kWh;
- YoY raw e normalizzato;
- costo;
- produzione FV;
- autoconsumo;
- residuo non attribuito;
- reconciliation status;
- top 3 cause del consumo.

### View 2 — Loads

- stacked energy per principali carichi;
- residuo;
- base load;
- picchi;
- anomalie.

### View 3 — Climate efficiency

- HVAC kWh vs HDD/CDD;
- comfort band;
- cicli;
- envelope retention;
- finestre / free cooling / solar gain.

### View 4 — Automation ROI

Per automazione:

- stato;
- KPI target;
- baseline;
- delta kWh;
- delta euro;
- confidence;
- guardrail violation.

Nessun KPI deve essere aggiunto alla dashboard se non supporta una decisione.

## 10. Reporting automatico

n8n deve produrre un **Mercurio Energy Scorecard** mensile con massimo 10 righe utili:

1. kWh mese;
2. YoY raw;
3. YoY normalizzato;
4. costo;
5. base load;
6. top load;
7. residuo %;
8. PV/autoconsumo;
9. migliore automazione del mese;
10. anomalia/azione prioritaria.

Output: SSOT Mercurio + notifica sintetica. Evitare report manuali.

## 11. Roadmap di implementazione

### Fase 0 — Runtime truth audit

**Scopo:** sapere quali dati esistono realmente.

Deliverable:

- inventario energy entities runtime;
- mappa source -> canonical -> KPI;
- stato long-term statistics;
- data-quality matrix;
- sorgenti Energy Dashboard;
- elenco duplicati/reset/gap.

**Exit gate:** truth meter identificato e storico affidabile definito.

### Fase 1 — Whole-house truth + reconciliation

Implementare:

- entità canoniche casa import/export/PV/consumo;
- utility meter casa daily/monthly;
- reconciliation mensile con bolletta;
- errore %.

**Exit gate:** differenza HA vs bolletta <= 3% oppure differenza spiegata.

### Fase 2 — Allocation + residual

Implementare:

- gerarchia carichi;
- energia per carico;
- residuo;
- quota attribuita.

**Exit gate:** >=80% del consumo attribuito nei giorni normali.

### Fase 3 — Baseline YoY MVP

Implementare:

- monthly YoY;
- HDD/CDD;
- occupancy correction minima;
- baseline 2025;
- Energy Scorecard.

**Exit gate:** spiegazione quantitativa del delta mensile.

### Fase 4 — Automation ROI

Per ogni automazione energetica attiva:

- definire ipotesi;
- KPI;
- guardrail;
- periodo before/after o A/B quando possibile;
- stima kWh/€ evitati.

**Exit gate:** almeno 3 automazioni con beneficio o assenza di beneficio misurabile.

### Fase 5 — Predictive optimization

Solo dopo le fasi precedenti:

- forecast FV;
- prezzo;
- meteo;
- pre-heating/pre-cooling;
- ACS su surplus;
- peak shaving;
- load shifting.

Questo layer deve ottimizzare su dati validati, non compensare lacune di misura.

## 12. MVP operativo consigliato

Il primo MVP deve stare in poche ore di lavoro e **non richiede nuovi sensori**:

1. identificare il truth meter generale e validare lo storico;
2. creare `house_energy_daily/monthly` + residual;
3. creare confronto YoY mensile 2025/2026;
4. aggiungere HDD/CDD;
5. produrre una scorecard n8n mensile.

Solo dopo questo MVP decidere quali nuovi misuratori fisici hanno ROI.

## 13. Target proposti

Questi sono target di progetto, non valori attuali verificati:

| KPI | Target iniziale |
| --- | ---: |
| Meter reconciliation error | <= 3% |
| Energia attribuita ai carichi | >= 80% |
| Unattributed energy | <= 20% |
| Dati energy disponibili | >= 99% |
| Automazioni con KPI esplicito | 100% delle automazioni energetiche nuove |
| Report manuale | 0 |
| Tempo review mensile | <= 10 min |

Il target di riduzione kWh non va fissato prima della normalizzazione del baseline. Dopo 2-3 mesi di dati puliti si potrà definire un obiettivo realistico, ad esempio percentuale annua di riduzione normalizzata.

## 14. Pre-mortem operativo

| Failure mode | Segnale precoce | Contromisura minima |
| --- | --- | --- |
| Doppio conteggio carichi | somma sub-meter > totale casa | gerarchia meter + residual, mai sommare rami sovrapposti |
| HA e bolletta divergono | errore >5% | reconciliation mensile e blocco ROI |
| Storico spezzato da rename/reset | salti nei total_increasing | registry canonico + audit long-term statistics |
| Meteo scambiato per risparmio | YoY cambia con HDD/CDD | normalizzazione clima |
| Presenza scambiata per risparmio | consumi bassi durante assenze | occupancy-days nel baseline |
| Dashboard theatre | KPI senza decisione | ogni KPI deve avere owner/threshold/action |
| Load shifting scambiato per saving | costo cala ma kWh no | kWh totale primario, costo secondario |
| Comfort sacrificato per risparmio | comfort band peggiora | comfort e IAQ come guardrail |
| Over-engineering | settimane senza scorecard | MVP Fasi 0-3 prima di ML/predittivo |

## 15. Decisione architetturale

**Direzione scelta:** Home Assistant rimane il motore realtime e di controllo; il repository `aeb` rimane la SSOT della logica; SSOT Mercurio contiene i dati economici/bollette; n8n esegue reconciliation, reporting e orchestrazione fuori dal realtime.

Separazione delle responsabilità:

- **HA:** misura, aggregazione breve, stato, automazione, guardrail;
- **GitHub/aeb:** schema canonico, package, governance, versionamento;
- **SSOT Mercurio:** bollette, baseline economico, serie consolidate;
- **n8n:** ETL, confronto periodi, reconciliation, scorecard, alert;
- **Dropbox:** archivio documentale delle fatture.

## 16. Next action canonica

**Prossima azione:** eseguire Fase 0 — `Energy Runtime Truth Audit` in modalità read-only.

Non modificare ancora policy, automazioni o dashboard. Prima produrre la matrice:

`entity -> physical meter -> load -> unit -> state_class -> history start -> daily/monthly aggregation -> overlap -> confidence`

Da quella matrice derivano senza ambiguità le implementazioni Fase 1-3.
