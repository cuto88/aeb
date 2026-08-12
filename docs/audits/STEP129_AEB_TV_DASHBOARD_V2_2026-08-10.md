# STEP129 - AEB TV Dashboard v2.0.0

Data: 2026-08-10

## Obiettivo e audit iniziale

La baseline canonica `cuto88/aeb:main` era la dashboard TV v1.0.1: griglia
nativa 4 colonne, testo desktop-size, grandi vuoti e due menu che esponevano
direttamente anche dashboard tecniche. Il collaudo fisico TCL Full HD ha
confermato leggibilita, proporzioni, contrasto e focus insufficienti a 2-4 m.

Il runtime operativo e `mercurio-edge` (`192.168.178.110`), Home Assistant
Core 2026.4.4 in Docker, container `homeassistant`, bind mount
`/opt/data/homeassistant` -> `/config`. La macchina legacy non e stata
contattata.

## Dipendenze frontend

| Risorsa | File runtime | Registrata Lovelace | Scelta |
|---|---:|---:|---|
| kiosk-mode | no | no | non installata |
| card-mod | no | no | non installata |
| custom:button-card | no | no | non installata |
| layout-card | si | no | non usata |

`configuration.yaml` registra soltanto `mini-graph-card`. Nessuna dipendenza e
stata installata o registrata per questa modifica. La v2 usa esclusivamente
`picture-elements`, `grid`, `button`, `entities` e un tema Home Assistant.

Il query parameter `?kiosk` non viene dichiarato operativo: richiede
`kiosk-mode`, assente. Sidebar/header devono essere gestiti dall'app Android TV
o dalla modalita fullscreen del client fino a una decisione di governance
separata sulla dipendenza kiosk.

## Pre-mortem

| Failure mode | Causa probabile | Segnale precoce | Contromisura |
|---|---|---|---|
| testo ancora piccolo | card desktop-centriche | KPI illeggibili a 2 m | valori 80-88 px sul canvas |
| D-pad/focus inutilizzabile | elementi grafici non focusable | focus ambiguo | soli button nativi nella barra di navigazione |
| layout che scrolla | altezza non vincolata | footer fuori viewport | SVG 1920x780 + singola barra, test 1080p/768p |
| custom card incompatibile | risorsa non registrata | custom element missing | nessuna custom card nuova |
| bella su PC, mediocre TCL | densita desktop | vuoti/testo piccolo dalla posizione reale | safe area, gerarchia 10-foot, collaudo fotografico |
| comando accidentale | controllo diretto home | un OK modifica stato | home read-only, comandi dopo subview dedicata |

## Layout implementato

La home e una HMI dark-first composta da:

- header AEB/CASA con stato sintetico, ora e temperatura esterna;
- quattro KPI dominanti: temperatura interna, umidita, esterna e FV;
- tre macro-aree: Clima, VMC, Energia;
- fascia stato/avviso e versione discreta;
- barra D-pad regolare a sei pulsanti: Menu, Clima, VMC, Energia, ACS, Azioni.

Il fondale SVG definisce superfici, label e safe area. I valori sono overlay
Home Assistant dinamici. Le subview operative usano controlli nativi e il menu
tecnico e raggiungibile solo attraverso un secondo livello.

## Entity ID home

- sintesi: `sensor.aeb_tv_stato_casa`,
  `sensor.aeb_tv_avviso_prioritario`;
- presentazione: `sensor.aeb_tv_ora`,
  `sensor.aeb_tv_temperatura_interna`,
  `sensor.aeb_tv_umidita_interna`,
  `sensor.aeb_tv_temperatura_esterna`, `sensor.aeb_tv_potenza_fv`,
  `sensor.aeb_tv_consumo_casa`, `sensor.aeb_tv_scambio_rete`;
- clima: `sensor.ac_priority`, `sensor.heating_priority`;
- VMC: `sensor.ventilation_priority`, `sensor.ventilation_reason`.

I sensori di presentazione formattano esclusivamente dati canonici e rendono
`unknown`, `unavailable` o null come `—`; non aggiungono soglie o decisioni.

## Controlli operativi esposti

- climatizzazione: setpoint e modalita giorno/notte;
- riscaldamento: setpoint, modalita manuale e timer esistenti;
- VMC: modalita, manuale, velocita, boost bagno e timer esistenti;
- Domestic Ops: stato bucato, stesura, tipo e carico.

Non sono esposti relay diretti, raw Modbus, writer ACS tecnico, restart, deploy,
bypass, dry-run o override permanenti. ACS resta in supervisione finche non
esiste un helper quotidiano distinto dal boundary tecnico del writer.

## File modificati

- `lovelace/13_stato_casa_tv.yaml`;
- `packages/aeb_tv_supervision.yaml`;
- `themes/aeb_tv.yaml`;
- `www/aeb-tv/home-v2.svg`;
- `docs/audits/STEP129_AEB_TV_DASHBOARD_V2_2026-08-10.md`.

## Test e deploy

- parsing YAML: PASS;
- parsing XML SVG: PASS;
- `ops/gates_run_ci.ps1`: PASS con `yamllint` 1.38.0 temporaneo;
- warning CI: soltanto linee lunghe preesistenti fuori scope;
- check configurazione HA pre-deploy: PASS;
- backup runtime: `/config/_aeb_tv_backup_20260810_v200_hmi`;
- deploy: si, chirurgico sui quattro artefatti runtime;
- check configurazione HA post-copia: PASS;
- restart: si, solo container `homeassistant`, necessario per i sensori template;
- container post-restart: `running`;
- dashboard HTTP: 200;
- registry: sensori KPI e `sensor.aeb_tv_ora` presenti, non disabilitati;
- verifica evento-level: non applicabile, nessun attuatore comandato nel deploy;
- source of truth: PR draft da creare, nessun merge automatico.

Path dashboard: `/13-stato-casa-tv/stato-casa`.

URL LAN: `http://192.168.178.110:8123/13-stato-casa-tv/stato-casa`.

## Checklist collaudo TCL

- [ ] riavviare l'app TV per svuotare il vecchio stato frontend;
- [ ] verificare fullscreen e annotare se sidebar/header restano visibili;
- [ ] verificare assenza di scroll a 1920x1080;
- [ ] leggere i quattro KPI dalla posizione reale;
- [ ] verificare stato Clima/VMC/Energia in tre secondi;
- [ ] verificare colore e leggibilita dell'avviso;
- [ ] percorrere la barra con LEFT/RIGHT senza salti;
- [ ] verificare un solo focus evidente;
- [ ] aprire Clima e tornare con BACK;
- [ ] aprire VMC e tornare con BACK;
- [ ] eseguire un controllo sicuro temporizzato;
- [ ] verificare dark mode di giorno e di sera;
- [ ] scattare foto dalla stessa posizione del collaudo precedente;
- [ ] ripetere il controllo a 1366x768 se disponibile.

## Limiti aperti

- collaudo fotografico TCL ancora necessario;
- fullscreen/kiosk non imponibile dal repository senza una dipendenza frontend
  oggi assente;
- focus dei button nativi dipende dal WebView/app TCL e va validato fisicamente;
- nessun comando ACS manuale esposto perche manca un helper quotidiano sicuro;
- PR draft da creare e lasciare non mergiata.
