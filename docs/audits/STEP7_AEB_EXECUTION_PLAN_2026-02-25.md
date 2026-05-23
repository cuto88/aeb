# STEP7 AEB Execution Plan (2026-02-25)

Date: 2026-02-25  
Scope: piano esecutivo per chiudere il gap AEB dopo stabilizzazione runtime ClimateOps.

## Obiettivo
Portare il sistema da stato AEB `BASIC/PARTIAL` a uno stato verificabile con:
- forecast input affidabili,
- policy tariff/grid esplicita,
- gerarchia multi-carico formale,
- KPI AEB chiusi con evidenza runtime.

## Prerequisiti (FACT)
- Home Assistant core operativo (`2026.2.3` al 2026-02-25).
- Writer authority ClimateOps attiva (`automation.climateops_system_actuate`).
- Gate locali disponibili: `ops/validate.ps1`.

## Strategia di delivery
Implementazione incrementale in 4 micro-step, ciascuno con:
1. contratto entita`/helper,
2. logica runtime,
3. test locale + check runtime,
4. evidenza audit con `context_id` dove applicabile.

---

## Micro-step 7.1 - Forecast Input Contracts

### Obiettivo
Introdurre segnali forecast meteo/PV affidabili con fallback e diagnostica qualita` dati.

### File target
- `packages/climate_policy_energy.yaml`
- `packages/climate_contracts.yaml`
- `docs/logic/core/README_sensori_clima.md`

### Deliverable
- helper/input per forecast disponibili e soglie minime qualità dato;
- sensori `cm_*` forecast normalizzati;
- contract sensor: stato `ready/not_ready` + reason.

### Validazione
- `ops/validate.ps1` PASS
- `ha core check` PASS
- verifica runtime: sensori forecast non `unknown/unavailable` in finestra campione >= 30 min.

### Rollback
- disattivare uso forecast nei template policy (fallback deterministico su dati attuali);
- ripristino commit precedente.

---

## Micro-step 7.2 - Tariff/Grid Policy

### Obiettivo
Aggiungere policy esplicita su prezzo/fascia rete e import/export per decisioni di carico.

### File target
- `packages/climate_policy_energy.yaml`
- `packages/climateops/strategies/arbiter.yaml`
- `docs/logic/core/regole_core_logiche.md`

### Deliverable
- binary sensor policy: `allow_shift_load`, `prefer_self_consumption`, `grid_expensive_now` (nomi da finalizzare in coerenza naming bridge);
- reason sensor leggibile per explainability;
- nessun rename di entity in produzione.

### Validazione
- replay logico su 3 scenari: tariffa alta, tariffa bassa, surplus PV;
- verificare che policy non rompa lock anti-churn esistenti.

### Rollback
- toggle policy tariff/grid su OFF via helper dedicato;
- ritorno al comportamento precedente.

---

## Micro-step 7.3 - Multi-load Hierarchy

### Obiettivo
Formalizzare una gerarchia unica tra Heating / AC / VMC / DHW con priorita` deterministiche.

### File target
- `packages/climateops/strategies/planner.yaml`
- `packages/climateops/strategies/arbiter.yaml`
- `packages/climateops/actuators/system_actuator.yaml`
- `docs/logic/core/regole_core_logiche.md`

### Deliverable
- matrice priorita` (comfort, sicurezza impianto, energia, tariffa);
- regole anti-conflitto esplicite (es. no heat+cool simultanei, VMC boost condizionato);
- reason string unica per ogni decisione.

### Validazione
- trace runtime su automazione attuatrice con correlazione `context_id`;
- conferma assenza oscillazioni rapide su attuatori principali.

### Rollback
- cutover selettivo OFF per dominio impattato (heating/ac/vmc/dhw);
- restore del planner/arbiter precedente.

---

## Micro-step 7.4 - KPI Closure + Evidence Pack

### Obiettivo
Chiudere KPI AEB con metriche misurabili e audit trail ripetibile.

### File target
- `packages/climateops/core/kpi.yaml`
- `lovelace/06_power_runtime.yaml` (sezione KPI AEB)
- `docs/audits/` (report closure)
- `docs/logic/energy_pm/plancia_mirai_ehw.md`

### Deliverable
- KPI minimi:
  - self-consumption ratio,
  - load shifting effectiveness,
  - comfort vs energia (indicatore composito),
  - quota runtime con policy attiva.
- dashboard e documento di chiusura con finestre temporali esplicite.

### Validazione
- confronto baseline vs post-step su finestra minima (es. 7 giorni);
- evidenza tracciata in `docs/runtime_evidence/<date>/`.

### Rollback
- mantenere KPI in sola osservazione se i controlli attivi regressano;
- rollback dei soli blocchi decisionali, non della telemetria.

---

## Definition of Done (Step 7 completo)
1. Tutti e 4 micro-step implementati con gate PASS.
2. `ha core check` PASS dopo ogni deploy.
3. Nessun rename di `entity_id` esistenti.
4. Evidenza runtime con `context_id` per i path attuatori principali.
5. Report finale di closure AEB in `docs/audits/` con data e limiti noti.

## Sequenza consigliata
1. 7.1 Forecast contracts
2. 7.2 Tariff/grid policy
3. 7.3 Multi-load hierarchy
4. 7.4 KPI closure

## Stima operativa
- 7.1: 0.5-1 giorno
- 7.2: 0.5-1 giorno
- 7.3: 1-2 giorni (piu` rischio regressione)
- 7.4: 0.5-1 giorno

Totale: 2.5-5 giorni operativi, con deploy incrementali.
