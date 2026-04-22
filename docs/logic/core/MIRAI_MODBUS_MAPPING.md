# MIRAI Modbus Mapping

Documento canonico per il mapping Modbus MIRAI usato nel runtime Home Assistant.

Scopo:
- elencare i registri attivi del profilo stabile;
- esplicitare la semantica oggi assunta dal runtime;
- distinguere cio' che e' `confermato`, `candidato`, `smentito`;
- separare il mapping fisico dei registri dalla diagnostica di run.

## Sorgenti autoritative

- Transport Modbus: [mirai_modbus.yaml](../../../packages/mirai_modbus.yaml)
- Template runtime: [mirai_templates.yaml](../../../packages/mirai_templates.yaml)
- Advisory runtime truth: [mirai_runtime_truth_advisory.yaml](../../../packages/mirai_runtime_truth_advisory.yaml)
- Overview sensori: [README_sensori_mirai.md](README_sensori_mirai.md)

## Profilo stabile attuale

- Hub: `mirai`
- Protocollo: Modbus TCP
- Slave runtime valido: `1`
- Profilo operativo: `status-only unit1`
- Polling stabile: registri minimi e probe selezionati, senza riaprire il profilo storico rumoroso

## Mapping registri attivi

| Registro | Entity runtime | Tipo | Semantica corrente | Stato |
|---|---|---|---|---|
| `1003` | `sensor.mirai_u1_status_word_raw`, `sensor.mirai_status_word_raw`, `sensor.mirai_status_word_effective` | `uint16` | status word principale macchina | confermato |
| `1208` | `sensor.mirai_u1_status_code_raw`, `sensor.mirai_status_code_raw`, `sensor.mirai_status_code_effective` | `uint16` | status code macchina | confermato |
| `1209` | `sensor.mirai_u1_fault_code_raw`, `sensor.mirai_fault_code_raw`, `sensor.mirai_fault_code_effective` | `uint16` | fault code macchina | confermato |
| `4000` | `sensor.mirai_probe_temp_a_raw`, `sensor.mirai_probe_temp_a_c` | `uint16` | probe temperatura A scalata `x10` | candidato forte |
| `9050` | `sensor.mirai_probe_temp_a_dup_9050_raw` | `uint16` | duplicato coerente di `4000` | candidato forte |
| `9086` | `sensor.mirai_probe_temp_a_dup_9086_raw` | `uint16` | duplicato coerente di `4000` | candidato forte |
| `3548` | `sensor.mirai_probe_temp_b_raw`, `sensor.mirai_probe_temp_b_c` | `uint16` | probe temperatura B scalata `x10` | candidato forte |
| `9087` | `sensor.mirai_probe_temp_b_dup_9087_raw` | `uint16` | duplicato coerente di `3548` | candidato forte |
| `3515` | `sensor.mirai_probe_temp_outdoor_raw`, `sensor.mirai_probe_temp_outdoor_c` | `uint16` | candidato outdoor | smentito come vera esterna |
| `1015` | `sensor.mirai_probe_counter_1015_raw` | `uint16` | contatore/probe diagnostico | candidato debole |
| `3547` | `sensor.mirai_probe_state_3547_raw`, `binary_sensor.mirai_pump_candidate_running` | `uint16` | probe storico di stato legato alla pompa/runtime | candidato secondario |
| `9007` | `sensor.mirai_discovery_pump_do4_9007_raw`, `binary_sensor.mirai_pump_do4_running` | `uint16` | stato DO4 Smart-MT, circolatore PdC | candidato forte |
| `9043` | `sensor.mirai_discovery_compressor_9043_raw` | `uint16` | segnale compressore 0-10V da ingresso remoto | candidato debole |
| `9051` | `sensor.mirai_discovery_target_9051_raw` | `uint16` | target attuale regolazione frequenza compressore (`L561`) | candidato forte |
| `9052` | `sensor.mirai_discovery_reference_9052_raw` | `uint16` | riferimento attuale regolazione frequenza compressore (`L562`) | candidato forte |
| `8986` | `sensor.mirai_discovery_outdoor_8986_raw` | `uint16` | outdoor air temperature da manuale (`L163`) | candidato vivo |
| `8987` | `sensor.mirai_discovery_outlet_8987_raw` | `uint16` | water outlet da manuale (`L162`) | candidato vivo |
| `8988` | `sensor.mirai_discovery_inlet_8988_raw` | `uint16` | water inlet da manuale (`L161`) | sospetto |
| `9121` | `sensor.mirai_discovery_power_absorbed_9121_raw` | `uint16` | potenza elettrica assorbita da manuale (`L302`) | smentito nel profilo reale |

## Corrispondenza con il manuale vendor

Il file vendor [manual_mirai_address.md](../../vendor/mirai/manual_mirai_address.md) e' coerente con il quadro runtime attuale in un punto importante:

- i registri stabili `1003 / 1208 / 1209` restano un namespace separato e gia' affidabile per `status / status code / fault`;
- la shortlist migliore per espandere il mapping non e' il cluster storico `3515 / 3547 / 3548 / 4000` da solo, ma il set documentato dal manuale Smart-MT.

### Registri manuale con migliore rispondenza pratica

| Registro | Etichetta manuale | Significato manuale | Valutazione attuale |
|---|---|---|---|
| `8986` | `L163` | outdoor air temperature | candidato vivo, ma scala fisica ancora da chiudere |
| `8987` | `L162` | water outlet from heat pump | candidato vivo, ma scala fisica ancora da chiudere |
| `8988` | `L161` | water inlet to heat pump | documentato, ma molto sospetto sul campo (`32768` fisso) |
| `9007` | `L204` | Smart-MT DO4, circulator | miglior candidato documentato per corroborazione pompa |
| `9043` | `L170` | 0-10 V compressor signal | documentato, ma non discriminante nel profilo reale osservato |
| `9051` | `L561` | current target temperature for compressor frequency adjustment | segnale utile e coerente nel profilo reale |
| `9052` | `L562` | current reference temperature for compressor frequency adjustment | segnale utile e coerente nel profilo reale |
| `9120..9123` | `L301..L312` | flow / electric / thermal power | documentati ma a zero nel profilo reale osservato |

### Effetto sul mapping corrente

- `3515` non va piu' considerato il candidato principale per outdoor, anche se resta esposto nel profilo stabile come probe storico.
- `3547` resta utile come segnale storico candidato di stato, ma `9007` ha priorita' piu' alta come verita' pompa, perche' e' descritto esplicitamente dal manuale ed e' coerente sul campo.
- `8986 / 8987 / 9007 / 9051 / 9052` sono oggi la shortlist canonica piu' utile di discovery/diagnostica.

## Status word 1003

### Bit osservati

| Bit | Entity | Semantica storica | Evidenza corrente | Stato |
|---|---|---|---|---|
| `bit 00` | `binary_sensor.mirai_status_word_bit_00` | non formalizzata storicamente | durante il run reale resta `on`; a macchina ferma puo' restare `on` con basso assorbimento | attivita' Modbus macchina, non run autonomo |
| `bit 01` | `binary_sensor.mirai_status_word_bit_01` | usato storicamente come run flag principale | nel run reale osservato il `bit 01` e' rimasto `off` | non affidabile come unico flag RUN |

### Conclusione operativa

- `bit 01` non deve piu' essere trattato come unica verita' di `RUN`.
- `bit 00` e' un segnale utile di attivita' Modbus macchina.
- `bit 00` da solo non basta a dichiarare `RUN`, perche' puo' restare alto anche a macchina quasi ferma.
- Il runtime attuale considera `bit 00` valido solo insieme a potenza reale.

## Run detection attuale

### Entita' base

- `binary_sensor.mirai_machine_running_by_power`
  - base potenza;
  - soglia helper: `input_number.mirai_running_power_on_w`;
  - oggi serve come conferma fisica primaria del run.

- `binary_sensor.mirai_machine_running`
  - vero se:
    - `bit 01 = on`, oppure
    - `bit 00 = on` e c'e' potenza reale, oppure
    - il fallback a potenza e' `on`.

- `sensor.mirai_machine_running_source`
  - `MODBUS_STATUS`: `bit 01` attivo;
  - `MODBUS_ACTIVITY_BIT00`: `bit 00` attivo con potenza reale;
  - `POWER_OVERRIDE`: run visto solo da potenza;
  - `MODBUS_IDLE`: link Modbus vivo ma nessun segnale run valido;
  - `POWER_FALLBACK`: fallback senza Modbus affidabile.

### Runtime truth multi-livello

| Livello | Significato |
|---|---|
| `idle` | nessuna finestra run valida |
| `power_only_run` | run visto solo dai consumi |
| `power_plus_modbus` | run visto da consumi + attivita' Modbus coerente |
| `fully_corroborated_run` | run confermato da consumi + Modbus + pompa (`9007`) |

## Evidenza runtime del 2026-04-08 / 2026-04-09

Finestra manuale controllata con setpoint alzato per forzare un run reale:

- richiesta heating coerente;
- ramo MIRAI coerente;
- macchina realmente partita con potenza oltre soglia;
- `status_word_effective = 1`;
- `status_bits_on = bit 00`;
- `bit 01 = off`;
- livello runtime truth corretto: `power_plus_modbus`;
- `9007` osservato in progressione `0 -> 1 -> 10`, coerente con startup e run;
- `9043` rimasto `10` sia fuori run sia in run;
- letture dirette fuori da HA, in `RUN`, via Modbus TCP:
  - `1003=1`
  - `1208=128`
  - `1209=32768`
  - `3515=117`
  - `3547=20992`
  - `8986=338/339`
  - `8987=284/285`
  - `8988=32768`
  - `9007=10`
  - `9043=10`
  - `9051=339`
  - `9052=340`
  - `9120=0`
  - `9121=0`
  - `9122=0`
  - `9123=0`
- test FC4 sugli stessi registri: `EXC:1` su tutti.

Conclusione:
- il remap semantico su `bit 00` e' giustificato;
- la corroborazione pompa va spostata da `3547` a `9007`;
- il mapping `bit 01 == RUN` e' da considerare superato come assunzione unica.
- `PW 59` nel manuale corretto indica il livello service HMI dello Smart-MT, non un unlock Modbus documentato.

## Elementi ancora non chiusi

| Oggetto | Stato | Nota |
|---|---|---|
| vera sonda outdoor MIRAI | aperto | `3515` non valida come esterna reale; `8986` resta il candidato vivo migliore |
| scala fisica `8987` | aperto | segnale vivo, ma semantica/scaling ancora da chiudere |
| semantica piena `3547` | aperto ma secondario | utile come storico, non piu' candidato principale pompa |
| significato vendor ufficiale di `bit 00` e `bit 01` | aperto | manca conferma documentale vendor numerica |

## Nuova shortlist di discovery

Ordine consigliato, read-only e uno per volta:

1. `8986`
2. `8987`
3. `9007`
4. `9051`
5. `9052`

Seconda fascia, solo dopo:

1. `8988`
2. `9043`
3. `9003`
4. `9004`
5. `9005`

Regola:
- nessun nuovo registro entra nel profilo stabile senza correlazione ripetuta con realta' fisica e runtime.

## Regole operative

- Non promuovere nuovi registri nel profilo stabile senza evidenza runtime.
- Non usare `bit 01` come unico criterio di `RUN`.
- Non usare `bit 00` come `RUN` puro senza potenza reale.
- Trattare `3515` come probe non validato, non come verita' meteo.
- Non assumere che `PW 59` sia una password Modbus: oggi il manuale la documenta solo come livello service HMI.

## Riferimenti

- [GOVERNANCE_MIRAI.md](../../GOVERNANCE_MIRAI.md)
- [manual_mirai_address.md](../../vendor/mirai/manual_mirai_address.md)
- [STEP50_MIRAI_RUNTIME_TRUTH_ADVISORY_2026-04-07.md](../../audits/STEP50_MIRAI_RUNTIME_TRUTH_ADVISORY_2026-04-07.md)
- [STEP51_MIRAI_MANUAL_RUN_WINDOW_PLAN_2026-04-07.md](../../audits/STEP51_MIRAI_MANUAL_RUN_WINDOW_PLAN_2026-04-07.md)
- [STEP53_MIRAI_BRANCH_POWER_AND_SOLAR_GAIN_CLOSURE_2026-04-07.md](../../audits/STEP53_MIRAI_BRANCH_POWER_AND_SOLAR_GAIN_CLOSURE_2026-04-07.md)
