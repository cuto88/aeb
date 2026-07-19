# ADR-HA-DASH-001 - Governance delle dashboard Home Assistant

- Stato: Accepted; Tranche 1 e Tranche 2A implementate, Tranche 2B-3 proposte
- Data: 2026-07-19
- Ambito: dashboard YAML Lovelace del repository AEB

## Problema

Le dashboard coprono adeguatamente i domini della casa, ma nel tempo overview, drill-down, diagnostica, raw fieldbus e tuning hanno accumulato sovrapposizioni. La navigazione tra superfici era quasi assente, due dashboard legacy restavano registrate e una registrazione puntava a un file inesistente. Parte della documentazione descriveva ID e visibilita` non piu` correnti.

La razionalizzazione deve preservare la SSOT delle entita` e delle logiche. Le dashboard sono viste e controlli: non devono diventare una seconda fonte per soglie, decision tree o mapping runtime.

## Stato attuale

La tassonomia corrente comprende:

- `1 ECLSS Casa`: overview cross-domain, ClimateOps, AEB e sintesi Passive House;
- `2 Air Loop`, `3 Heating Loop`, `4 Cooling Loop`: drill-down clima;
- `5 PV Array`, `6 Power Runtime`: energia;
- `7 DHW / ACS`, `8 MIRAI Plant`: macchine;
- `9 Fieldbus`: raw/forensic;
- `10 Envelope`: building physics;
- `11 Observability`: health e fault board;
- `12 Domestic Ops`: operazioni domestiche.

I file legacy sono conservati in `lovelace/_archive/legacy_dashboards/` e non sono registrati. La registrazione `0-lovelace` e` stata rimossa perche` il target `ui-lovelace.yaml` non esiste e nessuna governance corrente le attribuisce un ruolo.

## Policy definitiva legacy

- Le dashboard operative YAML vivono direttamente sotto `lovelace/` e devono essere tutte registrate in `configuration.yaml`.
- Nessun YAML top-level puo` restare orfano, anche se non tracciato da Git.
- Le dashboard storiche vivono sotto `lovelace/_archive/` e non possono essere registrate come dashboard operative.
- Le baseline vivono sotto `lovelace/_baseline/` e non possono essere registrate.
- I file archivio non ricevono evoluzioni funzionali; possono essere letti da gate comparativi, audit o procedure di rollback.
- Il gate VMC usa `lovelace/_archive/legacy_dashboards/02_air_loop_legacy.yaml` esclusivamente come contratto storico dei quattro indicatori condivisi. Questo confronto non implica registrazione, deploy o ownership operativa del legacy.
- Gli archivi VMC e AC devono restare byte-identici alla baseline `2026-07-19_dashboard_pre_refactor`, salvo una nuova ADR che autorizzi esplicitamente un aggiornamento storico.

## Ruoli target

| Livello | Dashboard | Responsabilita` |
|---|---|---|
| Overview | ECLSS | stato sintetico, reason dominante, attuazione, fault e navigazione |
| Domain | Air Loop, Heating, Cooling, Envelope, Domestic Ops | stato semantico, controlli e trend del dominio |
| Energy/machine | PV, Power Runtime, DHW, MIRAI | fonte energetica, sintesi consumi e stato macchina |
| Observability | Observability | readiness, fault, contratti, unavailable, debug e gap |
| Fieldbus | Fieldbus | registri raw, mapping, link e forensic bus |
| Historical | legacy VMC/AC, Step7 | confronto e rollback, senza registrazione attiva |

## Ownership

- Le logiche e le soglie appartengono ai package e alla documentazione core/modulo, non alle card.
- ECLSS possiede la sintesi cross-domain e non la diagnostica completa.
- Ogni dashboard di dominio possiede comandi, stato semantico e trend del proprio dominio.
- Observability possiede health, fault, missing entity, debug e rischi di telemetria.
- Fieldbus possiede registri, segnali raw e mapping basso livello.
- I file legacy non sono entrypoint e non devono ricevere evoluzioni funzionali.
- Ogni card ha un solo owner primario anche quando mostra entita` condivise.
- Le card `state` e `command` restano nel dominio che prende o presenta la decisione operativa.
- Le card `trend` restano nel dominio quando spiegano il comportamento; i trend cross-domain possono restare nell'overview.
- Le card `tuning` restano nel dominio, in viste o sezioni chiaramente tecniche.
- Le card `diagnostic` appartengono a Observability quando descrivono health, readiness, contratti, fallback o mapping trasversali.
- Le card `raw` appartengono a Fieldbus quando espongono registri, probe, snapshot o valori di trasporto; raw non-fieldbus appartiene a Observability.
- Il censimento normativo per la Tranche 2B e` `docs/audit/ha_dashboard_card_ownership.md`.

## Regole sulla duplicazione

Una stessa entita` puo` essere mostrata in piu` dashboard quando cambia lo scopo:

- indicatore sintetico nell'overview;
- dettaglio e contesto nel dominio;
- stato di salute in Observability;
- evidenza raw in Fieldbus.

Non sono ammesse duplicazioni di interi blocchi raw, tuning o forensic fuori dal proprietario. Le soglie numeriche non devono essere replicate in Markdown se esistono helper o documenti SSOT. Ogni duplicazione mantenuta deve avere una motivazione osservabile.

## Separazione overview, domain, observability e fieldbus

- Overview risponde a: cosa sta succedendo e dove devo entrare.
- Domain risponde a: perche` il dominio sta agendo e quali controlli sono ammessi.
- Observability risponde a: quali contratti, sensori o attuatori sono degradati.
- Fieldbus risponde a: cosa espone realmente il trasporto o registro raw.

I link devono seguire questa direzione: overview verso domain; sintesi energia/macchina verso raw; Observability verso il dominio interessato. Non si usano dashboard legacy come destinazioni.

## Piano in tre tranche

### Tranche 1 - struttura a basso rischio

- baseline completa;
- rimozione registrazioni orfane e legacy;
- navigazione esplicita;
- audit e ADR;
- riallineamento dei riferimenti documentali chiaramente obsoleti.

Nessuno spostamento di card, cambio entity ID o modifica runtime.

### Tranche 2A - policy e ownership

- archiviare i legacy fuori dal top-level;
- rendere vincolante la regola top-level registrato / archive non registrato;
- preservare il confronto VMC sul riferimento storico;
- censire l'ownership di ogni sezione e card;
- non modificare card operative, entity ID o navigation path.

### Tranche 2B - ownership dei contenuti

- classificare ogni card come overview, domain, observability o fieldbus;
- ridurre ECLSS a indicatori sintetici e link;
- spostare raw MIRAI/EHW in Fieldbus;
- spostare debug/legacy Heating e diagnostica trasversale in Observability;
- ridurre la vista Passive House a sintesi, lasciando il dettaglio a Envelope;
- sostituire soglie narrative duplicate con riferimenti alla SSOT.

Ogni spostamento deve preservare il controllo operatore e avere confronto visuale prima/dopo.

## Criteri di ingresso alla Tranche 2B

- gate Lovelace e gate VMC verdi;
- 12 dashboard top-level registrate e nessun orfano;
- nessun file sotto `_archive` o `_baseline` registrato;
- hash dei due legacy uguali alla baseline 2026-07-19;
- parsing YAML completo riuscito;
- entity ID e navigation path invariati rispetto alla Tranche 1;
- censimento `ha_dashboard_card_ownership.md` completo e revisionato;
- lista delle card `move` approvata prima di modificare il layout;
- destinazione e posizione di ogni card definite, evitando duplicati temporanei non dichiarati;
- piano di rollback per singola dashboard e confronto visuale mobile/desktop predisposti;
- worktree estraneo identificato e preservato;
- nessun deploy incluso implicitamente nella modifica sorgente.

### Tranche 3 - uniformita` e chiusura

- uniformare il pattern Stato/Comandi, KPI, Trend/Diagnostica;
- aggiungere i riferimenti logici richiesti dalla governance;
- riesaminare card e risorse non usate;
- verificare navigazione mobile/desktop e runtime;
- aggiornare la documentazione di chiusura e dichiarare le duplicazioni intenzionali residue.

## Rollback

La baseline canonica pre-refactor e`:

`lovelace/_baseline/2026-07-19_dashboard_pre_refactor/`

Contiene i 14 file Lovelace top-level presenti prima della tranche 1 e `configuration.lovelace.yaml`, snapshot della sezione Lovelace di `configuration.yaml`. Il rollback consiste nel ripristino selettivo dei file dalla baseline e nella verifica YAML prima di qualsiasi deploy. Il rollback runtime non fa parte di questa tranche, perche` non e` stato eseguito alcun deploy.

## Criteri di accettazione

- tutti i file YAML sono validi;
- ogni `filename` registrato esiste;
- ogni `navigation_path` risolve a dashboard ID e view path esistenti;
- nessun collegamento punta alle registrazioni rimosse;
- i file legacy restano disponibili;
- nessun entity ID viene cambiato;
- automazioni, package, helper e ClimateOps restano invariati;
- nessuna card raw/debug viene spostata nella tranche 1;
- audit, ADR e documentazione corrente descrivono lo stato reale;
- quality gate locale eseguito, oppure eventuale blocco documentato;
- nessun deploy, modifica runtime o commit automatico.

## Decisioni della tranche 1

- `0-lovelace`: rimossa; registrazione orfana senza ruolo corrente.
- `92-vmc-legacy`, `94-ac-legacy`: rimosse da `configuration.yaml`; file preservati.
- Navigazione: aggiunta mediante card standard `button` e `tap_action: navigate` nelle superfici richieste.
- Struttura interna: invariata salvo l'aggiunta delle card di navigazione esplicitamente autorizzate.

## Validazione della tranche 1

- Parsing YAML con `yq`: PASS su 31 file, inclusa la baseline.
- Target `filename` registrati: PASS, tutti esistenti.
- `navigation_path`: PASS, 20 collegamenti risolti su 12 dashboard e 18 viste.
- Entity ID nei sei file Lovelace modificati: invariati rispetto alla baseline.
- File legacy: preservati e byte-identici alla baseline.
- Gate naming, CM naming, nested template, policy sensori AC notte, link documentali e artifact policy: PASS.
- Gate aggregato `ops/gates_run_ci.ps1`: FAIL nel gate Lovelace perche` la policy corrente considera orfani i due file legacy top-level non piu` registrati. Il gate non e` stato modificato per mascherare il conflitto; la collocazione definitiva dei legacy deve essere decisa separatamente.
- `yamllint`: non eseguibile perche` il comando non e` installato nell'ambiente; la validita` sintattica e` stata comunque verificata con `yq`.

## Decisioni della Tranche 2A

- I legacy VMC e AC sono stati spostati in `lovelace/_archive/legacy_dashboards/` senza variazioni di contenuto.
- Il gate Lovelace enumera il filesystem top-level, richiede che ogni YAML sia registrato e rifiuta registrazioni sotto `_archive` o `_baseline`.
- Il gate VMC confronta la dashboard corrente con il legacy archiviato senza richiederne la registrazione.
- Nessuna card operativa, entity ID o navigation path e` stata modificata.
- La classificazione completa e le decisioni candidate per la 2B sono in `docs/audit/ha_dashboard_card_ownership.md`.

## Validazione della Tranche 2A

- Parsing con `yq`: PASS su 31 YAML, inclusi archive e baseline.
- Gate Lovelace: PASS, `Active=12`, `TopLevel=12`.
- Gate VMC: PASS sul legacy archiviato e sulla dashboard corrente.
- Hash SHA-256 dei legacy: identici alla baseline 2026-07-19.
- Registrazioni archive/baseline: nessuna.
- Entity ID: invariati per tutte le 12 dashboard rispetto alla baseline.
- Link documentali: PASS.
- `git diff --check` sul perimetro Tranche 2A: PASS.
- `yamllint 1.38.0` e `ops/gates_run_ci.ps1`: PASS.

## Provenienza operativa

- Macchina operativa: workspace locale Windows `C:\2_OPS\aeb`.
- Runtime target: `mercurio-edge` / Home Assistant Docker, non toccato.
- Macchina legacy: non contattata.
- Modalita` di accesso: filesystem locale.
- Deploy: no.
- Modifiche runtime: no.
- Commit o GitHub Actions: nessuno.
