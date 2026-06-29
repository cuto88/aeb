# AEB Digital Twin Data Layer

Questa cartella contiene il layer dati fisico e decisionale di Casa Mercurio.

Obiettivo: trasformare informazioni disperse tra repo, Home Assistant e chat tecniche in una fonte di verita` riusabile da AEB, automazioni, audit, simulazioni e futuri agenti.

## Regole

1. Ogni dato deve avere stato di attendibilita`: `verified`, `documented`, `inferred`, `estimated`, `to_confirm`.
2. Ogni dato deve indicare fonte: repo, chat, misura, progetto, runtime HA, rilievo.
3. Ogni dato deve indicare almeno un possibile `used_by`.
4. Nessun file in `data/` e` runtime Home Assistant diretto finche` non viene creato un bridge esplicito.
5. Le decisioni progettuali vanno salvate insieme ai dati, non solo nei messaggi chat.

## File v0

- `building_core.yaml`: DNA edificio e contesto generale.
- `rooms.yaml`: geometria e zone note.
- `systems.yaml`: impianti e sottosistemi fisici.
- `sensors_actuators.yaml`: mappa sensori/attuatori fisici e logici.
- `open_questions.yaml`: dati mancanti, dubbi e conferme richieste.

## Stato

Snapshot iniziale creato da memoria conversazionale e repo AEB. Non e` ancora un digital twin completo: e` il primo schema normalizzato per iniziare a chiudere i buchi informativi.