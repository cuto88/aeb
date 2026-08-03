# Tranche 2B.2b-R1 — deduplicazione Passive House

Data operativa: 2026-08-03.

## Obiettivo

Consolidare in Envelope la sintesi Passive House gia` rappresentata e
trasferire i due trend mancanti, senza cambiare entity ID, template,
navigation path o logiche runtime.

## Baseline

Baseline pre-dedup:
`lovelace/_baseline/2026-08-03_dashboard_tranche_2b2b_r1_pre_dedup/`.

Contiene i due YAML originali, inventari entity ID/navigation/dashboard,
hash SHA-256, estratti delle card e matrice di equivalenza funzionale.

HEAD iniziale: `8a50458c63bd303e670fa75a17df9ef44b0a935c`.

## Deduplicazione della sintesi

| ECLSS rimossa | Owner mantenuto in Envelope | Classificazione |
|---|---|---|
| Stanza peggiore | Stanza peggiore | EQUIVALENTE |
| Rischio | Rischio peggiore | EQUIVALENTE_CON_DIFFERENZE_PRESENTATIVE |
| Scuri consigliati | Scuri consigliati | EQUIVALENTE |
| Candidabili raffrescamento notturno | Candidabili raffrescamento notturno | EQUIVALENTE |
| Stanze schermate | Stanze | EQUIVALENTE_CON_DIFFERENZE_PRESENTATIVE |

Nessuna coppia presenta differenze funzionali in azioni, visibility,
template, severity o soglie. Il colore rosso della card ECLSS `Rischio` e i
due titoli differenti sono attributi presentativi.

Il KPI count `sensor.envelope_shade_applied_rooms_count` resta distinto dalla
lista e viene visualizzato come `Numero stanze schermate`.

## Trend trasferiti

- `Involucro 24h`: ECLSS / Passive House -> Envelope / Trend.
- `Solare e scuri 24h`: ECLSS / Passive House -> Envelope / Trend.

I blocchi YAML sono stati trasferiti integralmente, conservando tipo, titolo,
intervallo, refresh, entity ID, ordine e nomi delle serie.

## File della tranche

- `lovelace/01_eclss_casa.yaml`
- `lovelace/10_envelope.yaml`
- `docs/audit/ha_dashboard_audit.md`
- `docs/audit/ha_dashboard_card_ownership.md`
- `docs/audit/ha_dashboard_tranche_2b2b_r1.md`
- baseline dedicata

## Invarianti e validazioni

- insieme globale degli entity ID invariato;
- navigation path invariati;
- 12 dashboard YAML registrate;
- nessuna modifica a Notte 2;
- nessuna modifica a package, automazioni, helper o configuration;
- cinque duplicati assenti da ECLSS;
- due trend presenti una sola volta in Envelope;
- configurazione strutturale dei trend invariata.

Gli esiti numerici dei gate, la pubblicazione, il deploy e la verifica visuale
sono riportati nel rapporto operativo finale della tranche dopo la conclusione
delle rispettive fasi.

## Riconciliazione notification policy

La policy Telegram globale e` stata riconciliata sul risultato 2B.2b-R1 senza
alterare sintesi, KPI, trend o navigation path. Envelope espone ora
`input_boolean.aeb_telegram_notifications_enabled`; i due trend e il nome
`Numero stanze schermate` restano invariati.

## Rischi e rollback

Il rischio e` limitato al layout Lovelace di ECLSS ed Envelope. Il rollback
consiste nel ripristino dei due YAML dalla baseline repository o dal backup
runtime timestamped creato prima del deploy.

## Chiusura operativa

Il deploy consolidato e` stato completato il 2026-08-03 dal commit
`4d411c55574de44992fdf8a047238da405b667c3`, dopo Quality Gates
`30831956812` concluso con esito positivo.

- repository: **DONE**;
- deploy: **DONE**;
- backup runtime:
  `/config/backups/aeb_consolidated_deploy_20260803_20260803_184014/`;
- file Lovelace effettivamente copiati:
  `lovelace/01_eclss_casa.yaml` e `lovelace/10_envelope.yaml`;
- `check_config`: **PASS**;
- restart controllato di `homeassistant`: **PASS**;
- verifica visuale desktop: **PASS**;
- verifica visuale mobile: **PASS**;
- cinque sintesi duplicate e due trend assenti da ECLSS: confermato;
- sintesi canoniche, KPI count e due trend presenti in Envelope: confermato;
- Observability e Domestic Ops preservate: confermato;
- 12 dashboard operative e 13 navigation path: confermati;
- entity ID Lovelace finali: 426, coerenti con la sostituzione dei quattro
  consensi legacy con il consenso globale;
- notification drift: riconciliato;
- consenso globale: operativo e ripristinato su `off`;
- test Telegram: gate OFF senza recapito; gate ON con una sola notifica
  ricevuta;
- regressioni introdotte: nessuna rilevata;
- rollback: non necessario.

Le anomalie runtime osservate su LocalTuya, Meross, Modbus e duplicati
`unique_id` sono preesistenti e restano fuori dal perimetro della tranche.

## Stato finale

- Stato: **DONE**
- Valutazione: **ARCHIVIABILE**
- Prossima azione: nessuna; eventuali evoluzioni appartengono a task
  separati.
