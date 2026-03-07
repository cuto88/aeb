# STEP31 - VMC boost hardening - 2026-03-07

## Contesto
Segnalazione runtime: chiamata `vel3` non attesa lato bagno e notifiche Telegram mancanti.

## Modifiche applicate
- Hardening trigger boost bagno automatico:
  - trigger su UR bagno invariato (`vmc_bagno_on`/`vmc_bagno_off`)
  - trigger su delta UR reso opzionale con toggle dedicato:
    - `input_boolean.vmc_bagno_delta_trigger_enable` (default `off`)
    - soglia `input_number.vmc_bagno_delta_ur_on`
- Timeout boost bagno manuale:
  - `timer.vmc_boost_bagno_manual_timeout`
  - durata configurabile con `input_number.vmc_boost_manual_timeout_min`
  - auto-spegnimento `input_boolean.vmc_boost_bagno` a timer scaduto
- Notifica debug Telegram resa robusta (escaping contenuto) per evitare errori markdown parse.
- Guardrail igrometrico boost bagno:
  - boost automatico non parte con aria esterna piu` umida (`delta_ur` negativo)
  - boost automatico si rilascia se `delta_ur` diventa fortemente negativo (outside wetter)

## Obiettivo operativo
- Evitare richieste `VEL3` non intenzionali legate al solo delta UR.
- Evitare boost manuali lasciati accesi senza scadenza.
- Ripristinare affidabilita` del canale notifica debug.
