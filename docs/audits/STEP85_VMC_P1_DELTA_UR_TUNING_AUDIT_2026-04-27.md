# STEP85 - VMC P1_delta_ur tuning audit (2026-04-27)

## Scopo
Capire se la policy `P1_delta_ur` è troppo aggressiva e sta tenendo la VMC a `vel_2` più del necessario.

## Sintesi

## FACT
L'attuazione `vel_2` oggi funziona.

## FACT
La permanenza lunga su `vel_2` è spiegata dalla regola:

`ur_in_media > 50 and (ur_in_media - ur_out) >= 10`

## DECISIONE
Il punto da correggere non è il writer VMC, ma la sensibilità della policy `P1_delta_ur`.

---

## Stato attuale

## FACT
Campione live durante l'audit:
- `sensor.ur_in_media = 54 %`
- `sensor.ur_out = 38 %`
- `sensor.delta_ah_in_out = 2.28 g/m3`
- `sensor.delta_t_in_out = -2.12 C`
- `sensor.vmc_vel_target = 2`
- `sensor.ventilation_priority = P1_delta_ur`
- `sensor.ventilation_reason = P1 – aria esterna più secca (ΔUR)`

## FACT
Storico odierno:
- fino alle `08:28` la VMC era a `vel_1`
- dalle `08:28` è salita a `vel_2`
- alle `11:16` è scesa a `0` solo per `P0_failsafe`
- alle `11:26` è tornata a `vel_2`
- `vel_2` ha firma di potenza circa `70-73 W`
- `vel_1` ha firma di potenza circa `26 W`

## DECISIONE
Il sistema non è "bloccato": sta semplicemente applicando in modo coerente una policy troppo permissiva per le condizioni attuali.

---

## Root cause

## FACT
Nel file `packages/climate_ventilation.yaml` la regola `P1_delta_ur` non usa:
- isteresi dedicata;
- timer minimo di persistenza;
- soglia di rilascio separata;
- correlazione con CO2;
- correlazione con carico bagno specifico.

## FACT
La regola usa solo:
- UR interna media > `50`
- differenza UR interna-esterna >= `10`

## IPOTESI (confidenza alta)
In mezze stagioni o giornate ventilabili, questa regola:
- scatta facilmente;
- resta vera per molte ore;
- mantiene `vel_2` anche quando il beneficio marginale non è più alto.

## DECISIONE
La policy è efficace come "trigger semplice", ma non è abbastanza selettiva per un comportamento BMS più sobrio.

---

## Cosa NON fare

1. ## FACT
   `vel_2` ha effetto reale.
   ## DECISIONE
   Non ha senso toccare relè, proxy o binding VMC per questo problema.

2. ## FACT
   Il monitor potenza PM1 distingue bene `vel_1` da `vel_2`.
   ## DECISIONE
   Non serve aprire ora un nuovo filone di metering solo per capire questo caso.

3. ## FACT
   L'assenza di CO2 rende la ventilazione ancora solo-igrometrica.
   ## DECISIONE
   Non aspettare la CO2 per correggere una soglia manifestamente aggressiva.

---

## Opzioni di tuning

### Opzione A - alzare le soglie

## DECISIONE
Prima correzione a massimo ROI:
- alzare `ur_in_media` da `> 50` a `>= 55`
- alzare `delta UR` da `>= 10` a `>= 15`

### Effetto atteso
- meno ore in `P1_delta_ur`
- meno permanenze lunghe a `vel_2`
- basso rischio di regressione

### Contro
- tuning più grezzo
- nessuna isteresi vera

---

### Opzione B - introdurre isteresi on/off

## DECISIONE
Opzione migliore architetturalmente:
- condizione ON più alta
- condizione OFF più bassa

Esempio:
- ON: `ur_in_media >= 55` e `delta_ur >= 15`
- OFF: `ur_in_media <= 52` oppure `delta_ur <= 10`

### Effetto atteso
- meno flapping
- meno permanenze inutili
- comportamento più leggibile

### Contro
- richiede refactor template leggermente più strutturato

---

### Opzione C - aggiungere dwell time

## DECISIONE
Aggiungere `delay_on` / `delay_off` o un binary sensor dedicato a `P1_delta_ur`.

### Effetto atteso
- evita salita a `2` per spike brevi

### Contro
- non risolve da solo il caso attuale, perché oggi la condizione resta vera per ore

---

## Raccomandazione finale

## DECISIONE
La strada corretta è:

1. **adesso**
   - rialzare le soglie di `P1_delta_ur`
2. **subito dopo**
   - introdurre isteresi on/off dedicata
3. **più avanti**
   - portare CO2 `giorno + matrimoniale` per smettere di far pesare troppo una logica solo-igrometrica

---

## Proposta minima concreta

## DECISIONE
Se vuoi un fix conservativo a basso rischio:

- trigger `P1_delta_ur`:
  - da `ur_in_media > 50 and delta_ur >= 10`
  - a `ur_in_media >= 55 and delta_ur >= 15`

Questa è la correzione con miglior rapporto:
- tempo di modifica basso
- rischio basso
- effetto atteso alto

---

## Verdetto

## FACT
L'attuazione VMC non è il problema.

## FACT
La policy `P1_delta_ur` è oggi troppo facile da mantenere attiva.

## DECISIONE
Il prossimo intervento corretto è un **tuning policy-side** della soglia `P1_delta_ur`, non un lavoro sul layer hardware o writer.
