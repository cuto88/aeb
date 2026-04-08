# PV SolarEdge — Plancia

Riferimento: `lovelace/energy_pv_solaredge_plancia.yaml`.

Sezioni principali:
- "Stato attuale": gauge `sensor.pv_power_now` + card stato con sorgente selezionata.
- "Energia": `sensor.pv_energy_daily`, `sensor.pv_energy_monthly`, `sensor.pv_energy_yearly`.
- "Produzione giornaliera (7 giorni)": statistics su `sensor.pv_energy_total` (`period: day`, `stat: change`).
- "Trend 24h": history potenza FV.
- "Debug sensori": confronto raw SolarEdge / fallback LocalTuya / canonici.

Hardening applicato:
- `sensor.pv_power_now` con fallback da `sensor.solaredge_potenza_attuale` a `sensor.sensor_pv_power_w`.
- `sensor.pv_energy_total` non forza piu `0` quando la sorgente e` unavailable (evita reset anomali su `utility_meter`).
- Sensore diagnostico sorgente attiva: `sensor.pv_potenza_sorgente` (`solaredge`, `localtuya_fallback`, `unavailable`).

## Riferimenti logici
- [Modulo Energy PV](README.md)
- [Regole plancia](../core/regole_plancia.md)
- [Regole core logiche](../core/regole_core_logiche.md)
