# 🧭 Struttura sistemi Casa Silea — docs/logic/

Panoramica aggiornata della cartella `docs/logic/` dopo la semplificazione: separa le regole core, i file di logica per modulo e le plance documentate.

## 🧩 Standard di riferimento
- **Regole globali**: tutte le convenzioni, priorità, lock e hook vivono unicamente in `docs/logic/core/regole_core_logiche.md`; qui risiedono anche le logiche ufficiali e complete per VMC, AC, Heating, Vent e Surplus.
- **Moduli logici (ventilation, heating, ac, energy_pm, surplus, debug)**:
  - `docs/logic/<modulo>/README.md` (o equivalente) contiene logica locale, eccezioni e mappa sensori/attuatori.
  - `docs/logic/<modulo>/plancia.md` (o equivalente) definisce solo layout e KPI della plancia Lovelace.
  - Nessuna logica duplicata dentro i file di plancia: le regole puntano sempre al core per priorità, lock e hook.
- **Documentazione soltanto**: la cartella `docs/logic/` ospita solo documenti testuali (nessun YAML o automazione).
- **Collegamenti ai package**: i moduli fanno riferimento al core per le regole condivise e dichiarano solo le eccezioni locali.
- **Consolidamento VMC**: la logica VMC vive nel modulo `ventilation`, insieme a ventilazione naturale e diagnostica.

## 📂 Struttura ad albero
```
docs/logic/
├─ core/
│  ├─ regole_core_logiche.md      ← convenzioni, priorità, lock, hook e logiche ufficiali
│  └─ regole_plancia.md           ← linee guida UI comuni
├─ ventilation/
│  ├─ README.md                   ← logica ventilazione naturale + VMC
│  ├─ plancia.md                  ← layout plancia ventilation
│  ├─ vmc.md                      ← approfondimento VMC (meccanica)
├─ heating/
│  ├─ README.md                   ← logica riscaldamento a pavimento
│  └─ plancia.md                  ← layout plancia heating
├─ ac/
│  ├─ README.md                   ← logica climatizzazione
│  └─ plancia.md                  ← layout plancia AC
├─ energy_pm/
│  └─ plancia.md                  ← layout plancia power meter (5_powermeter)
├─ surplus/
│  ├─ README.md                   ← logica surplus energetico
│  └─ plancia.md                  ← layout plancia surplus
├─ _backup/
│  ├─ archive/                    ← versioni storiche (es. plancia VMC legacy)
│  └─ doc/                        ← documenti di progetto
├─ _backup_legacy/                ← spazio per file legacy o non allineati
└─ README_struttura_sistemi.md    ← questo file
```

## 🎛️ Ruoli dei file
- **core/**: unica fonte per convenzioni, priorità P0–P4, lock e hook cross-modulo (regole_core_logiche) e per le linee guida UI generali (regole_plancia).
- **Cartelle modulo**: contengono coppie `logica` + `plancia` specifiche del modulo; le plance riportano solo layout e rimandi ai documenti core.
- **_backup/**: conserva versioni storiche non più attive e la documentazione di progetto.
- **_backup_legacy/**: raccoglie file legacy, bozze e risorse temporanee non allineate allo standard.

## 🔗 Collegamento con YAML
Ogni documento di logica corrisponde a un package YAML e alla relativa plancia Lovelace omonima, ma la cartella `docs/logic/` rimane soltanto documentale. Le soglie e i lock devono essere presi dal core; i moduli dichiarano solo le eccezioni locali. Le plance includono sempre la sezione **RIFERIMENTI LOGICI** con link al core e al file logico del modulo.

## 🌡️ Clima 2026 — stack attivo
- **Packages (principali):** `packages/climate_sensors.yaml`, `packages/climate_ventilation.yaml`, `packages/climate_heating.yaml`, `packages/climate_ac_logic.yaml`, `packages/climate_ac_mapping.yaml`.
- **ClimateOps (orchestrazione):** `packages/climateops/` (drivers, strategies, actuators, overrides).
- **Plance Lovelace (entrypoint utente):** `lovelace/climate_casa_unified_plancia.yaml`.
- **Plance tecniche/legacy ancora registrate ma dismesse da sidebar:** `lovelace/climate_ventilation_plancia.yaml`, `lovelace/climate_ventilation_plancia_v2.yaml`, `lovelace/climate_heating_plancia.yaml`, `lovelace/climate_ac_plancia.yaml`, `lovelace/climate_ac_plancia_v2.yaml`, `lovelace/ehw_plancia.yaml`, `lovelace/8_mirai_plancia.yaml`.
- **Plance archiviate fuori dall'entrypoint utente:** `lovelace/_archive/climateops_step7_plancia.yaml` come copia storica; la voce dashboard e` gia' rimossa da `configuration.yaml` e l'originale `lovelace/climateops_step7_plancia.yaml` e` gia' stato rimosso dal repo attivo.

> Revisione documentazione clima: riferimenti allineati ai file runtime attuali.
