# STEP89 - Clima Casa overview refactor (2026-04-28)

## Scopo
Avviare la Fase 1 del piano plance: trasformare `Clima Casa` in una vista realmente operativa, riducendo nel main viewport soglie, writer e tuning.

## FACT
La vista `Clima Casa` prima del refactor mescolava:
- overview operativa;
- tuning soglie;
- dettagli writer EHW;
- manual controls profondi;
- parte di diagnostica che appartiene ai drill-down di dominio.

## DECISIONE
Il refactor della vista principale segue queste regole:
- sopra il fold: solo stato, reason, attuazione e KPI essenziali;
- sotto: dettagli minimi per il comando umano;
- tuning avanzato e writer restano nelle plance dominio/tecniche.

## Modifiche applicate

### Bagno e boost
- rimosse dalla vista principale:
  - `input_number.vmc_bagno_on`
  - `input_number.vmc_bagno_off`
- mantenuti:
  - `T bagno`
  - `UR bagno`
  - `Boost manuale`
  - `Boost auto`
  - `ETA boost`

### VMC
- rimossi dalla vista principale:
  - `input_select.vmc_manual_speed`
  - `timer.vmc_manual_timeout`
  - relè `switch.vmc_vel_0..3`
  - `freecooling candidabile`
- mantenuti:
  - modalità
  - manuale
  - `vel target`
  - `vel attuale`
  - `freecooling attivo`
  - stato freecooling
  - `reason VMC`

### AC
- rimossi dalla vista principale:
  - soglie DRY
  - timeout manuale
  - timeout block VMC
  - setpoint/tuning secondari
- mantenuti:
  - attuazione giorno/notte
  - block da VMC
  - `AC bloccata`
  - `reason AC`
  - manuale attivo

### Heating
- rimossi dalla vista principale:
  - setpoint e soglie
  - min on/off
  - timeout manuali
  - dettaglio lock residuale
- mantenuti:
  - logica attiva
  - `should run`
  - `demand`
  - `held by min ON`
  - `reason Heat`
  - `heat source`

### DHW / EHW
- rimossa la sezione writer dettagliata dal main viewport
- rimossi raw/calc details
- mantenuti:
  - feedback attuale / atteso
  - feedback coerente
  - modbus ready
  - setpoint scalato
  - blocked reason

## Esito

## FACT
La vista principale ora è meno densa e più coerente con il ruolo di overview.

## DECISIONE
Le soglie e il tuning non spariscono:
- restano nelle plance dominio o tecniche;
- smettono solo di occupare la vista primaria.

## Prossimo passo

## DECISIONE
Dopo `Clima Casa`, la sequenza resta:
1. ripulire `Heating`
2. decidere le plance `v2`
3. consolidare `Passive House` / `Involucro`
