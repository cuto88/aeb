# Step 2-bis — Runtime Evidence Update (Writer per evento)
Date: 2026-02-21
Scope: Read-only analysis con evidenza runtime (UI export + SSH + recorder DB)

## Obiettivo
Ridurre gli `UNKNOWN` residui di Step 2 sull'attribuzione writer per evento.

## Evidence utilizzata
- `docs/runtime_evidence/2026-02-21/trace automation.climateops_system_actuate 2026-02-21T18_58_00.541738+00_00.json`
- `docs/runtime_evidence/2026-02-21/trace automation.climateops_system_actuate 2026-02-21T19_51_22.167498+00_00.json`
- `docs/runtime_evidence/2026-02-21/trace automation.climateops_system_actuate 2026-02-21T19_52_37.899840+00_00.json`
- `docs/runtime_evidence/2026-02-21/ultima.json`
- `docs/runtime_evidence/2026-02-21/trace.saved_traces.json` (copiato da `/homeassistant/.storage/trace.saved_traces`)
- `docs/runtime_evidence/2026-02-21/history.csv`
- `docs/runtime_evidence/2026-02-21/home-assistant_v2.db` (+ `-wal`, `-shm`) interrogato in sola lettura

---

## A) Writer evento-level: VMC

### FACT
- Il trace esportato mostra un run reale di `automation.climateops_system_actuate` (`item_id`) con contesto run (`context.id`).
- Nello stesso run sono presenti azioni servizio:
  - `switch.turn_off` su `switch.vmc_vel_3`
  - `switch.turn_on` su `switch.vmc_vel_1`
- Quindi, per quell'evento, il writer è dimostrato: `automation.climateops_system_actuate`.

### FACT (recorder)
- Nel recorder (`call_service`) esistono molte scritture VMC sui target:
  - `switch.vmc_vel_1`: 5965
  - `switch.vmc_vel_3`: 5968
  - `switch.vmc_vel_0`: 377
  - `switch.vmc_vel_2`: 377
- `automation_triggered` su `automation.climateops_system_actuate` risulta presente e frequente (6442 eventi).

---

## B) Writer evento-level: Heating

### FACT
- `history.csv` mostra transizioni stato di `switch.heating_master` (sequenze `unknown -> on`) con timestamp.
- Il trace `...19_51_22...json` mostra run con `mode: HEAT` e chiamata servizio:
  - `switch.turn_on` su `switch.heating_master`.
- Quindi writer evento-level heating è attribuito: `automation.climateops_system_actuate`.

### FACT (recorder)
- Query su `call_service` nel recorder: nessuna chiamata registrata verso `switch.heating_master` (count=0).

---

## C) Writer evento-level: AC

### FACT
- Nel recorder `call_service` non risultano chiamate verso:
  - `switch.ac_giorno`
  - `switch.ac_notte`
  - `script.ac_giorno_apply`
  - `script.ac_notte_apply`
  (tutti count=0 nel dataset disponibile)

### FACT
- In `trace.saved_traces.json` i run recenti di `automation.climateops_system_actuate` risultano solo con `mode: VENT_BASE`.
- Il trace `...19_52_37...json` mostra run con `mode: COOL_DAY`, ma nessuna azione AC eseguita:
  - ramo `choose/4` (COOL_DAY) valutato `false` su condition,
  - `script.ac_giorno_apply` non chiamato nel run.
- Il trace `ultima.json` mostra run con:
  - `mode: COOL_DAY`
  - `ac_available: true`
  - scelta ramo AC `choice: 4`
  - step eseguito `action/1/choose/4/sequence/0` con servizio `script.ac_giorno_apply`
  - logbook con `script.ac_giorno_apply` started e contesto legato a `automation.climateops_system_actuate`.

### Conclusione AC
- Writer evento-level AC è attribuito come FACT: `automation.climateops_system_actuate` (invocazione `script.ac_giorno_apply` osservata a runtime).

---

## D) Stato aggiornato Step 2

### CLOSED as FACT
1. Writer evento-level VMC dimostrato (`climateops_system_actuate` -> `switch.vmc_vel_3/1`).
2. Writer evento-level heating dimostrato (`climateops_system_actuate` -> `switch.heating_master` in run `mode: HEAT`).
3. Writer evento-level AC dimostrato (`climateops_system_actuate` -> `script.ac_giorno_apply` in run `mode: COOL_DAY`).
4. Presenza e attività runtime di `automation.climateops_system_actuate` ulteriormente confermata da recorder (`automation_triggered`) e trace storage.

### STILL UNKNOWN
- Nessuno sul perimetro writer per evento climate (heating/VMC/AC) con evidence corrente.

## Step 2-bis status
- CLOSED (writer per evento chiusi su heating, VMC e AC con evidenza runtime)
