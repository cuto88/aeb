# DomesticOps — handoff M09

Status: design handoff only; no runtime deploy.
Owner project: 3_MERCURIO.
Target repository: `cuto88/aeb`.

## Objective

Ridurre attrito operativo e prelievo elettrico della gestione domestica usando Home Assistant come orchestratore per lavastoviglie, lavatrice, asciugatura bucato, pulizia bagno e rifiuti, riutilizzando entità FV/meteo già esistenti.

## Decisions already taken

- Carichi differibili (lavastoviglie, lavatrice, asciugatrice) vanno favoriti nella finestra solare/FV, senza inseguire il surplus perfetto.
- Lavastoviglie: caricata dopo cena, avvio consigliato nel giorno successivo in fascia solare, idealmente circa 10:30–16:00.
- Lavatrice: pochi profili semplici; favorire 30–40 °C per uso normale e 60 °C per asciugamani/lenzuola quando necessario; evitare micro-carichi.
- Asciugatura: default esterno quando meteo favorevole; asciugatrice come fallback o completamento, preferibilmente con surplus FV.
- Nessun avvio automatico di elettrodomestici nell'MVP: solo advisory/notifiche fino a validazione hardware e affidabilità.
- Non modificare ClimateOps, VMC, heating o AC per introdurre DomesticOps.

## Laundry Decision Engine

Output logico previsto:

- `stendi_fuori`
- `asciugatrice_fv`
- `attendi`
- `rientra_e_completa_asciugatrice`
- `rischio_pioggia`
- `rischio_umidita`

Segnali da riutilizzare se disponibili:

- temperatura esterna;
- umidità relativa esterna;
- vento;
- pioggia corrente e forecast 3–4 h;
- tramonto;
- produzione FV / surplus FV;
- eventuali smart plug o sensori stato per lavatrice, lavastoviglie e asciugatrice.

Indicazioni iniziali da trattare come soglie configurabili e non come valori canonici finché non validate sul runtime:

- asciugatura esterna favorita con UR relativamente bassa, temperatura sufficiente, vento utile e nessuna pioggia prevista;
- warning rientro quando UR cresce, pioggia è probabile o il tramonto si avvicina;
- asciugatrice favorita se condizioni esterne sono sfavorevoli e il surplus FV è disponibile.

## Domestic routines

Routine da includere nello stesso modulo solo come reminder a basso attrito:

- lavastoviglie: carico serale + advisory avvio in fascia FV;
- lavatrice: advisory quando esiste uno slot energetico buono;
- bagno: reminder 1 volta/settimana;
- rifiuti/check domestico: reminder settimanale;
- opzionale: reminder mattutino svuotamento lavastoviglie.

## Implementation gate

Prima di creare `packages/domestic_ops.yaml`, eseguire un evidence gate read-only nel repo/runtime AEB:

1. cercare `domestic_ops`, `laundry`, `lavatrice`, `lavastoviglie`, `asciugatrice`, `rifiuti`, `dishwasher`, `washing_machine`;
2. mappare helper, sensori, automazioni e notifiche già presenti;
3. identificare le entità reali per FV, meteo, sun e appliance;
4. evitare duplicati e riusare i sensori canonici esistenti;
5. classificare il risultato come:
   - A) già presente → nessuna nuova implementazione;
   - B) parziale → integrare solo i gap;
   - C) assente → creare MVP dedicato.

## MVP target if gap is confirmed

File preferito: `packages/domestic_ops.yaml`.

Caratteristiche:

- naming `domesticops_*`;
- helper per soglie modificabili;
- mapping entità esplicito;
- template sensor per advisory;
- notifiche operative disattivabili;
- degrado sicuro quando un sensore non è disponibile;
- nessun custom component;
- nessun blueprint;
- nessun comando automatico agli elettrodomestici nell'MVP;
- un solo package, salvo evidenza tecnica che richieda separazione.

## Pre-mortem minimo

| Failure mode | Segnale precoce | Contromisura minima |
|---|---|---|
| Duplicazione di logiche già esistenti | sensori/helper equivalenti già in repo | evidence gate prima di scrivere |
| Notifiche rumorose | advisory ripetuti/non azionabili | cooldown + notify enable + una sola notifica utile |
| Soglie meteo rigide | consigli sbagliati in giornate reali | helper configurabili + tuning da storico |
| Dipendenza da entità instabili | `unknown/unavailable` nei template | default sicuri e availability esplicita |
| Over-engineering | più file/servizi prima del primo test | MVP in un package, advisory only |

## Runtime / provenance

- Macchina operativa usata per questo handoff: ChatGPT con GitHub connector.
- Runtime target: Home Assistant su `mercurio-edge`, non modificato.
- Accesso runtime usato: nessuno.
- Deploy eseguito: no.
- Modifiche runtime eseguite: no.
- Modifica SSOT remota: sì, documentazione in repository `cuto88/aeb`.

## Next action when this workstream is resumed

Eseguire l'evidence gate read-only su repo/runtime AEB. Solo se il gap è confermato, implementare e validare l'MVP `packages/domestic_ops.yaml`.
