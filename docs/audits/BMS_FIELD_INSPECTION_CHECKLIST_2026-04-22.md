# BMS Field Inspection Checklist (2026-04-22)

## Scope

Scheda pratica per ispezione fisica di quadro, RS485/Modbus, gateway, morsetti,
metering e predisposizione sensori cablati.

Usare questa checklist prima di comprare o installare:
- nuovi meter DIN
- moduli ingressi digitali
- gateway RS485 aggiuntivi
- sensori CO2/IAQ alimentati
- contatti finestra cablati
- moduli I/O HVAC

## Regola

DECISIONE
- Non modificare cablaggi durante la sola ispezione.
- Fotografare prima di toccare.
- Annotare A/B/GND come sono realmente cablati.
- Se serve scollegare o misurare, farlo solo in finestra dedicata e sicura.

## 1. Gateway / segmenti

| campo | bus MIRAI + SDM120 | bus EHW | nuovo segmento candidato |
|---|---|---|---|
| gateway model |  |  |  |
| IP | `192.168.178.191` |  |  |
| port | `502` |  |  |
| alimentazione gateway |  |  |  |
| posizione fisica |  |  |  |
| serial settings | `9600 8E1` |  |  |
| note etichetta/marca |  |  |  |
| foto scattata | sì / no | sì / no | sì / no |

## 2. Slave RS485

| slave | dispositivo | posizione | A wire | B wire | GND wire | terminazione | note |
|---:|---|---|---|---|---|---|---|
| 1 | MIRAI / PDC |  |  |  |  |  |  |
| 2 | SDM120 |  | bianco/arancio | arancio | bianco/verde |  | wiring gia` validato |
|  |  |  |  |  |  |  |  |

## 3. Topologia fisica

FACT
- Attualmente e` noto che MIRAI e SDM120 condividono il path `192.168.178.191:502`.

Da compilare:

| domanda | risposta |
|---|---|
| Il bus e` daisy-chain o stella? |  |
| Ordine fisico gateway -> slave |  |
| Lunghezza stimata tratta gateway -> ultimo slave |  |
| Ci sono derivazioni/stub? |  |
| Lunghezza stub massima stimata |  |
| Cavo usato |  |
| Coppia twistata usata per A/B? |  |
| Schermo presente? |  |
| Schermo collegato dove? |  |
| GND/reference presente lungo il bus? |  |
| Cavi RS485 separati da 230V/potenza? |  |
| Passaggi critici o promiscui con potenza |  |

## 4. Terminazione / biasing

| punto | presente | valore / note | foto |
|---|---|---|---|
| terminazione lato gateway | sì / no / ignoto |  |  |
| terminazione ultimo slave | sì / no / ignoto |  |  |
| terminazione intermedia errata | sì / no / ignoto |  |  |
| biasing gateway | sì / no / ignoto |  |  |
| biasing esterno | sì / no / ignoto |  |  |

DECISIONE
- Non aggiungere nuovi slave se terminazione e biasing sono ignoti.

## 5. Quadro elettrico / linee misurabili

Obiettivo: capire dove ha senso mettere metering AC/VMC e feedback attuatori.

| carico | linea dedicata identificabile | spazio DIN | neutro accessibile | TA possibile | meter diretto possibile | priorita` |
|---|---|---|---|---|---|---|
| AC giorno |  |  |  |  |  | alta |
| AC notte |  |  |  |  |  | alta |
| VMC |  |  |  |  |  | alta |
| heating/PDC/MIRAI |  |  |  |  |  | media dopo truth |
| EHW/ACS |  |  |  |  |  | media |
| altro carico shiftabile |  |  |  |  |  | backlog |

## 6. Contatti finestre / porte

Obiettivo: capire se conviene DI cablato, nodo locale alimentato o wireless residuo.

| zona | finestre/porte | cavo gia` presente | passaggio possibile | arriva a quadro? | nodo locale possibile | decisione preliminare |
|---|---|---|---|---|---|---|
| giorno |  |  |  |  |  |  |
| notte |  |  |  |  |  |  |
| bagno |  |  |  |  |  |  |
| ingresso/porta |  |  |  |  |  |  |

DECISIONE
- Per il BMS basta prima l'aggregato affidabile per zona, non ogni anta individuale.

## 7. CO2 / IAQ

| zona | punto sensore ideale | presa 230V vicina | Ethernet/PoE possibile | Wi-Fi stabile | note posizionamento |
|---|---|---|---|---|---|
| giorno |  |  |  |  |  |
| notte |  |  |  |  |  |
| eventuale studio |  |  |  |  |  |

Regole di posizionamento:
- non sopra termosifoni/split/VMC
- non in piena corrente d'aria
- altezza respirazione, parete o piano stabile
- evitare sole diretto
- evitare angoli morti

DECISIONE
- CO2 e` prioritaria per VMC, ma la scelta protocollo dipende dal cablaggio reale.

## 8. Foto richieste

| foto | fatta | note |
|---|---|---|
| gateway RS485 generale | sì / no |  |
| morsetti gateway A/B/GND | sì / no |  |
| morsetti MIRAI/PDC se accessibili | sì / no |  |
| morsetti SDM120 | sì / no |  |
| quadro completo con spazio DIN | sì / no |  |
| linee AC/VMC identificate | sì / no |  |
| EHW gateway/morsetti | sì / no |  |

## 9. Decisione dopo ispezione

Compilare solo dopo avere i dati sopra.

| domanda | risposta |
|---|---|
| Posso aggiungere slave al bus MIRAI/SDM120 senza degradare affidabilita`? |  |
| Serve un secondo gateway RS485 dedicato a I/O o metering? |  |
| AC/VMC metering e` fattibile in quadro? |  |
| Contatti finestre conviene cablarli a quadro o a nodo locale? |  |
| CO2 conviene PoE, ESPHome alimentato, RS485 o altro? |  |
| Qual e` il primo intervento fisico a ROI piu` alto? |  |

## Exit criteria

DECISIONE
- Dopo l'ispezione si puo` passare a scelta componenti solo se sono noti:
  - segmento bus
  - gateway
  - indirizzi disponibili
  - spazio quadro
  - percorsi cavo
  - linee carico misurabili
  - tipo di feedback desiderato

DECISIONE
- Se questi dati restano ignoti, la prossima azione non e` comprare hardware:
  e` completare l'ispezione fisica.
