# MIRAI Smart-MT Validation Checklist

## Scope

- validazione read-first dei candidati Smart-MT
- nessuna scrittura live
- nessun impatto sul namespace macchina stabile `1003/1208/1209`

## Runtime Windows

### Idle

- macchina ferma
- nessuna chiamata heating reale
- stato bus stabile

### Real Heating Run

- run reale della macchina
- richiesta heating reale o manual boost controllato
- finestra sufficientemente lunga da osservare plateau

### Transition / Startup

- finestra di accensione
- osservare `pre-run -> run`
- se possibile osservare anche lo spegnimento

## Baseline To Compare Against

- realta' fisica osservabile
- sensori runtime gia' esistenti
- valori letti direttamente fuori da HA se necessario
- coerenza su letture ripetute

## Candidate Checks

### 8986

- expected: temperatura aria esterna Smart-MT
- compare against:
  - temperatura esterna fisica plausibile
  - `sensor.t_out`
  - stabilita' multi-lettura
- accept only if:
  - andamento coerente con meteo reale
  - bassa dipendenza da startup/run macchina

### 8987

- expected: temperatura acqua in uscita
- compare against:
  - comportamento termico atteso in heating run
  - riferimento `9052` se coerente
  - andamento su startup/run
- accept only if:
  - sale/scende in modo fisico coerente
  - non resta piatto o codificato in modo ambiguo

### 8988

- expected: temperatura acqua in entrata
- compare against:
  - plausibilita' fisica
  - differenza con `8987`
  - stabilita' su piu' letture
- reject or hold if:
  - resta su valore sentinel/costante sospetta

### 9007

- expected: DO4 circolatore PdC
- compare against:
  - run macchina reale
  - `sensor.mirai_power_w_effective`
  - transition startup
- accept only if:
  - passa in modo coerente tra idle/startup/run
  - discrimina meglio del candidato storico `3547`

### 9043

- expected: segnale compressore 0-10V
- compare against:
  - startup
  - real heating run
  - idle
- reject or hold if:
  - non cambia tra finestre diverse

### 9003 / 9004 / 9005 / 9002

- expected: stati output digitali Smart-MT
- compare against:
  - eventi macchina osservabili
  - output noti o stati di impianto
  - consistenza sulle finestre runtime
- accept only if:
  - almeno un output mostra correlazione netta e ripetibile

### 9001

- expected: output analogico AO1
- compare against:
  - startup/run/idle
  - eventuale scala analogica plausibile
- hold unless:
  - cambia in modo leggibile e correlato

## Repeated Read Rule

- ogni candidato va controllato in almeno:
  - 1 finestra idle
  - 1 finestra heating run
  - 1 transition/startup se disponibile
- non promuovere su singolo snapshot

## Promotion Decision

### Promote to stable profile

- evidenza ripetuta
- semantica difendibile
- correlazione fisica chiara
- nessun conflitto col namespace macchina stabile

### Keep as candidate

- registro vivo ma semantica/scaling ancora incompleta

### Exclude

- dipendenza hardware assente
- service/config write
- nessuna utilita' operativa

## FACT

- `1003/1208/1209` restano fuori checklist di discovery: sono gia' stabili.

## RISK

- lettura vera ma semantica errata
- correlazione occasionale scambiata per causalita'

## NEXT STEP

- loggare i risultati nel registry candidati
- aggiornare il mapping canonico solo dopo evidenza ripetuta
