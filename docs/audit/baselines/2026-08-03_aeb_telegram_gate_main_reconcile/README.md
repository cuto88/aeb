# Baseline AEB Telegram gate / main reconcile

## Provenienza

- `main/`: `origin/main` a `eb74e9e24b8c0d3bdcc2d293ff5414cf420ea48b`.
- `feature/`: `origin/feat/aeb-telegram-notification-gate` a
  `cf475883bbb9f1c0bb23ce41b37cb7fa186c59ba`.
- `runtime/`: lettura SSH di `mercurio-edge:/config` prima della
  riconciliazione Git.

## Matrice file

| File | Main | Feature | Runtime | Risultato richiesto |
|---|---|---|---|---|
| `packages/notify_telegram.yaml` | gate legacy | gate globale | uguale feature | feature |
| `packages/climate_sensors.yaml` | helper climate legacy | helper rimosso | uguale feature | feature |
| `packages/climate_ventilation_helpers.yaml` | helper VMC legacy | helper rimosso | uguale feature | feature |
| `packages/climate_ventilation.yaml` | gate VMC locale | `script.aeb_notify` | uguale feature | feature |
| `packages/climate_ac_logic.yaml` | persistent notification | `script.aeb_notify` | uguale feature | feature |
| `packages/envelope_room_advisory.yaml` | gate Envelope locale | `script.aeb_notify` | uguale feature | feature |
| `packages/domestic_ops.yaml` | gate DomesticOps locale | `script.aeb_notify` | uguale feature | feature |
| `packages/climate_hardware_branch_control.yaml` | notifiche dirette | gate globale + `COOL_BOTH` | uguale feature | feature |
| `lovelace/01_eclss_casa.yaml` | 2B.2b-R1 | storico pre-2B.2a | runtime post-2B.2a | main |
| `lovelace/10_envelope.yaml` | 2B.2b-R1 | consenso globale, pre-2B.2b | uguale feature | merge manuale |
| `lovelace/11_observability.yaml` | 2B.1/2B.2a | consenso globale + contenuti preservati | uguale feature | merge manuale |
| `lovelace/12_domestic_ops.yaml` | dashboard corrente | consenso globale | uguale feature | merge manuale |

## Matrice helper

| Helper | Main pre-merge | Feature/runtime | Risultato |
|---|---|---|---|
| `input_boolean.aeb_telegram_notifications_enabled` | assente | definito | definito una volta |
| `input_boolean.climate_debug_telegram` | attivo | rimosso | rimosso |
| `input_boolean.vent_notifiche_attive` | attivo | rimosso | rimosso |
| `input_boolean.envelope_notify_enabled` | attivo | rimosso | rimosso |
| `input_boolean.domesticops_notify_enabled` | attivo | rimosso | rimosso |

## Matrice chiamanti

| Chiamante | Main pre-merge | Feature/runtime e risultato |
|---|---|---|
| Climate debug | sender diretto + gate locale | `script.aeb_notify` |
| Ventilazione | sender diretto + gate locale | `script.aeb_notify` |
| AC da VMC | persistent notification | `script.aeb_notify` |
| Envelope | sender diretto + gate locale | `script.aeb_notify` |
| Domestic Ops | sender diretto + gate locale | `script.aeb_notify` |
| Hardware branch | persistent/sender diretto | `script.aeb_notify` |

`script.telegram_ha_mercurio_send` resta il sender basso livello ed e`
raggiungibile dagli alert AEB soltanto attraverso `script.aeb_notify`.

## Estratti dashboard da preservare

Envelope:

- `input_boolean.aeb_telegram_notifications_enabled`;
- `Numero stanze schermate`;
- `Involucro 24h`;
- `Solare e scuri 24h`.

Observability:

- Contracts / State e Reasons;
- Climate, Energy e Domestic diagnostics;
- Legacy mappings;
- consenso globale AEB.

Domestic Ops:

- consenso globale in Stato rapido e Helper e soglie;
- tutte le altre sezioni del main corrente.

ECLSS:

- cinque card Passive House duplicate assenti;
- due trend Passive House assenti;
- contenuti 2B.2a-R1 invariati.

## Invarianti 2B.2a / 2B.2b

- Planner e trend energia restano in Power Runtime.
- Runtime diagnostico AEB resta in DHW.
- Contracts resta consolidato in Observability.
- I cinque duplicati Passive House non tornano in ECLSS.
- I due trend Passive House restano in Envelope.
- Notte 2 e navigation path non cambiano.
