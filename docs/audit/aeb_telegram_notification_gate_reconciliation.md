# Riconciliazione AEB Telegram notification gate

Data: 2026-08-03.

## Contesto

La notification policy globale era gia` operativa nel runtime
`mercurio-edge` ed era versionata nel branch
`feat/aeb-telegram-notification-gate`, ma non era ancora presente su `main`.
Il runtime derivava dal commit feature `cf47588`, mentre `main` includeva le
Tranche dashboard 2B.2a-R1 e 2B.2b-R1 successive alla base della feature.

## Integrazione

Branch di lavoro: `reconcile/aeb-telegram-gate-main`.

Commit applicati in ordine:

1. `bed039f` - notification gate globale;
2. `b84ff49` - preservazione delle logiche hardware runtime;
3. `cf47588` - patch risultata vuota perche` i contenuti Observability da
   preservare erano gia` presenti sul main corrente.

Non sono state sostituite dashboard complete con versioni storiche. Il merge
automatico del primo cherry-pick ha mantenuto i contenuti correnti e importato
solo i delta non confliggenti.

## Contratto finale

- `input_boolean.aeb_telegram_notifications_enabled` e` definito una volta in
  `packages/notify_telegram.yaml`;
- `script.aeb_notify` e` l'unico gateway degli invii operativi AEB;
- i quattro helper legacy non sono definiti o letti dal codice attivo;
- il sender basso livello `script.telegram_ha_mercurio_send` e` chiamato
  soltanto dal gateway;
- il consenso torna su `off` dopo reload completo o riavvio per effetto di
  `initial: false`.

Helper rimossi:

- `input_boolean.climate_debug_telegram`;
- `input_boolean.vent_notifiche_attive`;
- `input_boolean.envelope_notify_enabled`;
- `input_boolean.domesticops_notify_enabled`.

## Chiamanti migrati

- Climate debug;
- Ventilazione;
- richiesta AC da VMC;
- Envelope: apertura/scuri e chiusura finestre;
- Domestic Ops;
- controllo ramo hardware AC, inclusa notifica di rientro.

## Dashboard

- Envelope: consenso globale, `Numero stanze schermate` e i due trend
  Passive House 24h;
- Observability: consenso globale e tutte le sezioni Contracts/diagnostiche
  introdotte nelle tranche precedenti;
- Domestic Ops: consenso globale nelle due posizioni operative;
- ECLSS: invariata rispetto alla 2B.2b-R1.

## Baseline

`docs/audit/baselines/2026-08-03_aeb_telegram_gate_main_reconcile/`
contiene le versioni `origin/main`, feature e runtime dei dodici file,
hash, matrici helper/chiamanti e invarianti dashboard.

## Separazione delle modifiche

- La modifica funzionale notification policy preesisteva nel runtime.
- Questa attivita` la riconcilia nella source of truth Git.
- La Tranche 2B.2b-R1 resta distinta: deduplicazione Passive House e
  trasferimento dei due trend.

## Deploy

Nessun deploy e` incluso nella riconciliazione. Il deploy richiede
autorizzazione separata dopo CI verde e un nuovo confronto repository/runtime.
