# STEP18 Hardware Audit ROI Plan (2026-02-27)

Date: 2026-02-27  
Scope: audit hardware orientato ROI per ottimizzazione AEB (senza modifiche authority chain).

## 1) Runtime-critical hardware/sources (FACT from repo)

1. FV produzione:
- `sensor.solaredge_potenza_attuale` (source primaria)
- `sensor.sensor_pv_power_w` (fallback)
- canonico: `sensor.pv_power_now`
- file: `packages/energy_pv_solaredge.yaml`, `packages/climate_policy_energy.yaml`

2. Rete elettrica:
- `sensor.sensor_grid_power_w` (source primaria policy grid)
- `sensor.sensor_grid_direction` (import/export)
- canonico: `sensor.policy_grid_power_w`, `sensor.policy_grid_import_w`
- file: `packages/climate_policy_energy.yaml`

3. Indoor comfort sensing:
- T: `sensor.t_in_giorno/notte1/notte2/bagno`, `sensor.t_in_med`
- RH: `sensor.ur_in_*`, `sensor.ur_in_media`, `sensor.ur_in_min`
- file: `packages/climate_heating.yaml`, `packages/climate_ventilation.yaml`

4. Outdoor sensing:
- `sensor.t_out`, `sensor.ur_out`
- file: `packages/climate_heating.yaml`, `packages/climate_ventilation.yaml`

5. EHW/ACS modbus:
- registri/tank/setpoint (`sensor.ehw_*`)
- file: `packages/ehw_modbus.yaml`

6. Plug energy meters (Meross PM):
- `sensor.pm1/pm2/pm3_*_power_w_main_channel`, `*_energy_kwh_*`
- file: `packages/energy_pm.yaml`

7. Physical actuators:
- Heating relay: `switch.4_ch_interruttore_3` (single-writer enforced)
- AC: `switch.ac_giorno`, `switch.ac_notte`
- VMC: `switch.vmc_vel_0..3`
- file: `packages/climate_heating.yaml`, `packages/climate_ac_logic.yaml`, `packages/climate_ventilation.yaml`

## 2) Gap analysis (AEB optimization impact)

1. Mancano misure elettriche granulari dedicate HVAC:
- assorbimento elettrico dedicato per VMC/AC/Heating relay (oggi parziale o indiretto).

2. Mancano misure termiche idroniche complete:
- mandata/ritorno circuito heating + temperatura superficiale/inerzia (non presenti nel perimetro logico attuale).

3. Forecast PV dipende da feed opzionali:
- policy ha fallback robusti, ma qualità predittiva dipende da disponibilità forecast esterno.

4. Mancano misure qualità aria complete:
- logica VMC usa T/RH/ΔAH, ma non CO2/VOC/PM come driver di qualità aria.

## 3) Priorità upgrade (ROI-first)

## Priorità ALTA

1. Misura potenza dedicata carichi HVAC principali (AC/VMC/Heating):
- Impatto: alto su KPI efficienza, detection cicli reali, tuning planner.
- Costo/complessità: medio.
- Effetto atteso: miglior attribuzione consumi e riduzione tuning “alla cieca”.

2. Sonda/e CO2 in zone principali (giorno + notte):
- Impatto: alto su qualità aria e controllo VMC boost/comfort.
- Costo/complessità: medio-basso.
- Effetto atteso: VMC meno reattiva solo a UR, più centrata su IAQ reale.

3. Affidabilità feed forecast PV (ridondanza provider o qualità feed):
- Impatto: alto su decisioni anticipative AEB.
- Costo/complessità: basso-medio (software/feed).
- Effetto atteso: migliori raccomandazioni planner (pre-heating/pre-cooling).

## Priorità MEDIA

1. Sensori termici idronici (mandata/ritorno) se impianto compatibile:
- Impatto: medio-alto su ottimizzazione heating e diagnostica.
- Costo/complessità: medio-alto (installazione).

2. Misura export/import più robusta con latenza minore:
- Impatto: medio su policy tariff/grid dinamica.
- Costo/complessità: medio.

3. Sensore occupancy affidabile (zone chiave):
- Impatto: medio su comfort-energy tradeoff.
- Costo/complessità: medio.

## Priorità BASSA

1. Ulteriori sonde duplicate T/RH senza clear gap:
- Impatto: basso se già presenti sensori stabili.

2. Upgrade estetici dashboard senza nuovi segnali:
- Impatto: basso su ottimizzazione energetica.

## 4) Piano implementazione consigliato

## Wave 1 (quick wins, 1-2 settimane)

1. Aggiungere misura potenza dedicata ad almeno 2 carichi HVAC.
2. Installare 1-2 sonde CO2 (giorno/notte).
3. Stabilizzare/validare feed forecast PV.
4. Baseline KPI pre/post upgrade (7 giorni + 7 giorni).

## Wave 2 (strutturale, 2-6 settimane)

1. Integrare sensori idronici (se fattibile impiantisticamente).
2. Raffinare policy/planner con nuovi segnali (sempre senza introdurre writer non governati).
3. Audit comparativo KPI (comfort %, cicli, kWh import/export).

## 5) Decisione

- Stato attuale: AEB operativo e stabile.
- Miglioramento hardware: consigliato per aumentare precisione decisionale e ROI energetico.
- Prossimo step tecnico: partire da Wave 1 Priorità Alta.
