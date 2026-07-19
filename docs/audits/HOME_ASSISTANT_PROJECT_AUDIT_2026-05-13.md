# HOME ASSISTANT PROJECT AUDIT

## 1. EXECUTIVE SUMMARY
Il progetto e' **maturo ma disordinato**.  
La base e' chiaramente **package-based** e c'e' una governance documentale reale, quindi non e' un caos.  
Il problema e' la quantita' di **dipendenze runtime implicite**, alias storici e contratti non espressi nei file sorgente.  
C'e' almeno un **finding CRITICAL dimostrabile**: un token Home Assistant in chiaro nel workspace.  
Ci sono anche segnali concreti di **rischio recorder/database** e di **single-writer non perfettamente chiusa** sull'AC.  
Le automazioni ClimateOps sono strutturate, ma l'osservabilita' di alcuni sensori/strategie e' fragile.  
Non considero il sistema "sano".  
Non lo considero nemmeno "da buttare".  
Lo considero **da stabilizzare con gating runtime prima di qualsiasi refactor**.  
Decisione finale: **RUNTIME EVIDENCE GATE**.

## 2. SYSTEM MAP
| Area | File/cartelle | Ruolo | Stato |
|---|---|---|---|
| Entrypoint HA | [configuration.yaml](../../configuration.yaml) | Include `packages/`, recorder, Lovelace YAML | Attivo, minimale, senza policy recorder articolata |
| Packages core | `packages/` | Dominio principale della logica HA | Modulare ma eterogeneo |
| ClimateOps core | `packages/climateops/` | Planner, arbiter, actuator, drivers, bootstrap | Strato architetturale centrale |
| Climate domain | `packages/climate_ac_*.yaml`, `packages/climate_heating_*.yaml`, `packages/climate_ventilation_*.yaml` | AC, heating, ventilation logic/observability/templates | Buona segmentazione, ma con alias legacy |
| Bridge canonici | [packages/cm_driver_bridge.yaml](../../packages/cm_driver_bridge.yaml) , [packages/cm_policy_bridge.yaml](../../packages/cm_policy_bridge.yaml) , [packages/cm_system_facade.yaml](../../packages/cm_system_facade.yaml) | Contratti `cm_*` e fallback sistemico | Governance-based, ma con dipendenze runtime implicite |
| Energia e fieldbus | `packages/energy_*.yaml`, [packages/sdm120_modbus.yaml](../../packages/sdm120_modbus.yaml), `packages/ehw_modbus*.yaml` | Misura energia, modbus, EHW, PV | Dominio sensibile, alto impatto recorder |
| DomesticOps | [packages/domestic_ops.yaml](../../packages/domestic_ops.yaml) | Advisory domestico FV-aware e notifiche | Overloaded, hotspot manutentivo |
| UI Lovelace | `lovelace/` | Dashboard operative e legacy | Presente, ma con file legacy e archive |
| Documentazione | [README.md](../../README.md), [docs/SOT_ENTITIES.md](../../docs/SOT_ENTITIES.md), [docs/audits/README.md](../../docs/audits/README.md), `docs/runtime_evidence/`, [docs/climateops/ENTRYPOINTS.md](../../docs/climateops/ENTRYPOINTS.md) | Governance, audit trail, mappa entita' | Buona copertura, ma non perfettamente allineata al runtime |
| Segreti / runtime env | `.env` locale non versionato | URL e token HA locali | Critico, non governato correttamente |

## 3. ARCHITECTURE SCORE
| Dimensione | Score | Motivo |
|---|---:|---|
| Modularita' | 7 | Packages ben separati per dominio, ma con package enormi e sovraccarichi |
| Osservabilita' | 6 | Esiste un buon layer di advisory/trace, ma alcuni sensori dipendono da contratti impliciti |
| Sicurezza | 2 | Token HA in chiaro nel workspace; inventario segreti incompleto |
| Manutenibilita' | 5 | Struttura comprensibile, ma drift e legacy file aumentano il costo cognitivo |
| Robustezza template | 4 | Buone protezioni in alcuni punti, ma ci sono riferimenti fragili e alias stabili solo per convenzione |
| Single writer authority | 5 | Buona centralizzazione su alcuni attuatori, ma AC ha writer multipli coordinati solo parzialmente |
| Performance recorder | 4 | DB gia' pesante, backup corrotto presente, molte entita' ad alta frequenza |
| Documentazione | 6 | Molta documentazione, ma con drift tra runtime e source |
| Prontezza runtime | 5 | Il core gira, ma i contratti runtime non sono chiusi abbastanza da essere considerati affidabili senza verifica live |

## 4. CRITICAL FINDINGS
| ID | Severita' | Fatto/Ipotesi | Area | Evidenza file | Impatto | Azione consigliata |
|---|---|---|---|---|---|---|
| CRIT-01 | CRITICAL | FATTO | Security / secrets | `.env` locale non versionato | Token Home Assistant esposto in chiaro nel workspace; rischio di accesso non autorizzato se il file viene replicato, sincronizzato o accidentalmente committato | Ruotare il token, trattare `.env` come compromesso operativo e verificare che nessun log/docs lo abbia replicato |

Nessun altro finding **CRITICAL** e' dimostrabile in modo pulito dai file statici senza chiedere verifica runtime.

## 5. WARNING FINDINGS
| ID | Severita' | Fatto/Ipotesi | Area | Evidenza file | Impatto | Azione consigliata |
|---|---|---|---|---|---|---|
| WARN-01 | WARNING | FATTO | Climate sensors | [packages/climate_sensors.yaml](../../packages/climate_sensors.yaml#L155-L200) | Quattro sensori room-level referenziati non risultano definiti nel repo: KPI e derivati possono restare incompleti o `unknown` | Chiudere il contratto entita' o dichiarare esplicitamente la dipendenza runtime |
| WARN-02 | WARNING | FATTO | AC observability | [packages/climate_ac_templates.yaml](../../packages/climate_ac_templates.yaml#L135-L177) | `sensor.ac_reason` / `sensor.ac_priority` dipendono da `template_event`, ma non esiste un emitter visibile nel repo; rischio aggiornamenti stantii | Sostituire il trigger implicito con una sorgente osservabile o documentare l'emitter runtime |
| WARN-03 | WARNING | FATTO | Ventilation templates | [packages/climate_ventilation_templates.yaml](../../packages/climate_ventilation_templates.yaml#L138-L222) | Il source usa `sensor.climateops_arbiter_suggested_mode/reason`, ma il runtime documentato espone `sensor.arbiter_suggested_mode/reason` | Drift tra source e runtime; rischio dashboard e advisory fuori allineamento |
| WARN-04 | WARNING | FATTO | System facade | [packages/cm_system_facade.yaml](../../packages/cm_system_facade.yaml#L19-L21) | Fallback ancora agganciato a `sensor.climateops_planner_recommended_mode`, mentre il runtime documentato usa `sensor.planner_recommended_mode` | Fallback fragile e semanticamente obsoleto |
| WARN-05 | WARNING | FATTO | Single writer / AC | [packages/climateops/actuators/system_actuator.yaml](../../packages/climateops/actuators/system_actuator.yaml) , [packages/climate_ac_mapping.yaml](../../packages/climate_ac_mapping.yaml) | `switch.ac_giorno` e `switch.ac_notte` sono toccati da script di apply, da un actuator centrale e da un'authority automation di enforcement | Coordinazione presente, ma il perimetro del writer non e' puro; rischio race/revert loop se i precondition falliscono |
| WARN-06 | WARNING | FATTO | Recorder / performance | [configuration.yaml](../../configuration.yaml#L4-L18), evidenza runtime locale del 2026-05-13 | Recorder con purge ridotto a 30 giorni e shortlist di esclusione su metriche osservazionali; DB a 1.2G e backup corrotto da 1.4G | Rischio crescita, WAL churn, UI lenta e manutenzione DB piu' costosa |
| WARN-07 | WARNING | FATTO | Package overloading | [packages/domestic_ops.yaml](../../packages/domestic_ops.yaml) , [packages/climateops_aeb_mvp.yaml](../../packages/climateops_aeb_mvp.yaml) | File troppo grandi e densita' logica alta; il costo di modifica cresce rapidamente | Spezzare per responsabilita' logiche, senza cambiare comportamento |
| WARN-08 | WARNING | RISOLTO 2026-07-19 | Legacy artifacts | [VMC legacy](../../lovelace/_archive/legacy_dashboards/02_air_loop_legacy.yaml), [AC legacy](../../lovelace/_archive/legacy_dashboards/04_cooling_loop_legacy.yaml), [Step7](../../lovelace/_archive/climateops_step7_plancia.yaml) | Gli artefatti legacy sono fuori dalla superficie operativa e non registrati | Mantenere gli archivi immutabili e usarli solo per confronto, gate o rollback |
| WARN-09 | WARNING | FATTO | Secrets governance | [packages/ehw_modbus_transport.yaml](../../packages/ehw_modbus_transport.yaml) , [ops/disabled_runtime/mirai_modbus.transport.yaml](../../ops/disabled_runtime/mirai_modbus.transport.yaml) , [docs/logic/core/README_sensori_mirai.md](../../docs/logic/core/README_sensori_mirai.md) | `!secret` usati correttamente e contratto documentato in `docs/security/secrets.example` | Onboarding e audit dei segreti piu' verificabili |

## 6. ENTITY CONTRACT ISSUES
| Entita' | Tipo problema | Dove appare | Rischio | Verifica richiesta |
|---|---|---|---|---|
| `sensor.t_in_notte3` | Entita' usata ma non definita nel repo | [packages/climate_sensors.yaml](../../packages/climate_sensors.yaml#L155-L156) | Derivati climatici incompleti | Verificare in HA se esiste nel registry runtime |
| `sensor.ur_in_notte3` | Entita' usata ma non definita nel repo | [packages/climate_sensors.yaml](../../packages/climate_sensors.yaml#L199-L200) | Derivati umidita' incompleti | Verificare in HA se esiste nel registry runtime |
| `sensor.t_in_lavanderia` | Entita' usata ma non definita nel repo | [packages/climate_sensors.yaml](../../packages/climate_sensors.yaml#L155-L156) | KPI stanza lavanderia incompleti | Verificare in HA se esiste nel registry runtime |
| `sensor.ur_in_lavanderia` | Entita' usata ma non definita nel repo | [packages/climate_sensors.yaml](../../packages/climate_sensors.yaml#L199-L200) | KPI stanza lavanderia incompleti | Verificare in HA se esiste nel registry runtime |
| `sensor.climateops_arbiter_suggested_mode` | Alias legacy / drift runtime | [packages/climate_ventilation_templates.yaml](../../packages/climate_ventilation_templates.yaml#L138-L222) | Il source non coincide con il runtime documentato | Verificare mapping registry vs source |
| `sensor.climateops_arbiter_suggested_reason` | Alias legacy / drift runtime | [packages/climate_ventilation_templates.yaml](../../packages/climate_ventilation_templates.yaml#L222-L222) | Observability non allineata | Verificare mapping registry vs source |
| `sensor.climateops_planner_recommended_mode` | Fallback obsoleto / alias implicito | [packages/cm_system_facade.yaml](../../packages/cm_system_facade.yaml#L19-L21) | Facade dipende da nome storico | Verificare canonical name runtime |
| `input_boolean.ac_send_command_busy` | Helper usato come mutex logico | [packages/climate_ac_logic.yaml](../../packages/climate_ac_logic.yaml#L156-L182) | Deadlock o busy-state se non liberato bene | Verificare che solo wrapper AC lo modifichi |
| `input_boolean.ac_block_vmc` | Helper usato come interlock temporale | [packages/climate_ac_logic.yaml](../../packages/climate_ac_logic.yaml#L37-L64) | Blocco VMC persistente se il timeout fallisce | Verificare clearance automatica e trace |
| `input_boolean.climateops_dhw_request` | Helper usato come richiesta/queue | [packages/climateops_dhw_writer.yaml](../../packages/climateops_dhw_writer.yaml#L141-L261) | Re-entrancy e pending state se il writer non chiude | Verificare idempotenza nel runtime |

## 7. AUTOMATION CONFLICT MATRIX
| Entita' attuata | Writer 1 | Writer 2 | Writer 3 | Stato | Rischio |
|---|---|---|---|---|---|
| `switch.heating_master` | `automation.climateops_system_actuate` | Template switch `switch.heating_master` verso relay fisico | - | OK | Basso, se il relay template resta l'unico punto fisico |
| `switch.vmc_vel_0..3` | `automation.climateops_system_actuate` | - | - | OK | Basso |
| `switch.ac_giorno` | `script.ac_giorno_apply` | `automation.climateops_system_actuate` | `automation.climateops_enforce_ac_writer_authority` | WARNING | Medio-alto: writer multipli coordinati ma non puri |
| `switch.ac_notte` | `script.ac_notte_apply` | `automation.climateops_system_actuate` | `automation.climateops_enforce_ac_writer_authority` | WARNING | Medio-alto: stesso rischio del canale giorno |

## 8. TEMPLATE ROBUSTNESS
| File | Entita'/template | Problema | Fix suggerito | Severita' |
|---|---|---|---|---|
| [packages/climate_sensors.yaml](../../packages/climate_sensors.yaml) | `sensor.t_in_notte3`, `sensor.ur_in_notte3`, `sensor.t_in_lavanderia`, `sensor.ur_in_lavanderia` | Dipendenza su entita' mancanti nel repo | Chiudere il contratto con nomi canonici o rendere esplicita la dipendenza runtime | WARNING |
| [packages/climate_ac_templates.yaml](../../packages/climate_ac_templates.yaml) | `sensor.ac_priority`, `sensor.ac_reason` | Trigger `template_event` senza producer visibile | Legare il template a sorgenti state/event concrete o documentare l'emitter | WARNING |
| [packages/climate_ventilation_templates.yaml](../../packages/climate_ventilation_templates.yaml) | `sensor.climateops_arbiter_suggested_mode`, `sensor.climateops_arbiter_suggested_reason` | Alias storico divergente dal runtime documentato | Allineare source e runtime oppure formalizzare il bridge | WARNING |
| [packages/cm_system_facade.yaml](../../packages/cm_system_facade.yaml) | `sensor.climateops_planner_recommended_mode` | Fallback vecchio rispetto al runtime canonico | Sostituire il fallback con il nome effettivo del registry o documentare la compat layer | WARNING |

## 9. RECORDER / PERFORMANCE
- Rischio reale: [configuration.yaml](../../configuration.yaml#L4-L18) imposta `purge_keep_days: 30`, `auto_purge: true` e una shortlist di esclusione su metriche osservazionali; resta il rischio DB residuo ma il perimetro è governato.
- Rischio reale: l'evidenza runtime locale del 2026-05-13 mostrava `home-assistant_v2.db` da 1.2G e un backup corrotto da 1.4G.
- Rischio reale: nel repo ci sono molti derivati frequenti, soprattutto `statistics`, `history_stats`, `time_pattern` e `logbook`; questo aumenta churn su recorder e WAL.
- Candidate a esclusione o almeno a review prioritaria: advisory/observability ad alta frequenza in `packages/climateops_aeb_mvp.yaml`, `packages/climate_ac_observability.yaml`, `packages/climate_heating_observability.yaml`, `packages/energy_pm.yaml`, `packages/sdm120_modbus.yaml`, `packages/mirai_runtime_truth_advisory.yaml`, `packages/domestic_ops.yaml`.
- Verifiche necessarie: crescita DB per 24h/7d, impatto su statistics helpers, cardinalita' delle entita' in logbook, coerenza long-term statistics, dimensione WAL/SHM.
- Impatto atteso di una governanza seria: meno storage, meno lentezza UI, meno rischio di corruzione/backup sporchi.

## 10. SECURITY
- Segreto trovato: `.env` locale non versionato contiene `HA_URL` e un `HA_TOKEN` in chiaro.
- Segreti referenziati correttamente via `!secret`: `ehw_modbus_host`, `ehw_modbus_port`, `ehw_modbus_slave`, `mirai_modbus_host`.
- Gap chiuso: il contratto segreti e' inventariato in [docs/security/secrets.example](../../docs/security/secrets.example).
- Target sensibile centralizzato: `notify.telegram_davide` nel wrapper [packages/notify_telegram.yaml](../../packages/notify_telegram.yaml#L1-L20).
- Azioni immediate: ruotare il token HA, assicurare che `.env` non entri mai in history o backup, inventariare i `!secret` richiesti, verificare che nessun doc/audit contenga credenziali copiate.

## 11. DOCUMENTATION DRIFT
| Documento | Drift rilevato | Impatto | Azione |
|---|---|---|---|
| [README.md](../../README.md#L3-L10) | Descrive correttamente packages e fonti di verita', ma non esplicita tutti i bridge/runtime alias oggi presenti | Medio | Aggiornare la mappa con alias runtime e dipendenze legacy |
| [docs/SOT_ENTITIES.md](../../docs/SOT_ENTITIES.md#L39-L45) | Riporta dipendenze runtime legacy/non-cm, ma non chiude l'allineamento con i nomi canonici effettivi | Medio | Rendere esplicito il mapping source-runtime |
| [docs/audits/CURRENT_RUNTIME_STATUS_2026-04-15.md](../../docs/audits/CURRENT_RUNTIME_STATUS_2026-04-15.md#L28-L29) | Dichiara `sensor.planner_recommended_mode` attivo e il legacy `sensor.climateops_planner_recommended_mode` assente | Basso-Medio | Aggiornare i fallback sorgente per evitare ambiguita' |
| [docs/audits/STEP70_AC_CANONICAL_DRIVER_BRIDGE_2026-04-22.md](../../docs/audits/STEP70_AC_CANONICAL_DRIVER_BRIDGE_2026-04-22.md#L64-L65) | Runtime usa proxy e arbiter senza prefisso `climateops_` in piu' punti | Medio | Riflettere il naming reale nel contratto documentale |
| [docs/climateops/ENTRYPOINTS.md](../../docs/climateops/ENTRYPOINTS.md#L4-L7) | Corretta come descrizione del load model, ma non basta da sola a governare i contratti entita' | Basso | Tenere, ma integrare con una entity registry map aggiornata |

## 12. TOP 10 ACTIONS
| Priorita' | Azione | Tempo stimato | Rischio ridotto | ROI |
|---|---|---:|---|---|
| 1 | Ruotare il token HA e trattare `.env` come compromesso operativo | 15-30 min | Esposizione credenziali | Altissimo |
| 2 | Verificare nel runtime i nomi canonici di planner/arbiter/proxy e chiudere il drift | 15-30 min | Contratti entita' impliciti | Altissimo |
| 3 | Ispezionare trace di `automation.climateops_system_actuate` e degli script apply AC | 30-45 min | Race, loop, writer multipli | Alto |
| 4 | Chiudere il problema dei quattro sensori stanza mancanti | 30-45 min | KPI rotti e template fragili | Alto |
| 5 | Verificare `sensor.ac_reason` / `sensor.ac_priority` e il producer dell'evento | 30-45 min | Observability stantia | Alto |
| 6 | Imporre una policy recorder piu' precisa o almeno una shortlist di esclusione | 30-60 min | DB growth / performance | Alto |
| 7 | Separare `domestic_ops.yaml` in moduli per responsabilita' | 60-120 min | Manutenibilita' | Medio-alto |
| 8 | Formalizzare il mapping `!secret` in un inventario documentale | 30-60 min | Drift segreti | Medio |
| 9 | Verificare e archiviare i dashboard legacy non piu' usati | 30-60 min | UI drift | Medio |
| 10 | Aggiornare la SOT entita' con i nomi runtime effettivi | 30-60 min | Ambiguita' operativa | Medio |

## 13. MVP FIX PLAN 1-2H
- 0-30 min
  - Verificare in Developer Tools i nomi effettivi di `sensor.planner_recommended_mode`, `sensor.arbiter_suggested_mode`, `sensor.arbiter_suggested_reason`, `switch.ac_giorno`, `switch.ac_notte`, `switch.heating_master`.
  - Controllare se `sensor.ac_reason` e `sensor.ac_priority` si aggiornano davvero senza interventi manuali.
- 30-60 min
  - Aprire le trace di `automation.climateops_system_actuate` e degli script `script.ac_giorno_apply` / `script.ac_notte_apply`.
  - Cercare re-trigger inutili, revert, timeout o `unknown` persistenti sui canali AC.
- 60-120 min
  - Definire una lista minima di entita' ad alto churn da tenere sotto osservazione nel recorder.
  - Allineare la documentazione dei nomi runtime con i nomi usati nel source, senza toccare la logica.

## 14. RUNTIME EVIDENCE REQUIRED
- Log core HA: errori di load su package, template warning, restore issues.
- Trace automazioni: `automation.climateops_system_actuate`, `automation.climateops_enforce_ac_writer_authority`, `script.ac_giorno_apply`, `script.ac_notte_apply`, `automation.climateops_dhw_writer_execute`, `automation.climateops_aeb_mvp_dispatch`.
- Stati entita': `switch.ac_giorno`, `switch.ac_notte`, `switch.heating_master`, `binary_sensor.vmc_is_running_proxy`, `sensor.planner_recommended_mode`, `sensor.arbiter_suggested_mode`, `sensor.ac_reason`.
- Recorder DB: dimensione, crescita giornaliera, integrita', WAL/SHM, eventuali resti di corruzione.
- Storico: presenza di update coerenti sui sensori advisory e sui contatori.
- Developer Tools: template evaluation per i sensori che oggi dipendono da alias o da eventi non visibili.
- Restart check: boot senza entita' `unknown` persistenti sui canali critici.
- Correlazione `context_id`: verificare che la catena `automation.climateops_system_actuate` -> script/apply -> attuatore fisico sia coerente e non duplicata.

## 15. FINAL DECISION
**STABILIZZARE**
