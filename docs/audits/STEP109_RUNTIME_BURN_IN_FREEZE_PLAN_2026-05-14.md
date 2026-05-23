# STEP109 - Runtime burn-in freeze plan (2026-05-14)

Scope: congelare il perimetro Home Assistant dopo la stabilizzazione recente e validarlo con burn-in operativo senza refactor.

## Obiettivo
- Non cambiare la logica.
- Verificare che il sistema regga 24h e 7d senza regressioni.
- Conservare solo le modifiche difensive gia' introdotte.
- Eseguire il burn-in in automatico via `n8n`, non via task scheduler Windows.

## Finestra di burn-in
- Inizio: 2026-05-14
- Checkpoint 24h: 2026-05-15
- Checkpoint 7d: 2026-05-21

## Cosa resta fermo
- Nessun refactor su package, dashboard o helper.
- Nessuna rinomina di entita' o bridge.
- Nessuna riduzione ulteriore di recorder/logbook senza evidenza runtime nuova.
- Nessuna modifica ai writer AC/DHW se non per regressioni dimostrate.

## Evidenza da raccogliere ogni giorno
- `ops/phase4_daily_runtime_report.ps1`
- `ops/aeb_runtime_audit_snapshot.ps1`
- `ops/phase6_no_go_guard.ps1`
- `ops/phase7_executive_status.ps1`

## Gate di uscita
### Dopo 24h
- `ha core check` PASS
- `template.validators` = 0 nel log recente
- `statistics` = 0 nel log recente
- `history_stats` = 0 nel log recente
- nessun errore nuovo su `automation.climateops_system_actuate`
- nessun errore nuovo su `script.telegram_ha_mercurio_send`

### Dopo 7d
- stessi gate delle 24h
- nessun degrado di `recorder` o `logbook`
- nessun drift nuovo su `sensor.planner_recommended_mode`, `sensor.arbiter_suggested_mode`, `sensor.arbiter_suggested_reason`
- nessuna regressione sui writer `switch.ac_giorno`, `switch.ac_notte`, `switch.heating_master`

## Comandi operativi
- Importare o riallineare il workflow:
  - `n8n/workflows/aeb_supervisor_readonly_mvp.json`
- Installare il task giornaliero:
  - `.\ops\phase5_schedule_daily_report.ps1 -Action Install -StartTime 07:30`
- Verificare lo stato del task:
  - `.\ops\phase5_schedule_daily_report.ps1 -Action Status`
- Eseguire un run immediato:
  - `.\ops\phase5_schedule_daily_report.ps1 -Action RunNow`
- Fallback portabile se Windows Scheduled Tasks rifiuta l'installazione:
  - `.\ops\phase5_burn_in.ps1 -Action Start -StartTime 07:30`
  - `.\ops\phase5_burn_in.ps1 -Action Status`
  - `.\ops\phase5_burn_in.ps1 -Action RunNow`
  - `.\ops\phase5_burn_in.ps1 -Action Stop`

## Automatic path
- Primary: `n8n` workflow scheduled daily at `07:30`.
- Secondary: host-side PowerShell runner only if n8n is unavailable.

## Criterio di freeze
Se i gate 24h e 7d passano, il perimetro resta fermo e si riapre solo per:
- nuovi errori runtime
- nuovo drift segreti/sicurezza
- regressione writer o recorder
