# AEB Digital Twin Data Layer

Questa cartella contiene il layer dati fisico e decisionale di Casa Mercurio.

Obiettivo: trasformare informazioni disperse tra repo, Home Assistant, Dropbox e chat tecniche in una proiezione tecnica versionata del Digital Twin, riusabile da AEB, audit, simulazioni e futuri agenti. La SSOT Mercurio resta il registro trasversale cross-domain; questo layer e` la rappresentazione tecnica curata e versionata per AEB.

La specifica semantica di riferimento e`:

- `docs/specifications/AEB_Digital_Twin_Spec_v1.md`

La specifica v1 e` adottata come baseline del layer non-runtime. I file v0 restano validi come input legacy-compatible e saranno migrati in modo incrementale, senza modifiche distruttive o perdita di provenienza.

## Regole

1. Ogni dato deve avere stato di attendibilita`: `verified`, `measured`, `runtime_observed`, `documented`, `user_reported`, `inferred`, `estimated`, `to_confirm` oppure `unknown`.
2. Ogni dato materiale deve indicare una fonte o evidenza: repo, documento Dropbox, targhetta, foto, misura, progetto, runtime Home Assistant, rilievo o dichiarazione utente.
3. Ogni entita` di primo livello deve avere un identificatore stabile.
4. Ogni dato dovrebbe indicare almeno un possibile `used_by` o una relazione esplicita.
5. Nessun file in `data/` e` runtime Home Assistant diretto finche` non viene creato un bridge esplicito e revisionato.
6. Specifiche nominali, realta` installata, runtime osservato e dati derivati non devono essere confusi.
7. Le decisioni progettuali vanno salvate insieme a motivazioni, alternative ed evidenze, non solo nei messaggi chat.
8. I valori sconosciuti restano `null`, omessi oppure collegati a una domanda aperta: non devono essere inventati.

## File v0

- `building_core.yaml`: DNA edificio e contesto generale.
- `rooms.yaml`: geometria e zone note.
- `systems.yaml`: impianti e sottosistemi fisici.
- `sensors_actuators.yaml`: mappa sensori/attuatori fisici e logici.
- `open_questions.yaml`: dati mancanti, dubbi e conferme richieste.
- `assets.yaml`: Asset Register curato v1.
- `relationships.yaml`: relazioni curate tra entita` con provenance esplicita.

## Target evolutivo

La struttura prevista dalla specifica separa progressivamente:

- edificio e spazi;
- asset e componenti installati;
- sensori, attuatori ed entita` runtime;
- documenti ed evidenze;
- relazioni;
- decisioni, manutenzioni, incidenti e misure.

La baseline v1 comprende l'Asset Register e una prima relazione end-to-end. Le verifiche future aumentano l'evidence grade senza ritardare la baseline quando i dati sono gia` supportati da fonti coerenti.

## Stato

Baseline Digital Twin v1 non-runtime. Il dataset resta incrementale: i gap non bloccanti sono mantenuti in `open_questions.yaml`; nessun file in `data/` modifica direttamente il runtime Home Assistant.
