# STEP110 - AEB supervisor bridge closure (2026-05-15)

Scope: chiusura del blocco operativo sul bridge host usato dal supervisore AEB da `n8n`.

## FACT

- Il bridge condiviso `n8n-bridge` risponde su `0.0.0.0:8787` sul host Windows.
- Dal container `lifeos_n8n` il bridge risponde correttamente su `http://host.docker.internal:8787`.
- L'endpoint AEB supervisor payload risponde correttamente:
  - `GET /aeb/supervisor/payload?max_audits=3`
- Il workflow supervisor AEB e' stato eseguito end-to-end con esito positivo dopo la correzione del bridge.
- La scrittura del report canonico e l'invio finale sono risultati `success`.
- Il launcher del bridge e' stato semplificato a un solo wrapper PowerShell canonico.
- L'autostart utente del bridge e' attivo, quindi il servizio torna su senza intervento manuale al login.

## VERIFICA

- Health host: `PASS`
- Health container: `PASS`
- Payload AEB: `PASS`
- Run supervisor end-to-end: `PASS`
- Report canonico aggiornato: `PASS`

## DECISIONE

- Blocco `AEB supervisor bridge`: `CLOSED`
- `n8n-bridge` e' il proprietario canonico del bridge host.
- Non servono altri launcher paralleli o documentazione di cutover aggiuntiva.

## RESIDUI

- Resta un conflitto separato del broker `n8n` sulla porta `5679` quando si usa il CLI runner standard.
- Il conflitto non blocca il workflow schedulato, ma e' da tenere presente per run manuali ad-hoc.
