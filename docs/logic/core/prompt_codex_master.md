This is the ONLY canonical Codex prompt for this repository.
Any other prompt files are deprecated or stubs.

# PROMPT CODEX MASTER — CASA MERCURIO  
Versione 2025.01 — Codex Environment

---

# 1. CONTESTO DI LAVORO (immutabile)

Il sistema clima Casa Mercurio è suddiviso in:

- `packages/climate_sensors.yaml`
- `packages/climate_ventilation.yaml`
- `packages/climate_ventilation_windows.yaml`
- `packages/climate_heating.yaml`
- `packages/climate_ac_mapping.yaml`
- `packages/climate_ac_logic.yaml`
- `packages/migration_boundary.yaml`
- `packages/climateops/** (drivers/strategies/overrides)`

Plance Lovelace:

- `lovelace/climate_ventilation_plancia.yaml`
- `lovelace/climate_ventilation_plancia_v2.yaml`
- `lovelace/climate_heating_plancia.yaml`
- `lovelace/climate_ac_plancia.yaml`

Entity Map ufficiale:

- `docs/logic/core/README_sensori_clima.md`

Documenti canonici:

- `docs/logic/README.md`
- `docs/logic/core/README_sensori_clima.md`
- `docs/logic/core/regole_core_logiche.md`
- `docs/logic/core/regole_plancia.md`
- `README_ClimaSystem.md`

Le descrizioni possono essere in italiano.  
Gli `entity_id` devono essere **in inglese** SEMPRE.

---

# 2. REGOLE ASSOLUTE (hard rules)

1. NON rinominare mai un `entity_id` esistente.
2. NON creare mai duplicati (entità simili o alias).
3. NON modificare semantica delle automazioni esistenti senza motivo esplicito.
4. Tutti i file devono rispettare l’ENTITY MAP.
5. Ogni nuova entità deve essere:
   - aggiunta PRIMA al README
   - poi definita nei packages
   - poi integrata nella dashboard (solo se serve)
6. NON creare mai nuove metriche ΔT o ΔAH.
7. Usare solo:
   - `sensor.vmc_freecooling_status`
   - `sensor.clima_open_windows_recommended`
   - `sensor.delta_t_in_out`
   - `sensor.delta_ah_in_out`
8. YAML deve essere valido e coerente con HA.
9. Nessuna card Lovelace custom: usare card standard.
10. Non chiamare mai servizi `switchbot.*`; tutte le attuazioni devono passare da script driver (es. `script.ac_hw_press`) o wrapper.
11. Non spostare o rinominare file legacy finché non esiste il tag `migration_done`.

---

# 3. REGOLE ANTI-DUPLICATI (MANDATORIE)

## 3.1 Vietati alias KPI
Esempi:

- ❌ `sensor.t_in_media`  
  ✔️ usare solo `sensor.t_in_med`

- ❌ `sensor.delta_t_freecooling`  
  ✔️ usare `sensor.delta_t_in_out`

- ❌ `sensor.delta_ah_freecooling`  
  ✔️ usare `sensor.delta_ah_in_out`

## 3.2 Mai ricreare diagnostiche parallele
Usare ed estendere SOLO:

- `sensor.vmc_freecooling_status`
- `sensor.clima_open_windows_recommended`

## 3.3 Nuove entità solo come "ultima ratio"
Consentite solo se:

- KPI inesistente
- motivazione chiara
- aggiunta al README
- definizione in un solo package
- coerenza assoluta

## 3.4 Allineamento dashboard
Entrambe le plance VMC devono mostrare:

- Freecooling status  
- Windows recommendation  
- ΔT  
- ΔAH  

Layout: **single column**, mobile friendly.

## 3.5 Checklist Codex prima di ogni output
Codex deve verificare:

- zero duplicati  
- zero alias  
- zero nuove ΔT/ΔAH  
- YAML valido  
- coerenza con ENTITY MAP  

Se rileva problemi → deve autocorreggersi.

---

# 4. LOGICHE PASSIVHAUS (standard)

## FREECOOLING STATUS

Stati possibili:

- `off`
- `soft`
- `strong`

### Soft:
- T_in > 24°C  
- ΔT ≥ 2°C  
- ΔAH ≥ 2 g/m³  

### Strong:
- T_in > 25°C  
- ΔT ≥ 3°C  
- ΔAH ≥ 3 g/m³  

### Off:
- T_in ≤ 23°C  
OPPURE  
- ΔT < 1°C **AND** ΔAH < 1 g/m³ per 30 minuti

---

## APERTURA FINESTRE (WINDOWS RECOMMENDATION)

ON se:

- T_in > 25.5°C  
- ΔT ≥ 3°C  
- ΔAH ≥ 3 g/m³  
- `binary_sensor.vent_condizioni_meteo_ok == on`  
- freecooling = soft/strong per ≥ 45 minuti

Hysteresis:

- min ON: 10 min  
- OFF: ΔT < 1°C AND ΔAH < 1 g/m³  

---

# 5. OUTPUT TEMPLATE DI CODICE (obbligatorio per Codex GPT)

Ogni modifica deve generare output così:

FILE: docs/logic/core/README_sensori_clima.md
<contenuto aggiornato>

FILE: packages/climate_ventilation.yaml
<contenuto aggiornato>

FILE: lovelace/climate_ventilation_plancia.yaml
<contenuto aggiornato>

FILE: lovelace/climate_ventilation_plancia_v2.yaml
<contenuto aggiornato>

yaml
Copia codice

Nessun testo extra.

---

# 6. REGOLE DI STILE
- YAML sempre validato.
- Indentazione 2 spazi.
- Commenti solo in italiano.
- entity_id in inglese.
- Nessun "rumore" nel codice.

---

# 7. ISTRUZIONE PERMANENTE
Questo documento rappresenta la **single source of truth** per Codex GPT in tutto l'ambiente CASA MERCURIO.

# FINE FILE
