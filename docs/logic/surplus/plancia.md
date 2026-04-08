# Surplus - Plancia

Riferimento operativo corrente: `lovelace/energy_pv_solaredge_plancia.yaml`.

Nota storica:
- la naming `6_surplus_plancia` resta solo come riferimento concettuale;
- l'osservabilita` energia/PV attiva oggi vive nella plancia `PV SolarEdge`.
# Surplus — Documentazione layout plancia energia
# Descrive lovelace/6_surplus_plancia.yaml (monitor produzione/consumi PV).
###############################################################################

SEZIONE 1 — STATO & COMANDI
- Glance "Direzione flussi": sensor.grid_direction, sensor.pv_direction.
- Tile su potenze istantanee: sensor.grid_power_w, sensor.pv_power_w.

SEZIONE 2 — KPI OGGI
- Grid 2x2 di tile (sensor.a_energia_prelevata_forward, sensor.a_energia_immessa_reverse, sensor.b_energia_prelevata_forward, sensor.b_energia_immessa_reverse).

SEZIONE 3 — ANDAMENTO 24H
- History-graph su potenze istantanee sensor.pv_power_w e sensor.grid_power_w (24h).
- History-graph su direzioni `sensor.grid_direction`, `sensor.pv_direction`.

SEZIONE 4 — TREND 7GG / 30GG
- Statistics-graph (barre) 7gg per contatore A (prelievo/import vs immissione/export).
- Statistics-graph (barre) 7gg per contatore B (prelievo/import vs immissione/export).

SEZIONE 5 — SOGLIE & LOCK
- Entities "Parametri energia" con input_number.surplus_min_w, input_number.surplus_lock_minutes, input_boolean.surplus_enable, input_boolean.energy_debug.

SEZIONE 6 — COME DECIDE (SINTESI)
- Valuta il surplus FV confrontando produzione, consumi e (se presente) batteria.
- Attiva i carichi in ordine di priorità rispettando lock min_on/min_off/max_run.
- Può abilitare la pre-carica del pavimento tramite hook verso il modulo Heating.

Per il dettaglio logico:
- core/regole_core_logiche.md → sezione "Surplus — Energia FV, carichi e hook"
- docs/logic/surplus/README.md → configurazione specifica Casa Mercurio

NOTE
- Nessun comando diretto: plancia focalizzata su monitoraggio/diagnostica.
- Tutte le entità provengono dai pacchetti energia/surplus.

## Riferimenti logici
- [Modulo Surplus](README.md)
- [Regole plancia](../core/regole_plancia.md)
- [Regole core logiche](../core/regole_core_logiche.md)
