# STEP83 - Nodo DIN Tecnico 01 BOM v1 (2026-04-27)

## Scopo
Formalizzare in documentazione la BOM tecnica v1 del nodo DIN definitivo per:
- contatti filari serramenti/porte;
- sensori VMC;
- 3 uscite relè velocità VMC;
- 1 uscita relè comando portone garage.

## Boundary
Questa nota non è una buylist finale esecutiva di acquisto.
Serve a congelare l'architettura target e i blocchi materiali minimi.

## FACT
- I contatti filari serramenti esistono già e convergono in garage.
- Le plance e gli helper `input_boolean.vent_finestra_*` esistono già.
- Il runtime VMC usa oggi i relè `switch.vmc_vel_0..3`.
- L'obiettivo è un nodo definitivo:
  - cablato;
  - Ethernet/LAN;
  - montaggio DIN;
  - manutenibile;
  - separato da soluzioni provvisorie tipo Mega/Raspberry.
- In garage/tecnico esiste già alimentazione 12 V tramite `Mean Well HDR-15-12`.

## IPOTESI (confidenza alta)
- La base controller più coerente per questo progetto è un nodo ESP32 Ethernet supportato da ESPHome.
- Il packaging corretto è DIN-oriented, con controller, alimentazione/logica, morsetti e relè ordinati e separati.
- Le uscite VMC devono restare mutuamente esclusive.
- Il relè portone garage deve essere trattato come comando impulsivo, non come consenso mantenuto, salvo prova contraria.

## DECISIONE
Il target documentato diventa:

`Nodo DIN Tecnico 01 = controller Ethernet + ingressi digitali + sensori VMC + 4 uscite relè + distribuzione DIN`

---

## BOM v1

| Blocco | Componente / classe | Ruolo | Stato |
|---|---|---|---|
| Controller | ESP32 Ethernet class (`Olimex ESP32-POE2` preferred, `ESP32-POE` acceptable) | cervello ESPHome/LAN del nodo | obbligatorio |
| Packaging | supporto / contenitore DIN per board controller | montaggio ordinato, manutenzione, isolamento meccanico | obbligatorio |
| Alimentazione logica | PoE **oppure** conversione ordinata `12 V -> 5 V` dal ramo HDR-15-12 | alimentazione stabile controller | obbligatorio |
| Protezione ramo | fusibile/protezione dedicata lato bassa tensione per il nodo | hardening alimentazione | obbligatorio |
| Distribuzione segnali | morsetti DIN separati per ingressi, comuni e uscite | cablaggio pulito e serviceability | obbligatorio |
| Front-end ingressi | resistenze serie, pull-up/pull-down definiti, filtro RC leggero, ESD/TVS base | robustezza ingressi contatti | obbligatorio |
| Ingressi digitali | 8-10 canali minimi | finestre, portoncino, foro cappa, stato garage futuro, tamper futuro | obbligatorio |
| Uscite relè | modulo relè 4 canali separato dal controller | `VMC vel_1`, `VMC vel_2`, `VMC vel_3`, trigger garage | obbligatorio |
| Sensore T/RH VMC locale | classe `SHT4x` o equivalente | sensore tecnico locale nodo/ramo VMC | obbligatorio v1 se il nodo nasce già come nodo VMC |
| Sonde macchina VMC | da definire per punti reali di misura macchina | feedback temperatura macchina / flussi | quasi-obbligatorio, da chiudere con lista segnali |
| Rete | patch Ethernet corto / cablaggio LAN ordinato | uplink stabile | obbligatorio |
| Etichettatura | marker morsetti/cavi/I-O | manutenzione e debug | obbligatorio |

---

## Budget I/O v1

### Digital inputs
- `giorno1`
- `giorno2`
- `notte1`
- `notte2`
- `notte3`
- `bagno`
- `portoncino ingresso`
- `foro cappa`
- `garage door state` future
- `tamper` future

Target minimo: `8 DI`  
Target con margine: `10 DI`

### Digital outputs
- `VMC speed 1`
- `VMC speed 2`
- `VMC speed 3`
- `garage door trigger`

Target: `4 DO`

### Sensor bus / analog expansion
- T/RH tecnico locale nodo
- sonde macchina VMC
- margine per futura integrazione CO2 solo se fisicamente sensata nello stesso punto

---

## Scelte escluse

## FACT
- `Raspberry Pi 1` è stato valutato.
- `Arduino Mega + Ethernet shield` è stato valutato.
- doppio Arduino con seriale interna è stato valutato.

## DECISIONE
Queste opzioni non entrano nel nodo definitivo:
- no Raspberry Pi 1;
- no Mega come piattaforma finale;
- no mini-bus seriale proprietario tra MCU.

Motivo tecnico:
- più attrito manutentivo;
- più firmware da tenere vivi;
- architettura meno deterministica;
- peggior rapporto robustezza/tempo speso rispetto a controller Ethernet ESPHome.

---

## Optoisolazione

## FACT
Per contatti puliti serramenti l'optoisolazione non è un prerequisito per una v1 robusta.

## DECISIONE
v1:
- niente optoisolatori come requisito base;
- sì a protezioni base ingressi e cablaggio ordinato.

Upgrade futuro solo se emergono:
- disturbi EMC reali;
- ground noise;
- failure mode lato lunghi cablaggi.

---

## Regole architetturali del nodo

1. controller e relè restano blocchi distinti;
2. le 3 velocità VMC devono essere mutuamente esclusive;
3. il comando garage è impulsivo salvo evidenza contraria;
4. nessun nuovo modello entity lato HA per le finestre: il nodo deve bindare l'upstream fisico agli helper già esistenti;
5. il nodo nasce LAN-first, non Wi-Fi-first.

---

## Open item residui

## FACT
La BOM v1 è abbastanza chiara per congelare il boundary, ma non chiude ancora:
- scelta esatta del modulo relè DIN;
- scelta esatta della conversione `12 V -> 5 V` se non si usa PoE;
- lista finale sonde macchina VMC;
- allocazione pin / espansioni I/O definitive.

## DECISIONE
Questi restano step successivi di engineering, non bloccano la formalizzazione della BOM v1.
