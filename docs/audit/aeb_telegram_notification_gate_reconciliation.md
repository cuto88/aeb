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

Il deploy consolidato e` stato eseguito il 2026-08-03 da
`4d411c55574de44992fdf8a047238da405b667c3`, dopo il successo del workflow
Quality Gates `30831956812`.

Target operativo:

- host `mercurio-edge` (`192.168.178.110`);
- accesso LAN/SSH come `dscomparin`;
- container `homeassistant`;
- bind mount `/opt/data/homeassistant` -> `/config`;
- macchina legacy non contattata.

Backup verificato:
`/config/backups/aeb_consolidated_deploy_20260803_20260803_184014/`.

Il backup contiene gli otto package e le quattro dashboard del perimetro,
gli hash pre-deploy e il manifest di rollback. Il confronto iniziale ha
mostrato dieci file gia` allineati; sono stati quindi copiati soltanto:

- `lovelace/01_eclss_casa.yaml`;
- `lovelace/10_envelope.yaml`.

Gli hash SHA-256 runtime finali sono:

| File | SHA-256 |
|---|---|
| `packages/notify_telegram.yaml` | `931e8ba7af0f6ad8e4e55240b3845206deb04b5a9d80f2d6753dc2ebc832ea75` |
| `packages/climate_sensors.yaml` | `c04b21ea034009a237c5d57fdb2e1638eefef9730fb7ba403333c9a8e886f492` |
| `packages/climate_ventilation_helpers.yaml` | `b0bb7d9b230ecc65d74571047566e83f40d0c3bc78acc8e55ee4addafa0a2fd2` |
| `packages/climate_ventilation.yaml` | `59f4f9263c6a58b0ccf9a6b81b0f8a38f93e8f1acdf170dcbf43104347b785d1` |
| `packages/climate_ac_logic.yaml` | `7e56f8357bc941be82e6c860ce1ebf8deceddd2f8ab0d16e2827670441e8404f` |
| `packages/envelope_room_advisory.yaml` | `ebb7734b6f1fe3d65d78250179a1e493c7bfebdf7544f4226b335442a7850fd8` |
| `packages/domestic_ops.yaml` | `7b51105fa0486fd3bd570eaf08ccc55318583375563c3e3ffd725b3a8a1be9c2` |
| `packages/climate_hardware_branch_control.yaml` | `932c62c8f761f0963780f11d705d183cced2af3d377971991230caf05d7e832c` |
| `lovelace/01_eclss_casa.yaml` | `d03cf2a97b5c9e04e61d897e4eef6a2b551c6f97c4a1ba5ef228dd5762adeff9` |
| `lovelace/10_envelope.yaml` | `3ebba76437aca79dbd71d5ce903f51197b96214661cd05a7ed28e1a97038de92` |
| `lovelace/11_observability.yaml` | `908237598ff3193dc99aaf439b28ec0aa9bfadc98fc6835d6b086218be295f89` |
| `lovelace/12_domestic_ops.yaml` | `0b2dfb179989b67f96e6c168776b4945aa758a2abd499d9bd6ce339eb350743b` |

## Verifica operativa

- parsing YAML dei dodici file: PASS;
- `python -m homeassistant --script check_config -c /config`: PASS;
- restart controllato del solo container `homeassistant`: PASS;
- container dopo il restart: `running`, HTTP `200`, nessun restart loop;
- `input_boolean.aeb_telegram_notifications_enabled`: disponibile e
  ripristinato su `off`;
- `script.aeb_notify`: operativo;
- quattro helper legacy: non piu` attivi;
- chiamanti migrati e preservazioni hardware: caricati;
- Lovelace desktop e mobile: PASS;
- regressioni introdotte: nessuna rilevata;
- rollback: non necessario.

Le anomalie osservate nei log su LocalTuya, Meross, Modbus e duplicati
`unique_id` erano preesistenti e non sono riconducibili al deploy
dashboard/notification gate.

## Test notification gate

FACT:

- main e runtime sono riallineati;
- il gateway globale e` operativo;
- con gate `off`, la chiamata di test e` terminata senza recapito;
- con gate `on`, una singola chiamata con messaggio
  `TEST AEB notification gate — 2026-08-03` ha prodotto esattamente una
  notifica Telegram, come confermato dall'utente;
- nessun doppio invio e nessun errore sono stati rilevati;
- il consenso globale e` stato ripristinato su `off`.

DECISIONE:

- la notification policy e` accettata come operativa;
- i quattro helper legacy sono dismessi;
- `script.aeb_notify` e` l'unico gateway AEB Telegram.

DELIVERED:

- deploy consolidato package/dashboard;
- backup e rollback file-per-file;
- restart controllato;
- verifica runtime;
- test funzionale Telegram;
- verifica Lovelace desktop e mobile.

NEXT ACTION:

- nessuna per questa tranche;
- eventuali evoluzioni delle notifiche devono essere aperte come task
  separato.

## Stato finale

- Stato: **DONE**
- Valutazione: **ARCHIVIABILE**
