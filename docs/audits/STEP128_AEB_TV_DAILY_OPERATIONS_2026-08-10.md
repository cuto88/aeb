# STEP128 - Operativita quotidiana dalla TV

Data: 2026-08-10

## Obiettivo

Evoluzione della dashboard TV da plancia read-only a interfaccia a due livelli:

1. comprensione dello stato della casa in circa 3 secondi;
2. accesso intenzionale alle operazioni domestiche comuni in circa 30 secondi.

La supervisione resta prioritaria. Stato e azioni sono separati e nessun comando
e disponibile direttamente sulla home.

## Scelte operative

- home: Stato generale, Clima, Energia, VMC, ACS e Azioni;
- subview di stato: sole entita di sintesi, senza tap operativo;
- subview Azioni: primo passaggio intenzionale verso Clima, VMC o Bucato;
- VMC: modalita, manuale, velocita e boost bagno gia protetti dai timer esistenti;
- clima: soli setpoint e modalita AC gia limitati dagli helper esistenti;
- riscaldamento: setpoint e manuale solo con timer/failsafe gia esistenti;
- Domestic Ops: soli helper bucato gia previsti dal sistema;
- ACS: sola supervisione. Il writer disponibile e un boundary tecnico di cutover,
  quindi non viene reinterpretato come richiesta manuale quotidiana.

Sono stati rimossi dalla navigazione TV i launcher verso Fieldbus, Observability,
MIRAI e le dashboard tecniche. Non sono esposti relay, switch AC diretti, restart,
service call, writer, dry-run, cutover, bypass o override permanenti.

## Provenienza operativa

- macchina operativa: workspace Windows `C:\2_OPS\aeb`;
- runtime target dichiarato: `mercurio-edge`, Home Assistant Core Docker,
  container `homeassistant`, bind mount `/opt/data/homeassistant` -> `/config`;
- runtime target verificato o toccato: si, `mercurio-edge` via LAN;
- macchina legacy: non contattata;
- accesso usato: filesystem locale, LAN, SSH e Docker;
- deploy eseguito: si, chirurgico sul solo file
  `lovelace/13_stato_casa_tv.yaml`;
- modifiche runtime eseguite: si, backup
  `/config/_aeb_tv_backup_20260810_tv_ops_v2`, sostituzione del solo YAML TV;
- validazione pre-deploy: container `running`, config check PASS;
- validazione post-deploy: SHA-256 locale/runtime
  `8d930116be6b3d4e996167d1152d5cc97a9a34664d36f12e5532496b4ac048b5`,
  config check PASS, container `running`, dashboard HTTP 200;
- riavvio Home Assistant: no, non necessario per la dashboard YAML;
- GitHub commit / Actions: nessuno in questa fase.

## Collaudo residuo

Resta il collaudo manuale sulla TCL/Android TV con telecomando: leggibilita a
3 secondi, navigazione senza scroll e modifica intenzionale di un helper per
ciascuna subview operativa. Non eseguire prove su comandi ACS tecnici, che non
sono esposti.

## Esito collaudo TV e rollback

Il collaudo reale ha rilevato caricamento infinito della dashboard dopo il
login sul frontend TV e una resa grafica non accettabile. La v2 e stata quindi
ritirata dal runtime.

- rollback runtime: si, solo `lovelace/13_stato_casa_tv.yaml`;
- versione ripristinata: baseline v1.0.1, SHA-256
  `3f393e3ba14ff4126e023a511621a7a1b8902e07ee75dae94781ab1fd1d7f1e5`;
- copia della v2 fallita conservata in
  `/config/_aeb_tv_backup_20260810_tv_ops_v2/lovelace/13_stato_casa_tv.v2_failed_tv_loading.yaml`;
- config check post-rollback: PASS;
- container: `running`;
- riavvio: no;
- stato: nuova progettazione TV necessaria prima di un altro deploy.

## Redesign v2.1

Dopo aver confermato che il loading infinito era dovuto allo stato dell'app TV
e si risolveva riavviandola, la dashboard e stata riprogettata usando soltanto
card native gia presenti nella baseline funzionante.

- home fissa 4 x 3, senza scroll;
- eliminate tutte le card `heading`;
- quattro indicatori primari, quattro ingressi di dominio, tre riepiloghi e un
  solo ingresso `AZIONI`;
- subview di stato e operative mantenute separate;
- backup pre-v2.1: `/config/_aeb_tv_backup_20260810_v210`;
- SHA-256 locale/runtime v2.1:
  `aa7d7ee76447b99b58a08bf7a5c3eecf3c28a47d0065b1e74ee412948b8046fa`;
- config check post-deploy: PASS;
- container: `running`;
- dashboard HTTP: 200;
- riavvio Home Assistant: no;
- collaudo visivo TV v2.1: in attesa.
