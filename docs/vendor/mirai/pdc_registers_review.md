# PDC Registers and I/O Review

## Premessa
Questa review deriva solo da `manuale_pdc.md`.
Non sono presenti nella pagina indirizzi registri Modbus espliciti per i codici `C4xx`: ogni mapping `C4xx -> registro Modbus` resta `AMBIGUO`.

## Tabella tecnica (I/O e morsetti)

| codice | funzione | tipo segnale | morsetti fisici | default | note operative |
|---|---|---|---|---:|---|
| Outdoor temp. | Sonda temperatura esterna | `NTC 10k@25C` (sonda) | `A+ / A-` | n/d | Sonda passiva; non applicare tensione esterna. |
| C420 | Non utilizzato | `AMBIGUO` | `B+ / B-` | 0 | Punto non documentato operativamente. |
| C421 (I/O 100) | Sonda temperatura ACS | `NTC 10k@25C` (sonda) | `C+ / C-` | 0 | Sonda passiva. |
| C422 (I/O 101) | Termostato ambiente | Ingresso digitale `contatto pulito` | `D+ / D-` | 0 | Ingresso a contatto, non alimentato da esterno. |
| C423 (I/O 102) | On/Off remoto | Ingresso digitale `contatto pulito` | `E+ / E-` | 0 | Comando remoto abilitazione macchina. |
| C424 (I/O 103) | Limitazione frequenza compressore | Ingresso digitale `contatto pulito` | `F+ / F-` | 0 | Logica di limitazione da validare in commissioning. |
| C425 (I/O 104) | Estate/Inverno remoto | Ingresso digitale `contatto pulito` | `G+ / G-` | 0 | Cambio stagione da consenso esterno. |
| C426 (I/O 105) | Set point 2 | Ingresso digitale `contatto pulito` | `H+ / H-` | 0 | Abilita funzione SetPoint2. |
| C427 (I/O 200) | Consenso riscaldatore addizionale | Uscita `230V AC max 8A` | `R1` | 0 | Punto di potenza: richiede protezioni e interfacciamento corretto. |
| C428 (I/O 201) | Non utilizzato | `AMBIGUO` | `T1` | 0 | Nessuna funzione descritta. |
| C429 (I/O 202) | Consenso Eco Hot Water | Ingresso digitale `contatto pulito` | `M1 / M2` | 0 | Indicata come input; direzione funzionale da verificare in campo. |
| C430 (I/O 203) | Segnalazione PdC in allarme | Uscita `230V AC max 2A` | `P2` | 0 | Non collegare a ingressi SELV senza relè/isolamento. |
| C431 (I/O 204) | Consenso valvola 3-vie ACS | Uscita `230V AC max 2A` | `W1` | 0 | Pilotaggio valvola su rete 230V. |
| C432 (I/O 205) | Non utilizzato | `AMBIGUO` | `U1` | 0 | Nessuna funzione descritta. |
| C433 (I/O 206) | Non utilizzato | `AMBIGUO` | `X+ / X-` | 0 | Nessuna funzione descritta. |
| Pump di rilancio | Pompa di rilancio | Uscita `230V AC max 2A` | `P1` | n/d | Nessun codice `C4xx`/I/O logico indicato. |
| RS-485 | Bus seriale | Modbus RTU `9600 8E1 addr=1 timeout=1000ms` | `- / + / G` | n/d | Parametri link noti; mappa registri assente in pagina. |

## Parametri configurabili C4xx (non I/O fisico)

| codice | funzione | default | note operative |
|---|---|---:|---|
| C402 | Stato operativo in Off | 1 | `0`=quasi tutto off con antigelo; `1`=ACS+antigelo attivi. |
| C403 | Non utilizzato | 0 | Ignorare in supervisione base. |
| C404 | Attivazione Pump2 | 0 | Selezione ambito Pump2 (`radiante`/`SP2`/entrambi). |
| C405 | Curva climatica Set Point 2 | 0 | `0` off, `1` on. |
| C406 | Non utilizzato | 1 | Campo non operativo noto. |
| C407 | Modalita' ACS | 0 | Scelta sorgente ACS (`EcoHW`/`PdC`/`non disponibile`). |
| C408 | Logica Pump1 con compressore spento | 0 | `sempre`/`15min`/`auto`. |

## Voci realmente utili per supervisione impianto

1. `I/O 100` temperatura ACS (misura fondamentale).
2. `Outdoor temp.` sonda esterna (compensazione climatica).
3. `I/O 102` On/Off remoto (stato comando macchina).
4. `I/O 104` Estate/Inverno remoto (modalita' impianto).
5. `I/O 103` limitazione compressore (derating esterno).
6. `I/O 203` uscita allarme PdC (teleallarme).
7. `I/O 204` comando valvola 3-vie ACS (stato produzione ACS).
8. `I/O 200` consenso riscaldatore addizionale (stadio integrazione).
9. Parametri `C402`, `C404`, `C405`, `C407`, `C408` (assetto logico macchina).

## Punti pericolosi o ambigui

- Uscite `R1`, `P2`, `W1`, `P1` sono a `230V AC`: rischio danneggiamento/folgorazione se trattate come contatti puliti.
- Ingressi sonda `A+/A-`, `C+/C-` sono NTC passive: rischio misura errata/danno se alimentate.
- `C420`, `C428`, `C432`, `C433` e relativi morsetti risultano non utilizzati: non impiegarli senza verifica manuale completo.
- La pagina non fornisce offset/indirizzi registri Modbus; quindi la supervisione via RS-485 richiede ulteriore mappa ufficiale.

## Tassonomia entita' pulita e scalabile (HA/Node-RED)

- Prefisso: `pdc_mirai_`
- Pattern: `<dominio>.<sottosistema>_<funzione>[_<canale>]`
- Domini consigliati:
  - `sensor` per temperature e valori analogici
  - `binary_sensor` per stati e allarmi
  - `switch` per consensi/comandi booleani
  - `select` per parametri enumerati `C4xx`
- Separazione livelli:
  - `physical_terminal`: es. `R1`, `D+`
  - `logical_io_ref`: es. `200`, `101`
  - `config_code`: es. `C407`

## DATI_CERTI

- Esistono i parametri `C402..C408` e `C420..C433` con default come da pagina.
- `I/O 100..105` e `200..206` sono riferimenti logici distinti dai morsetti fisici.
- Classi elettriche esplicite: `NTC 10k@25C`, `contatto pulito`, `uscita 230V AC` con limiti indicati.
- Bus seriale dichiarato: Modbus RTU su RS-485 (`9600`, `8E1`, `addr 1`, `timeout 1000 ms`).

## IPOTESI

- I codici `C4xx` possano essere leggibili/scrivibili via Modbus: non confermato dalla pagina.
- `I/O 202` possa rappresentare un consenso proveniente da dispositivo esterno verso la PdC (direzione da validare).

## RISCHI_DI_INTEGRAZIONE

- Assenza mappa registri: rischio mapping errato in polling Modbus.
- Ambiguita' su punti "non utilizzati": rischio cablaggio su morsetti inattivi.
- Misto SELV/230V nello stesso quadro: rischio sicurezza se manca separazione galvanica.
- Naming non coerente tra livelli fisico/logico/config: rischio confusione operativa in HA/Node-RED.
