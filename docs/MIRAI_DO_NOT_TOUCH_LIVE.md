# MIRAI Do Not Touch Live

## Purpose

- evitare scritture live su registri non validati o dipendenti da hardware assente
- mantenere il workflow strettamente read-first

## Do Not Write

### Service / config registers

- `9024`
- `16394`
- `16392`
- `16393`

Reason:
- registri di servizio/configurazione
- rischio di alterare offset o comportamento macchina/controller
- nessuna necessita' operativa nel pass di validazione corrente

### ACS / DHW related, excluded now

- `8989`
- `16395`

Reason:
- ACS / DHW non collegata
- possibile semantica falsa o non rappresentativa sul profilo reale
- `16395` e' anche un registro di write/service

### Febos-Crono related, excluded now

- `9146`
- `9147`
- `9148`
- `9151`
- `9066`
- `9152`
- `9153`

Reason:
- Febos-Crono Master non installato
- nessun valore letto sarebbe interpretabile in modo affidabile

## FACT

- il manuale corretto usa `PW 59` come livello service HMI dello Smart-MT
- non esiste al momento una procedura Modbus documentata di unlock da usare sul bus

## ASSUMPTION

- finche' non emerge un registro di unlock documentato e verificato, ogni write live fuori dai casi gia' governati va trattata come non sicura

## RISK

- modifica di offset sensori
- alterazione di setpoint o stati controller
- introduzione di drift difficile da auditare

## NEXT STEP

- limitarsi ai registri read-only elencati nel piano profiled mapping
- validare prima i candidati Smart-MT e solo dopo decidere eventuali test ulteriori
