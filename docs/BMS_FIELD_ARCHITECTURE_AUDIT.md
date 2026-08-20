# BMS Field Architecture Audit

Status: ANALYSIS_BASELINE
Owner: 3_MERCURIO / AEB
Date: 2026-08-20
Scope: analisi e proposta; nessuna modifica runtime o acquisto hardware autorizzato.

## 1. Obiettivo

Definire una baseline BMS domestica affidabile, cablata dove utile, senza dipendenza strutturale da batterie, riusando l'infrastruttura esistente e separando sensing, field I/O, trasporto, logica e attuazione.

## 2. Fatti confermati dal repository

### MIRAI + SDM120

`packages/mirai_modbus.yaml` definisce un unico hub Home Assistant Modbus TCP:

- hub: `mirai`
- `type: tcp`
- host: `!secret mirai_modbus_host`
- porta: `502`
- MIRAI: slave `1`
- SDM120: slave `2`

Il file contiene telemetria MIRAI read-only/discovery e SDM120 su registri input. La baseline corrente va quindi trattata come un segmento fieldbus già consolidato: stesso endpoint TCP, più slave Modbus.

### EHW

`archive/legacy/climate_ehw_modbus.yaml` documenta una precedente integrazione EHW con:

- hub: `mirai_ehw`
- `type: tcp`
- host: `!secret ehw_modbus_host`
- porta: `502`
- slave `3`

Poiché il file è sotto `archive/legacy`, questa configurazione NON costituisce prova dello stato runtime attuale. Prima di assegnare il secondo gateway RS485→Ethernet all'EHW o ad altro uso va verificato l'hardware reale e la configurazione live.

### Serramenti

I contatti serramenti sono già fisicamente cablati e centralizzati. Non è richiesto sostituire i reed con sensori smart o a batteria. L'oggetto da decidere è solo il layer di acquisizione digitale.

## 3. Punti non verificati

- ruolo fisico esatto dei due gateway RS485→Ethernet disponibili;
- quale gateway serve oggi MIRAI/SDM120;
- se EHW usa ancora Modbus, quale gateway/endpoint utilizza e se la comunicazione è read-only o write-enabled;
- protocollo fisico/controllo corrente della VMC;
- stato runtime dei contatti serramenti e del workstream M10;
- quantità, posizione e qualità dei sensori ambiente attuali da sostituire o mantenere.

Questi punti non devono essere colmati con assunzioni.

## 4. Target architecture proposta

```text
                    Ethernet / LAN
                         |
                   Home Assistant
                         |
          +--------------+--------------+
          |                             |
   GW RS485→ETH A                  GW RS485→ETH B
   HVAC / metering                 Field I/O futuro
          |                             |
      RS485 A                         RS485 B
   +------+------+                +-----+------+
   |             |                |            |
MIRAI #1     SDM120 #2         DI Modbus    DO/relay Modbus
                                  |            |
                         contatti cablati   consensi/attuazioni
```

### Segmento A — HVAC / metering

Mantenere come baseline il segmento già dimostrato nel repo:

- MIRAI slave 1
- SDM120 slave 2

Non aggiungere nuovi carichi o moduli prima di verificare topologia fisica, terminazioni, baud-rate del lato RTU del gateway e margine di affidabilità.

### Segmento B — field I/O

Riservare il secondo gateway, se libero dopo verifica EHW, a moduli I/O Modbus RTU:

- ingressi digitali per segnali cablati centralizzati;
- relè/uscite a contatto pulito per consensi semplici;
- eventuali sonde tecniche semplici.

RS485 trasporta dati tra moduli; i contatti e i circuiti relè restano elettricamente separati e terminano sui rispettivi I/O.

### Ethernet / PoE

Usare Ethernet/PoE come backbone per nodi stanza ricchi solo dove porta valore reale:

- T/RH/CO2;
- presenza evoluta;
- UI/pannello locale;
- diagnostica e aggiornamento firmware.

Non usare PoE per ogni singolo sensore binario: sarebbe sovradimensionato rispetto a DI Modbus centralizzati.

## 5. Piano sensori

### KEEP

- contatti serramenti cablati esistenti;
- sensori/telemetrie già stabili e senza batterie quando la qualità del dato è sufficiente;
- SDM120 sul segmento Modbus già esistente.

### REVIEW BEFORE REPLACEMENT

- sensori T/RH wireless attuali: valutarli stanza per stanza per qualità dato, alimentazione e utilità BMS;
- sensori a batteria: sostituire solo quelli realmente critici o ad alta manutenzione;
- qualsiasi sensore duplicato che non alimenta una logica o KPI concreto.

### TARGET

Per ambienti principali:

- nodo cablato alimentato, preferibilmente Ethernet/PoE se la presa di rete è già disponibile;
- T/RH come baseline;
- CO2 solo dove influenza VMC/comfort;
- presenza solo dove abilita una decisione utile.

Per segnali binari/tecnici centralizzati:

- DI cablati;
- Modbus RTU come trasporto dal modulo al BMS.

Wireless/batteria resta un layer secondario, non il fondamento del BMS.

## 6. Decisioni

1. Non sostituire i reed cablati dei serramenti.
2. Mantenere MIRAI + SDM120 sul segmento attuale finché non emerge un problema reale.
3. Non assegnare il secondo gateway finché EHW non è verificato fisicamente/runtime.
4. Se il secondo gateway è libero, preferire un segmento RS485 dedicato ai field I/O centralizzati.
5. Usare PoE selettivamente per nodi stanza multisensore, non come soluzione universale.
6. Nessun acquisto di moduli DI/DO prima del censimento di tensioni, tipo contatti, numero I/O e spazio quadro.

## 7. Pre-mortem

| Failure mode | Segnale precoce | Contromisura minima |
|---|---|---|
| Assegnare male uno dei due gateway | device già in uso diventa intermittente/offline | inventory fisico + IP/porta/slave prima di modificare |
| Duplicare integrazioni Modbus | warning hub duplicato / polling instabile | un solo hub HA per endpoint TCP |
| Comprare DI incompatibili con i contatti | ingressi richiedono 12/24 V invece di dry contact | verificare schema elettrico dei DI prima dell'acquisto |
| Over-engineering PoE | costo/nodo alto senza nuovi controlli utili | PoE solo su room node multisensore |
| Dipendenza da HA per funzioni vitali | perdita rete = perdita servizio base | mantenere fallback locale/manuale sugli impianti |

## 8. Next implementation gate

Aprire un workstream operativo separato solo dopo aver rilevato e registrato:

- gateway A: IP, seriale/modello, RS485 devices collegati;
- gateway B: IP, seriale/modello, RS485 devices collegati;
- EHW: protocollo/endpoint/slave/read-write reale;
- VMC: protocollo/ingressi/uscite disponibili;
- serramenti: numero reed/tamper, NO/NC, schema morsettiera;
- sensori ambiente: inventario per stanza, alimentazione, protocollo, qualità dato.

Fino a quel gate: analisi conclusa, nessuna implementazione hardware autorizzata.
