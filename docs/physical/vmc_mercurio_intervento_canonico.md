# VMC Casa Mercurio — Intervento fisico canonico

## 1. Scopo e confini

Questo documento è la SSOT tecnica per il ripristino, la strumentazione e il collaudo fisico della VMC di Casa Mercurio.

- Owner operativo: chat M16.
- Logica Home Assistant/AEB: resta separata nella chat M29 e in `docs/logic/core/regole_core_logiche.md`.
- Sequenza vincolante: `rilievo → filtri → sigillatura → sensori → baseline → coibentazione → misura finale → bilanciamento → decisioni opzionali`.
- Fonti consolidate: M07 VMC, M12 VMC, M14 VMC.
- M18 VMC non è una fonte verificata: nel portfolio collide con la chat reale M18 sul piano induzione Neff.

## 2. Stato verificato dell'impianto

- VMC centralizzata a doppio flusso installata nel garage.
- Plenum/collettori in lamiera zincata, non coibentati.
- Collegamento principale nominale DN160; distribuzione radiale nominale DN75.
- Configurazione dichiarata per ciascun circuito: `1×DN160 ↔ 6×DN75`, da confermare fisicamente.
- Condotti verso l'esterno DN160 in PVC, non coibentati.
- Tratto VMC–plenum circa 68 cm.
- Distribuzione terminale in tubo ovale PVC liscio, con salita dal pavimento e curva a 90° presso le uscite a parete.
- Bocchettoni dei plenum fissati con circa tre punti di saldatura, non saldati in continuo.
- Perdite d'aria visibili accertate nei giunti bocchettone–plenum.
- Sigillatura con butilico già iniziata/eseguita; chiusura finale con nastro rimandata per predisporre le sonde.
- Bocchettoni assimilabili ad attacchi femmina con diametro interno circa 75 mm; il tubo DN75 ha passaggio interno dichiarato circa 63 mm ed entra nel bocchettone.
- Possibile gioco tubo–bocchettone ancora da verificare dopo il ripristino del giunto principale.

## 3. Dati edificio

| Locale | Superficie m² | Altezza reale m | Volume reale m³ | Volume PH m³ | Terminali |
| --- | ---: | ---: | ---: | ---: | --- |
| Giorno | 29,03 | 3,24 | 94,0572 | 72,575 | 2 mandata + 2 ripresa |
| Camera 1 | 15,49 | 3,24 | 50,1876 | 38,725 | 2 mandata |
| Camera 2 | 9,43 | 3,42 | 32,2506 | 23,575 | 1 mandata |
| Camera 3 | 9,43 | 3,42 | 32,2506 | 23,575 | 1 mandata |
| Disimpegno | 5,73 | 2,40 | 13,752 | 13,752 | nessuno |
| Lavanderia | 5,73 | 2,40 | 13,752 | 13,752 | 2 ripresa |
| Bagno | 8,24 | 2,40 | 19,776 | 19,776 | 2 ripresa |
| Ingresso | 3,87 | 2,40 | 9,288 | da verificare | nessuno |

- Superficie utile riportata: 87 m².
- Volume reale complessivo riportato: 265,314 m³.
- Volume netto PH riportato: 215 m³.

## 4. Velocità nominali riportate

| Livello | Percentuale | Portata dichiarata |
| --- | ---: | ---: |
| Velocità 1 | 40% | 108 m³/h |
| Velocità 2 | 60% | 161 m³/h |
| Velocità 3 | 80% | 215 m³/h |
| Massima | 100% | 269 m³/h |

Questi valori sono dati riportati, non portate misurate. Devono essere verificati strumentalmente.

## 5. Geometria dei rami riportata

| Ramo | Terminali | Lunghezza totale riportata | Curve 90° | Valore storico “reg. ottimale” |
| --- | ---: | ---: | ---: | ---: |
| Giorno mandata | 2 | 9,7 m | 2 | 16 |
| Giorno ripresa | 2 | 5,1 m | 2 | 14 |
| Camera 1 mandata | 2 | 39,5 m | 2 | 18 |
| Camera 2 mandata | 1 | 32,2 m | 2 | 18 |
| Camera 3 mandata | 1 | 20,3 m | 2 | 16 |
| Lavanderia ripresa | 2 | 24,4 m | 2 | 16 |
| Bagno ripresa | 2 | 22,9 m | 2 | 16 |

Il significato e l'unità dei valori “reg. ottimale” 14/16/18 non sono definiti. Non usarli come specifica finché non vengono identificati.

## 6. Architettura di misura

### Punti temperatura

1. aria esterna → VMC;
2. aria estratta casa → VMC;
3. aria immessa VMC → casa;
4. aria espulsa VMC → esterno;
5. temperatura garage;
6. temperatura esterna reale.

### Componenti

- 6 × DS18B20 waterproof;
- ESP32 DevKit o equivalente;
- bus 1-Wire con pull-up 4,7 kΩ;
- alimentazione 5 V;
- acquisizione in Home Assistant come layer di misura, senza creare nuove logiche di controllo.

### Geometria delle sonde disponibili

- capsula: circa Ø6 × 50 mm;
- raccordo/guaina nera: circa Ø7 mm;
- cavo: circa Ø3 mm;
- foro diretto discusso: Ø8 mm;
- PG11 esclusi perché sovradimensionati;
- eventuale boccola PETG: foro interno 7–7,2 mm, corpo per foro circa 10 mm, flangia circa 22 mm.

Le quattro sonde di processo devono misurare direttamente nel flusso, essere stabili, non toccare le pareti e non introdurre perdite.

## 7. Ripristino dei plenum

### Preparazione

- Fotografare entrambi i plenum prima dell'intervento.
- Confermare geometria, dimensioni, innesti DN160/DN75, punti di saldatura, fori inutilizzati, stato della zincatura, condensa e corrosione.
- Misurare OD reale del tubo DN75, ID dei bocchettoni e spessori delle lamiere.
- Pulire e sgrassare i giunti.

### Rinforzo e tenuta

- Conservare plenum e bocchettoni esistenti salvo esito negativo del collaudo.
- Mantenere i punti di saldatura esistenti.
- Aggiungere rivetti ciechi tra i punti saldati; riferimento iniziale Ø3,2 mm, lunghezza da dimensionare sul pacchetto reale.
- Applicare sigillante HVAC continuo su tutta la circonferenza bocchettone–plenum.
- Il sigillante realizza la tenuta; i rivetti garantiscono stabilità meccanica.
- Il nastro alluminio HVAC è finitura/ridondanza, non sostituisce il sigillante.
- Verificare successivamente il giunto tubo–bocchettone e correggerlo solo se rimane una perdita o un rumore reale.

### Materiali esclusi

- schiuma poliuretanica;
- silicone generico edilizia/bagno;
- solo nastro alluminio;
- manicotti idraulici 57–63 mm;
- risaldatura continua senza necessità dimostrata.

## 8. Coibentazione

- Coibentare solo dopo ripristino della tenuta e acquisizione della baseline pre-coibentazione.
- Priorità ai condotti DN160 verso l'esterno e ai plenum metallici nel garage.
- Soluzione preferenziale da verificare: elastomero espanso a celle chiuse tipo Armaflex/K-Flex/Kaiflex.
- Spessore di riferimento discusso: 19 mm; 13 mm minimo valutato; 25 mm dove spazio e convenienza lo consentono.
- Lana di roccia: candidato alternativo per i plenum, da definire dopo rilievo; nessuna fibra deve essere esposta al flusso e serve una finitura/barriera compatibile con il rischio di condensa.
- L'isolante per cassonetti Fortlan-Dibi non è la soluzione primaria.

## 9. Procedura operativa canonica

1. Ispezionare e documentare plenum, condotti e innesti.
2. Verificare e manutenere i filtri.
3. Completare rinforzo e sigillatura dei plenum.
4. Installare le sei sonde e sigillare gli attraversamenti.
5. Testare a velocità normale e boost: perdite, vibrazioni, sibili e stabilità meccanica.
6. Acquisire baseline pre-coibentazione.
7. Coibentare DN160 e plenum.
8. Ripetere le misure nelle stesse condizioni operative.
9. Misurare le portate dei terminali e bilanciare mandata/ripresa.
10. Solo dopo rivalutare bocchette, adattatori, regolazioni locali, plenum commerciali e post-riscaldamento.

## 10. Criteri di accettazione

- nessuna perdita percepibile o misurabile sui giunti;
- nessun sibilo localizzato in funzionamento normale o boost;
- bocchettoni stabili e senza gioco significativo;
- attraversamenti sonde ermetici;
- quattro temperature di processo misurate direttamente nel flusso;
- T garage e T esterna chiaramente separate;
- baseline e misura finale confrontabili;
- coibentazione continua nei punti critici;
- portate terminali misurate, non dedotte dalle percentuali ventilatore;
- bilancio mandata/ripresa verificato strumentalmente.

## 11. Decisioni rinviate

- eventuale sostituzione del plenum con Zehnder/Tecnosystemi o altro sistema commerciale;
- necessità di serrande/regolatori sui rami;
- adattatori Ø75→Ø100/125 e nuove bocchette;
- soluzione definitiva elastomero/lana di roccia e relativo spessore;
- necessità di post-riscaldamento;
- eventuali ulteriori punti temperatura.

## 12. Dati da non trattare come fatti

- stime non misurate di perdite in °C, W, kWh/anno o euro;
- presunta equivalenza prestazionale con sistemi Zehnder;
- regola dei 5 diametri applicata al tratto da 68 cm: per DN160, 5D = 800 mm;
- portate stanza per stanza non approvate;
- diametri di diaframma esplorativi;
- tempi di cura del sigillante senza scheda tecnica del prodotto;
- necessità automatica di bocchette Ø125.

## 13. Registro fonti e assorbimento chat

| Chat | Contenuto trasferito | Stato previsto dopo verifica |
| --- | --- | --- |
| M07 VMC | geometria rete, volumi, velocità nominali, rami, priorità plenum prima delle bocchette | archiviabile |
| M12 VMC | perdite verificate, butilico, sonde, baseline, coibentazione | archiviabile |
| M14 VMC | giunti bocchettoni, rivetti, sigillatura, test rumore/boost | archiviabile |
| M18 VMC | nessuna chat reale verificata; riga portfolio in collisione con M18 Neff | correggere portfolio, non usare come fonte |

## 14. Next action unica

Eseguire un rilievo fotografico finale dei due plenum e misurare OD tubo DN75, ID bocchettoni e spessori delle lamiere; completare rinforzo/sigillatura e installazione sonde prima di chiudere con nastro e acquisire la baseline pre-coibentazione.

