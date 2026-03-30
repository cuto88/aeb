# Surplus — Logica gestione surplus FV Casa Mercurio

## Titolo
Surplus — logica surplus FV (decisionale).

## Obiettivo
- Massimizzare autoconsumo PV riducendo prelievi da rete.
- Attivare carichi a priorità progressiva e, quando utile, abilitare pre-carica del pavimento radiante.

## Entrypoints
- YAML: `packages/6_surplus_energy.yaml`.
- Lovelace: `lovelace/6_surplus_plancia.yaml`.

## KPI / Entità principali
### Sensori e metriche energia
- Potenza FV istantanea (`sensor.pv_power_w`), direzione `sensor.pv_direction`.
- Potenza/prelievo rete (`sensor.grid_power_w`, `sensor.grid_direction`), contatori e trend.
- Dal `2026-03-30` il layer canonico rete e` promosso verso `SDM120`; gli alias `grid_*` sono la fonte SSOT da usare nei moduli decisionali, con il ramo dual meter legacy mantenuto solo come compatibilita` transitoria.
- Eventuale batteria: livello/SOC e stato carica se disponibile.
- Carichi monitorati: boiler/presa EV/altro carico smart, con sensori di stato runtime.

### Eccezioni locali / tuning specifico
- Priorità Casa Mercurio: Step1 boiler/presa lenta; Step2 carico opzionale/EV veloce; eventuale Step3 extra solo in surplus ampio.
- Soglia iniziale `input_number.surplus_min_w` e scaling 2× per step successivi; rientro con isteresi su media breve per evitare oscillazioni.
- In caso di rete instabile o batteria in carica prioritaria: blocco attivazione step >1 anche con surplus.
- Comfort: nessuna forzatura COOL; pre-carica heating solo se comfort non già raggiunto e lock heating rispettati.

### Note di implementazione YAML
- Automazioni/helper in `packages/6_surplus_energy.yaml`; binary_sensor di stato surplus/deficit e contatori in 0_sensors.yaml.
- Ogni step usa switch dedicati e timer `timer.surplus_step_*` per lock; entità debug abilitate da `input_boolean.energy_debug`.
- Hook verso heating gestito da automation dedicata con timeout 180m e rispetto min_off prima di nuovo invio.

## Hook / Dipendenze
- Logica di surplus/deficit e carichi a step in `core/regole_core_logiche.md` → sezione "Surplus — Energia FV, carichi e hook".
- Lock min_on/min_off/max_run seguono la tabella lock core (voce Surplus).
- Hook `hook_surplus_heating_precharge` alzato quando surplus stabile e fascia heating utile.

## Riferimenti
- [docs/logic/core/regole_core_logiche.md](../core/regole_core_logiche.md)
- [docs/logic/core/README_sensori_clima.md](../core/README_sensori_clima.md)
- [docs/logic/core/regole_plancia.md](../core/regole_plancia.md)
- [README_ClimaSystem.md](../../../README_ClimaSystem.md)
