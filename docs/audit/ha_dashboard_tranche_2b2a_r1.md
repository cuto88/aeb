# Tranche 2B.2a-R1 - deduplicazione ECLSS

- Data: 2026-08-03
- Repository: `cuto88/aeb`
- Branch: `main`
- Baseline commit: `34f5a3f45ad17a0c0a29677fc8d38fd3facd4f30`
- Ambito: ECLSS, Observability, Power Runtime e DHW

## Obiettivo

Alleggerire ECLSS consolidando contratti, planner, policy ACS e trend energetici
nelle dashboard proprietarie, senza cambiare entity ID, template, soglie,
navigation path o logiche Home Assistant.

## Baseline

La baseline dedicata e`:

`lovelace/_baseline/2026-08-03_dashboard_tranche_2b2a_r1_pre_move/`

Contiene:

- i quattro YAML Lovelace coinvolti;
- inventario globale degli entity ID;
- inventario dei navigation path;
- registrazioni dashboard;
- hash SHA-256.

Prima della tranche:

- dashboard operative registrate: 12;
- entity ID Lovelace globali: 429;
- navigation path distinti: 13;
- `Planner dry-run`, `Forecast and grid 24h` e `Planner and AEB 24h`:
  una occorrenza ciascuna, tutte in ECLSS;
- `AEB MVP DHW`: due card semanticamente sovrapposte, una in ECLSS e una in DHW;
- contratti ClimateOps: una card ECLSS sovrapposta alle card `State` e `Reasons`
  di Observability.

## Decisioni applicate

### Contracts

Observability / `Contracts` / `State` e `Reasons` resta la struttura canonica.
Cinque entita` della card ECLSS erano gia` rappresentate. Le tre mancanti,
tutte di stato, sono state aggiunte a `State`:

- `input_boolean.policy_vacation_mode`;
- `binary_sensor.cm_policy_vacation_mode`;
- `binary_sensor.cm_noncritical_loads_allowed`.

La card ECLSS `Contratti` e` stata rimossa solo dopo aver verificato che tutte
le sue otto entita` fossero rappresentate nella sezione canonica.

### AEB MVP DHW

La card operativa DHW preesistente e` rimasta strutturalmente invariata.
Le cinque entita` esclusive della card ECLSS sono state consolidate nella nuova
card `AEB MVP DHW — Runtime e diagnostica`:

- `sensor.climateops_aeb_mvp_last_outcome`;
- `counter.climateops_aeb_mvp_live_requests_total`;
- `counter.climateops_aeb_mvp_holds_total`;
- `input_text.climateops_aeb_mvp_last_action`;
- `input_datetime.climateops_aeb_mvp_last_action_ts`.

### Spostamenti puri

- `Planner dry-run` -> Power Runtime / `Planner`;
- `Forecast and grid 24h` -> Power Runtime / `Trend e KPI`;
- `Planner and AEB 24h` -> Power Runtime / `Trend e KPI`.

Le tre card sono strutturalmente identiche alle versioni della baseline.

## Risultato strutturale

- le cinque card originarie non sono piu` presenti in ECLSS;
- le tre card spostate compaiono una sola volta;
- la card operativa `AEB MVP DHW` compare una sola volta;
- la nuova card diagnostica contiene esattamente le cinque entita` autorizzate;
- tutte le otto entita` dei contratti ECLSS sono rappresentate in Observability;
- entity ID globali: 429 prima e 429 dopo, insieme invariato;
- navigation path: 13 prima e 13 dopo, insieme invariato;
- dashboard attive: 12 prima e 12 dopo;
- nessuna modifica a Passive House, Envelope, package, automazioni o sensori
  Notte 2.

## Validazioni locali

- parsing `yq`: PASS, 118 file;
- `yamllint 1.38.0`: PASS; restano soltanto warning storici fuori perimetro;
- gate Lovelace: PASS, `Active=12`, `TopLevel=12`;
- gate VMC: PASS;
- artifact policy: PASS;
- link documentali: PASS;
- `ops/gates_run_ci.ps1`: PASS, `ALL GATES PASSED`;
- confronto strutturale delle tre card spostate: PASS;
- confronto card DHW operativa: PASS, invariata;
- confronto entity ID e navigation path: PASS.

## Rollback

Ripristinare selettivamente i quattro YAML dalla baseline dedicata, rieseguire
parsing e quality gate e distribuire soltanto gli YAML Lovelace interessati.
Package, automazioni, helper e `configuration.yaml` non fanno parte del rollback.

## Provenienza operativa

- macchina operativa: Windows, clone pulita in
  `C:\Users\ds\Downloads\aeb-2b2a-staging`;
- source of truth: GitHub `cuto88/aeb`, branch `main`;
- runtime target: `mercurio-edge`, non ancora contattato in fase sorgente;
- macchina legacy: non contattata;
- deploy e modifiche runtime: non ancora eseguiti;
- commit e GitHub Actions: da compilare dopo la pubblicazione.
