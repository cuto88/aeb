# Step 53 - MIRAI branch power + solar gain closure

Date: 2026-04-07

## Scope

Chiusura del rumore runtime residuo dopo l'introduzione dei branch power globali
e conferma finale che il modulo `solar_gain_advisory` non e' piu' bloccato da
input non pronti in postura stagionale corrente.

## Modifiche applicate

1. `packages/mirai_templates.yaml`
   - aggiunti:
     - `binary_sensor.cm_modbus_mirai_expected_ready`
     - `binary_sensor.cm_modbus_mirai_posture_ok`
     - `sensor.cm_modbus_mirai_reason`
   - semantica:
     - `branch_powered_off` quando il ramo MIRAI e' volutamente disalimentato
     - `link_ready` quando il payload Modbus e' valido
     - `no_status_word_available` / `invalid_status_word_payload` per fault reali

2. `lovelace/climate_casa_unified_plancia.yaml`
   - vista interna `ClimateOps` arricchita con diagnostica Modbus MIRAI coerente
     con la postura hardware.

3. `lovelace/8_mirai_plancia.yaml`
   - aggiunti `expected`, `posture ok` e `reason` per il link Modbus MIRAI.

4. `lovelace/modbus_plancia.yaml`
   - stessa semantica esposta anche nella plancia tecnica Modbus.

## Esito operativo

- Il sistema ora distingue correttamente:
  - ramo MIRAI spento intenzionalmente (`branch_powered_off`)
  - link Modbus disponibile (`link_ready`)
  - fault/modello dati non valido

- `binary_sensor.cm_modbus_mirai_ready` resta un segnale fisico puro.
- `binary_sensor.cm_modbus_mirai_posture_ok` e `sensor.cm_modbus_mirai_reason`
  eliminano il rumore interpretativo quando il ramo e' spento da quadro.

## Limite noto

Questa chiusura non spegne il polling Modbus reale da sola.

Se `packages/mirai_modbus.yaml` e' caricato nel runtime, Home Assistant continua
a interrogare il bus anche con `cm_mirai_branch_powered = off`. Per azzerare
anche gli errori `Pymodbus: mirai` serve un'azione di profilo runtime:

- rimuovere/disattivare il transport `packages/mirai_modbus.yaml`
- oppure passare al profilo con transport escluso
- quindi fare restart del Core

Questo e' un tema separato dalla semantica runtime e non blocca ClimateOps o il
solar gain advisory.

## Chiusura solar gain

Con i fix introdotti in Step 52 e con i branch power globali:

- default finestre = chiuse
- AC branch off non blocca piu' gli input advisory
- `solar_gain_advisory` torna osservabile e non resta piu' su `inputs_not_ready`

Verdetto finale al 2026-04-07:

- guadagno solare valutabile: SI
- advisory bloccato da posture stagionali attuali: NO
