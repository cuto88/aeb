# STEP116 - VMC vel_2 comfort/energy delta audit (2026-05-22)

## Scope
- Verificare se `vel_2` con `P1_delta_ur` sta producendo un beneficio di comfort misurabile, oppure solo consumo energetico extra.
- Nessun cambio di logica funzionale.
- Nessun tuning applicato da questo step.

## FACT

- `vel_2` e` reale e non e` un livello finto:
  - audit storico di riferimento: `STEP84_VMC_SPEED2_RUNTIME_AUDIT_2026-04-27.md`
  - firma di potenza distinta rispetto a `vel_1` (ordine di grandezza ~`26 W` vs ~`70-73 W`)
- La policy `P1_delta_ur` e` la causa documentata della permanenza su `vel_2`:
  - `STEP85_VMC_P1_DELTA_UR_TUNING_AUDIT_2026-04-27.md`
- Nei campioni giornalieri piu` recenti:
  - `2026-05-18`: `sensor.vmc_active_speed_proxy = 1`
  - `2026-05-19`: `sensor.vmc_active_speed_proxy = 3`, `sensor.climateops_hierarchy_reason = PRIORITY_VENT_BOOST`
  - `2026-05-20`: `sensor.vmc_active_speed_proxy = 1`
  - `2026-05-21`: `sensor.vmc_active_speed_proxy = 1`
  - `2026-05-22`: `sensor.vmc_active_speed_proxy = 1`
- Nei medesimi campioni il quadro di comfort visibile non mostra un miglioramento netto attribuibile al boost:
  - `sensor.envelope_recommended_action` resta `keep_closed`
  - `sensor.envelope_house_night_flush_potential` resta `none`
  - `sensor.envelope_house_passive_gain_state` resta `idle`
  - la stanza peggiore oscilla tra `notte2` e `bagno`
- La telemetry disponibile non include una misura IAQ/CO2 che permetta di chiudere un effetto comfort/aria interna con confidenza alta.
- Non c'e` un metering VMC dedicato nei campioni usati per questo micro-audit, quindi il costo energetico del boost resta dedotto dal verdetto storico su `vel_2`, non misurato qui in forma diretta.

## IPOTESI

- Confidenza alta: `vel_2` consuma di piu` di `vel_1`.
- Confidenza media: il boost su `P1_delta_ur` produce un beneficio reale quando la policy resta vera per molte ore.
- Confidenza medio-bassa: nei giorni osservati il beneficio marginale sul comfort e` visibile solo in modo indiretto e non abbastanza forte da giustificare un boost frequente senza ulteriore selettivita`.

## DECISIONE

- `vel_2` ha effetto fisico reale, quindi non e` da trattare come bug di attuazione.
- La parte non dimostrata e` il beneficio comfort netto rispetto al consumo extra nei giorni recenti.
- Il rischio operativo attuale non e` "VMC rotta", ma "policy troppo permissiva per le condizioni attuali".

## Conclusione operativa

1. `vel_2` funziona davvero.
2. Il costo energetico e` reale.
3. Il guadagno comfort non e` dimostrato abbastanza bene dai dati recenti.
4. Il prossimo miglior ROI, se vuoi ridurre spreco, e` il tuning della policy `P1_delta_ur`:
   - alzare soglie
   - introdurre isteresi
   - usare una misura IAQ reale appena disponibile

## Residuo

- Nessuna prova sufficiente per promuovere `vel_2` a comportamento sempre desiderabile.
- Nessuna prova sufficiente per dichiararlo inefficace.
- Serve un audit mirato sulla policy, non sui relè o sul writer.
