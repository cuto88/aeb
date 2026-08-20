# VMC Casa Mercurio — Intervento fisico canonico

## 1. Scopo e confini

Questo documento è la SSOT tecnica per il ripristino, la strumentazione e il collaudo fisico della VMC di Casa Mercurio.

- Owner operativo: chat M16.
- Logica Home Assistant/AEB: resta separata nella chat M29 e in `docs/logic/core/regole_core_logiche.md`.
- Sequenza vincolante: `rilievo → filtri → sigillatura → sensori → baseline → coibentazione → misura finale → bilanciamento → decisioni opzionali`.
- Fonti consolidate: M07 VMC, M12 VMC, M14 VMC, M15 VMC, M19 VMC, M33 VMC, M34 VMC, M38 VMC, M45 VMC.
- M18 VMC non è una fonte verificata: nel portfolio collide con la chat reale M18 sul piano induzione Neff.

## 2. Stato verificato dell'impianto

- VMC centralizzata a doppio flusso installata nel garage.
- Modello identificato dal manuale disponibile: **VMC Group RIS M9 22 HA BP 3 VEL EVO**.
- Plenum/collettori in lamiera zincata, non coibentati.
- Collegamento principale nominale DN160; distribuzione radiale nominale DN75.
- Configurazione dichiarata per ciascun circuito: `1×DN160 ↔ 6×DN75`, da confermare fisicamente.
- Condotti verso l'esterno DN160 in PVC, non coibentati.
- VMC montata verticalmente.
- Tratto VMC–plenum flessibile e coibentato: circa 67,5 cm, arrotondato a 68 cm.
- Presa/rinnovo esterna: sviluppo riportato circa 2,20 m.
- Espulsione: sviluppo riportato circa 1,33 m, con due curve a 90°.
- Distanza attuale tra presa ed espulsione sulla stessa parete: circa 0,60 m; l'eventuale ricircolo non è misurato.
- Distanza riportata tra VMC e curva immediatamente adiacente: circa 13,5 cm.
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

## 7. Filtri

- Il manuale disponibile non fornisce dimensioni fisiche utilizzabili né un codice ricambio certo.
- Non acquistare filtri prima del rilievo fisico.
- Estrarre e censire separatamente ogni filtro: larghezza, altezza, spessore, classe, produttore/codice, direzione del flusso e fotografie di fronte, retro, telaio ed etichette.
- Non assumere che i filtri presenti siano identici.
- Lo spessore di circa 22 mm è solo un ricordo da verificare, non una quota consolidata.
- Formati standard ipotizzati, classi F7/G4 o ePM1/ISO Coarse e periodicità 3–6 mesi non sono specifiche verificate dell'impianto.
- Confrontare OEM e compatibili solo dopo il rilievo, verificando montaggio, tenuta e perdita di carico; non aumentare arbitrariamente la classe filtrante.
- Esito atteso: riferimento di ricambio ripetibile, registrato senza dover riaprire la ricerca.

## 8. Ripristino dei plenum

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

## 9. Coibentazione

- Coibentare solo dopo ripristino della tenuta e acquisizione della baseline pre-coibentazione.
- Priorità ai condotti DN160 verso l'esterno e ai plenum metallici nel garage.
- Soluzione preferenziale da verificare: elastomero espanso a celle chiuse tipo Armaflex/K-Flex/Kaiflex.
- Spessore di riferimento discusso: 19 mm; 13 mm minimo valutato; 25 mm dove spazio e convenienza lo consentono.
- Lana di roccia: candidato alternativo per i plenum, da definire dopo rilievo; nessuna fibra deve essere esposta al flusso e serve una finitura/barriera compatibile con il rischio di condensa.
- L'isolante per cassonetti Fortlan-Dibi non è la soluzione primaria.

## 10. Terminali esterni DN160

- Prima di modificare presa o espulsione, completare rilievo, baseline, coibentazione, misura finale e bilanciamento.
- Confrontare soltanto dopo le misure: configurazione attuale; traslazione della presa di circa 2 m sulla facciata; prosecuzione della presa in copertura.
- La variante in copertura aggiungerebbe indicativamente due curve a 90° e richiederebbe un sostegno indipendente del tratto DN160 libero; una quota ipotetica di circa 50 cm sopra il manto non è una specifica approvata.
- Non spostare la VMC solo per accorciare i condotti e non acquistare ora silenziatori, terminali, plenum esterni o passaggi DN160→DN200.
- Un eventuale intervento deve dimostrare beneficio su ricircolo, perdita di carico, rumore, condensa e manutenzione senza scaricare peso o vento sull'attraversamento della copertura.

## 11. Raccordi terminali stampati 3D

- Esistono due nodi distinti: Caso A con condotto arretrato che non raggiunge la bocchetta; Caso B con prolunga esistente ancora troppo corta.
- Conservare le bocchette commerciali e la loro flangia; stampare soltanto il raccordo interno invisibile, con geometria specifica per ciascun caso.
- Quote riportate per il Caso A: 69 mm, 63 mm e 47 mm, ancora da associare con certezza alle superfici e verificare al calibro.
- Il prototipo `VMC75_CASE_A_boccola69_to_bocchetta63.stl` e le quote derivate — innesti 25 mm, tolleranza 0,3 mm, parete 2,3 mm, lunghezza 97 mm — non sono definitive.
- Materiale candidato: PETG. Guarnizione, O-ring o butile vanno scelti solo dopo test-fit e prova di tenuta.
- Salvo perdita reale che comprometta le misure, gli adattatori restano successivi al bilanciamento.

## 12. Trasferimento aria attraverso le porte

- Le porte interessate sono tamburate e prive di griglie o fori dedicati.
- Durante il rilievo censire, per ogni porta del percorso mandata→ripresa, larghezza dell'anta e luce libera sottoporta.
- Prima del bilanciamento associare la portata da trasferire, calcolare la sezione necessaria e verificare il comportamento a porte chiuse.
- Preferire il sottoporta quando sufficiente e acusticamente accettabile; usare una griglia acustica/labirintica solo dove necessario.
- Non applicare quote standard di 10–15 mm e non realizzare fori Ø30–40 mm senza dimensionamento.
- Il bilanciamento finale deve avvenire con porte e passaggi nella configurazione definitiva, verificando assenza di sibili, pressioni anomale e degrado acustico evitabile.

## 13. Hood anemometrico

- Strumento disponibile: HP-856A.
- Primo prototipo: HDPE, bocca 200×200 mm, uscita Ø61 mm e bordo morbido comprimibile per la tenuta.
- Validare il prototipo con almeno cinque misure consecutive sulla stessa bocchetta, a condizioni costanti.
- Criterio operativo di ripetibilità: dispersione indicativamente entro ±5%; non equivale ad accuratezza metrologica certificata.
- Baseline, misura finale e bilanciamento devono usare lo stesso hood, lo stesso strumento e la stessa procedura.
- Verificare compatibilità con tutte le bocchette, posizione ripetibile dell'anemometro, assenza di bypass e possibile distorsione della transizione prima di accettare i risultati.

## 14. Gate post-riscaldamento

- Non installare né dimensionare ora un post-riscaldatore: nessun deficit di temperatura o comfort è stato dimostrato.
- Dopo ripristino, coibentazione, misura finale e bilanciamento, acquisire in condizioni invernali significative per almeno 24 h: T esterna, T estrazione, T mandata e portata reale.
- Eseguire un GO/NO-GO; solo in caso di problema residuo misurato definire temperatura obiettivo, salto termico, potenza e tecnologia.
- Nessuna batteria elettrica/ad acqua, resistenza, relè o SSR entra ora nella distinta materiali.
- Efficienza del recuperatore al 90%, benefici energetici automatici e riduzione certa del carico della pompa di calore non sono fatti verificati.

## 15. Procedura operativa canonica

1. Ispezionare e documentare plenum, condotti, innesti, terminali esterni e porte interne.
2. Estrarre, misurare e identificare separatamente i filtri; manutenere o sostituire solo dopo il rilievo.
3. Completare rinforzo e sigillatura dei plenum.
4. Installare le sei sonde e sigillare gli attraversamenti.
5. Testare a velocità normale e boost: perdite, vibrazioni, sibili e stabilità meccanica.
6. Validare l'hood anemometrico e acquisire baseline pre-coibentazione.
7. Coibentare DN160 e plenum.
8. Ripetere le misure nelle stesse condizioni operative.
9. Dimensionare e stabilizzare i trasferimenti interni con porte chiuse.
10. Misurare le portate dei terminali e bilanciare mandata/ripresa.
11. Solo dopo rivalutare raccordi terminali, posizione presa/espulsione, silenziatori, plenum commerciali e post-riscaldamento.

## 16. Criteri di accettazione

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
- filtri identificati con L×H×S, classe, codice e documentazione fotografica;
- hood validato con cinque misure ripetute e dispersione operativa indicativamente entro ±5%;
- portate finali misurate con porte chiuse e passaggi di trasferimento stabilizzati;
- nessun acquisto o modifica opzionale privo di un problema misurato e di un confronto prima/dopo.

## 17. Decisioni rinviate

- eventuale sostituzione del plenum con Zehnder/Tecnosystemi o altro sistema commerciale;
- necessità di serrande/regolatori sui rami;
- adattatori Ø75→Ø100/125 e nuove bocchette;
- soluzione definitiva elastomero/lana di roccia e relativo spessore;
- necessità di post-riscaldamento;
- eventuali ulteriori punti temperatura.
- ricambio filtro OEM/compatibile e periodicità definitiva;
- spostamento della presa, passaggio in copertura, silenziatori e nuovi terminali esterni;
- geometria definitiva dei due raccordi terminali stampati;
- interventi sottoporta o griglie acustiche porta per porta.

## 18. Dati da non trattare come fatti

- stime non misurate di perdite in °C, W, kWh/anno o euro;
- presunta equivalenza prestazionale con sistemi Zehnder;
- regola dei 5 diametri applicata al tratto da 68 cm: per DN160, 5D = 800 mm;
- portate stanza per stanza non approvate;
- diametri di diaframma esplorativi;
- tempi di cura del sigillante senza scheda tecnica del prodotto;
- necessità automatica di bocchette Ø125.
- filtro spesso 22 mm, formati commerciali ipotizzati e classi F7/G4 o equivalenti;
- ricircolo significativo dovuto ai 60 cm tra presa ed espulsione;
- quote 69/63/47 mm e parametri dello STL come geometria esecutiva;
- sottoporta standard 10–15 mm o fori porta Ø30–40 mm;
- ±5% come accuratezza certificata dell'hood;
- necessità o potenza del post-riscaldamento.

## 19. Registro fonti e assorbimento chat

| Chat | Contenuto trasferito | Stato previsto dopo verifica |
| --- | --- | --- |
| M07 VMC | geometria rete, volumi, velocità nominali, rami, priorità plenum prima delle bocchette | archiviabile |
| M12 VMC | perdite verificate, butilico, sonde, baseline, coibentazione | archiviabile |
| M14 VMC | giunti bocchettoni, rivetti, sigillatura, test rumore/boost | archiviabile |
| M15 VMC | modello macchina, gate acquisto filtri, rilievo L×H×S/classe/codice/foto | archiviabile dopo merge |
| M19 VMC | due raccordi terminali 3D, quote preliminari Caso A, test-fit e tenuta | archiviabile dopo merge |
| M33 VMC | gate strumentale GO/NO-GO per post-riscaldamento | archiviabile dopo merge |
| M34 VMC | geometria presa/espulsione, alternative e gate misurato prima delle modifiche | archiviabile dopo merge |
| M38 VMC | dimensionamento trasferimenti aria e verifica a porte chiuse | archiviabile dopo merge |
| M45 VMC | hood 200×200→Ø61, protocollo di ripetibilità e uso comparativo | archiviabile dopo merge |
| M18 VMC | nessuna chat reale verificata; riga portfolio in collisione con M18 Neff | correggere portfolio, non usare come fonte |

## 20. Next action unica

Eseguire un unico rilievo fisico: estrarre e censire separatamente i filtri con L×H×S/classe/codice/foto; fotografare i due plenum e misurare OD tubo DN75, ID bocchettoni e spessori; rilevare geometria dei terminali esterni, quote reali dei due raccordi a parete e larghezza/luce sottoporta. Poi completare rinforzo/sigillatura e installazione sonde prima di chiudere con nastro e acquisire la baseline.
