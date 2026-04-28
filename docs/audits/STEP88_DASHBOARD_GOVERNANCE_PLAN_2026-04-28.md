# STEP88 - Dashboard governance plan (2026-04-28)

## Scopo
Definire una struttura target chiara per tutte le plance Lovelace, riducendo ridondanza e mescolanza tra overview, diagnostica, tuning e forensic.

## FACT
Le plance attuali coprono bene il sistema ma non hanno ancora una gerarchia di ruolo sufficientemente netta.

Plance censite:
- `climate_casa_unified_plancia.yaml`
- `climate_ventilation_plancia.yaml`
- `climate_ventilation_plancia_v2.yaml`
- `climate_ac_plancia.yaml`
- `climate_ac_plancia_v2.yaml`
- `climate_heating_plancia.yaml`
- `8_mirai_plancia.yaml`
- `ehw_plancia.yaml`
- `modbus_plancia.yaml`
- `consumi_mirai_ehw_plancia.yaml`
- `energy_pv_solaredge_plancia.yaml`
- `envelope_involucro_plancia.yaml`

## Problema

## FACT
Oggi alcune plance fanno contemporaneamente:
- overview operativa;
- tuning;
- debug runtime;
- forensic/machine diagnostics.

## IPOTESI (confidenza alta)
Questo riduce leggibilità e aumenta duplicazioni, soprattutto tra:
- `Clima Casa` e le plance dominio;
- `Passive House` e `envelope_involucro`;
- plance `v2` e plance legacy dello stesso dominio.

## Target taxonomy

## DECISIONE
Le plance vengono governate secondo 5 classi:

1. **Main operational**
   - overview quotidiana, leggibile in pochi secondi

2. **Domain drill-down**
   - VMC / AC / Heating

3. **Technical / machine**
   - MIRAI / EHW / Modbus

4. **Energy / optimization**
   - Consumi / PV

5. **Building physics**
   - Involucro / Passive House

---

## Mappa target per plancia

| Plancia | Ruolo attuale | Valutazione | Decisione |
|---|---|---|---|
| `climate_casa_unified_plancia.yaml` | overview + tuning + debug + cross-domain | troppo densa ma corretta come entrypoint | **keep, simplify** |
| `climate_ventilation_plancia.yaml` | VMC domain drill-down | leggibile e compatta | **keep** |
| `climate_ventilation_plancia_v2.yaml` | VMC alt UI | concorrente alla legacy | **decide / likely promote-or-archive** |
| `climate_ac_plancia.yaml` | AC domain drill-down | utile ma parzialmente ridondante | **keep, simplify** |
| `climate_ac_plancia_v2.yaml` | AC alt UI | concorrente alla legacy | **decide / likely promote-or-archive** |
| `climate_heating_plancia.yaml` | Heating drill-down + legacy TEMP | utile ma troppo carica di storico/legacy | **keep, simplify** |
| `8_mirai_plancia.yaml` | machine diagnostics | appropriata come plancia tecnica | **keep** |
| `ehw_plancia.yaml` | machine/writer diagnostics | appropriata come plancia tecnica | **keep** |
| `modbus_plancia.yaml` | fieldbus / forensic | appropriata come plancia tecnica | **keep** |
| `consumi_mirai_ehw_plancia.yaml` | energy KPI + technical overlap | utile ma candidata a overlap | **keep, review later** |
| `energy_pv_solaredge_plancia.yaml` | PV / energy source | ruolo chiaro | **keep** |
| `envelope_involucro_plancia.yaml` | building physics | sovrapposta in parte a Passive House | **consolidate with Passive House** |

---

## Regole di governance

1. `Clima Casa` deve mostrare prima di tutto:
   - stato sistema;
   - reason dominante;
   - attuazione attuale;
   - fault/blocchi;
   - KPI ambientali essenziali.

2. I controlli di tuning non devono stare nella parte alta della vista principale.

3. Le plance tecniche macchina non devono essere “rese consumer”; devono restare dense ma separate.

4. Le versioni `v2` non possono restare indefinitamente concorrenti alle legacy.

5. Il dominio involucro deve avere una sola vista principale, non due superfici piene che raccontano quasi la stessa cosa.

---

## Sequenza di refactor

### Fase 1
**DECISIONE**
Ripulire `Clima Casa`:
- solo overview operativa sopra il fold;
- tuning e diagnostica secondaria più in basso;
- writer/debug EHW ridotti nella vista principale.

### Fase 2
**DECISIONE**
Ripulire plance dominio:
- VMC
- AC
- Heating

Obiettivo:
- ogni plancia = drill-down leggibile del proprio dominio.

### Fase 3
**DECISIONE**
Decidere destino `v2`:
- promuovere la migliore
oppure
- archiviare quella ridondante.

### Fase 4
**DECISIONE**
Consolidare `Passive House` / `Involucro`.

---

## Stato operativo deciso

## DECISIONE
La baseline è congelata in `STEP87`.

Il refactor può procedere senza rischio di perdita di stato UI, perché il rollback contenutistico è definito.
