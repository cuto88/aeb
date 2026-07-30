# AEB Digital Twin Data Layer

Questa cartella contiene il layer dati fisico e decisionale di Casa Mercurio.

Obiettivo: trasformare informazioni disperse tra repo, Home Assistant, Dropbox e chat tecniche in una fonte di verita` riusabile da AEB, automazioni, audit, simulazioni e futuri agenti.

La specifica semantica di riferimento e`:

- `docs/specifications/AEB_Digital_Twin_Spec_v1.md`

La specifica e` attualmente in stato **Draft**. I file v0 restano validi come input legacy-compatible e saranno migrati in modo incrementale, senza modifiche distruttive o perdita di provenienza.

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

## Target evolutivo

La struttura prevista dalla specifica separa progressivamente:

- edificio e spazi;
- asset e componenti installati;
- sensori, attuatori ed entita` runtime;
- documenti ed evidenze;
- relazioni;
- decisioni, manutenzioni, incidenti e misure.

Il primo target applicativo dopo la specifica e` l'Asset Register, popolato da targhette e documentazione installata senza promuovere manuali multi-modello a prova del modello effettivo.

## Stato

Snapshot iniziale creato da memoria conversazionale, documentazione Dropbox e repo AEB. Non e` ancora un digital twin completo: e` il primo schema normalizzato per chiudere progressivamente i buchi informativi e costruire una Engineering Memory verificabile.
