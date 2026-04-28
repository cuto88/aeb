# STEP86 - VMC P1_delta_ur threshold tuning (2026-04-27)

## Scopo
Applicare il tuning minimo a massimo ROI emerso da `STEP85`, riducendo le permanenze troppo facili su `vel_2`.

## FACT
- `vel_2` è stata validata come attuazione reale.
- La persistenza prolungata dipendeva dalla policy `P1_delta_ur`.
- La regola precedente era:

`ur_in_media > 50 and (ur_in_media - ur_out) >= 10`

## DECISIONE
La regola viene rialzata a:

`ur_in_media >= 55 and (ur_in_media - ur_out) >= 15`

File modificato:
- `packages/climate_ventilation.yaml`

## Motivazione tecnica

## FACT
Con soglia precedente, in giornate primaverili con aria esterna moderatamente più secca:
- il trigger entrava facilmente;
- la condizione restava vera per ore;
- la VMC rimaneva spesso a `vel_2`.

## DECISIONE
Questo tuning:
- conserva la logica igrometrica;
- riduce i falsi "quasi-benefici";
- lascia invariati writer, relè e modello plancia.

## Impatto atteso

1. meno ore in `P1_delta_ur`;
2. più tempo in baseline `vel_1`;
3. nessun impatto su:
   - boost bagno `P1_boost_bagno`;
   - anti-secco;
   - freecooling;
   - modalità manuale.

## Rischio

## IPOTESI (confidenza alta)
Il rischio di regressione è basso perché:
- il cambiamento tocca una sola soglia logica;
- non modifica writer authority;
- non modifica attuazione hardware;
- non tocca la semantica delle altre priorità VMC.

## Verifica richiesta

## DECISIONE
Osservare per 24-48h almeno:
- `sensor.ventilation_priority`
- `sensor.ventilation_reason`
- `sensor.vmc_vel_target`
- `switch.vmc_vel_1`
- `switch.vmc_vel_2`
- `sensor.pm1_mss310_power_w_main_channel`

Verdetto atteso:
- meno attivazioni persistenti di `P1_delta_ur`;
- meno permanenza VMC in fascia `~70-73 W`;
- maggiore ritorno a baseline `~26 W` quando il beneficio igrometrico non è forte.
