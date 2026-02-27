# STEP9 Project Closure (2026-02-27)

Date: 2026-02-27  
Scope: chiusura formale progetto ClimateOps hardening/runtime.

## Criteri di chiusura

1. Governance runtime e writer chain documentate con evidenza evento-level.
2. Quality gates locali tutti verdi.
3. Runtime Home Assistant raggiungibile e configurazione valida.
4. Nessun blocker aperto nei report Step 0..8.

## Evidenze consolidate (FACT)

1. Correlazione evento-level chain AC e attuazione:
   - Fonte: `docs/runtime_evidence/2026-02-24/REPORT_event_level_context_audit.md`
   - Correlazioni documentate:
     - `automation.climateops_system_actuate` -> `script.ac_giorno_apply`
     - `automation.climateops_system_actuate` -> `switch.turn_off` su `switch.ac_giorno` e `switch.ac_notte`
     - transizioni stato `switch.ac_giorno/off` e `switch.ac_notte/off` nello stesso contesto evento (context binario HEX).

2. Runtime host verificato il 2026-02-27:
   - `core-ssh`, utente `root`, data host `Fri Feb 27 11:16:27 CET 2026`.
   - Snapshot runtime acquisiti in locale:
     - `_ha_runtime_backups/trace.saved_traces.2026-02-27.json`
     - `_ha_runtime_backups/core.restore_state.2026-02-27.json`

3. Quality gates locali eseguiti il 2026-02-27:
   - Comando: `powershell -ExecutionPolicy Bypass -File ops/gates_run.ps1`
   - Esito: `ALL GATES PASSED`
   - Gate coperti: hygiene, yamllint, include tree, HA structure/entity map, dashboard gates, naming, nested template, artifact policy, docs links.

4. Step 8 policy/hardening già formalizzati:
   - `docs/audits/STEP8_GATES_POLICY_2026-02-27.md`
   - `docs/audits/STEP8_RUNTIME_CLOSURE_2026-02-26.md`
   - `docs/audits/STEP8_RUNTIME_AUDIT_24H_2026-02-26.md`

## Nota operativa (non bloccante)

- Nel campione `trace.saved_traces` live letto il 2026-02-27 erano presenti run recenti non-AC (heating/VMC).  
  Questo non invalida la chiusura, perche' la correlazione AC evento-level risulta gia' dimostrata nei dump storici (`2026-02-24`).
- Post-closure hardening heating authority (2026-02-27): `switch.heating_night_block` convertito a gate logico non-writer;
  writer diretto unico del relay fisico `switch.4_ch_interruttore_3` centralizzato su `switch.heating_master`.

## Esito finale

- Stato progetto: **CLOSED**
- Data chiusura: **2026-02-27**
- Qualita': **PASS** (gates verdi)
- Runtime evidence: **SUFFICIENTE** per chiusura forense operativa (automation/script/switch con correlazione context).
