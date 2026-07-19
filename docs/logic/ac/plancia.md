# AC — Plancia

Riferimento corrente: `lovelace/04_cooling_loop.yaml`.

Stato sidebar:
- `04-ac` registra `lovelace/04_cooling_loop.yaml` come `4 Cooling Loop`, visibile in sidebar.
- `lovelace/_archive/legacy_dashboards/04_cooling_loop_legacy.yaml` e` conservata per confronto e rollback, ma non e` registrata in `configuration.yaml`.
- L'overview cross-modulo resta `01-clima-casa`; la plancia Cooling e` il drill-down ufficiale del dominio.

Sezioni principali:
- "Stato generale": priorità/motivo AC, stagione calda, failsafe e blocco VMC, con stato `switch.ac_giorno` e `switch.ac_notte`.
- "Setpoint e comandi": parametri dry/cool e lock min on/off.
- "Manuale e blocchi": `input_boolean.ac_manual`, `input_select.ac_manual_mode`, timeout manuale e blocco da VMC.
- "KPI principali": temperatura/umidità interna media ed esterna.
- "Grafici 24h / 7gg": temperatura, umidità e statistiche motivazioni.
- "Runtime e cicli": contatori ON/cicli/ultimo evento per AC giorno e notte.
- "Debug" + "Timeline decisioni": visione diagnostica completa.

Tuning UI/performance applicato:
- Tutti i `history-graph` sono su finestra 12h con `refresh_interval: 120`.
- Riduce redraw e carico frontend mantenendo leggibilità operativa.

## Riferimenti logici
- [Modulo AC](README.md)
- [Regole plancia](../core/regole_plancia.md)
- [Regole core logiche](../core/regole_core_logiche.md)
