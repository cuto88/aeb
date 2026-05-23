# STEP117 - VMC delta UR hysteresis tuning (2026-05-22)

## Scope
- Ridurre le ore inutili a `vel_2` introducendo isteresi reale su `P1_delta_ur`.
- Nessun cambio su relè, writer o metering.
- Nessun tocco agli hardware backlog in standby.

## FACT

- La soglia base `P1_delta_ur` era gia` stata rialzata a un valore conservativo:
  - ON: `ur_in_media >= 55`
  - ON: `delta_ur >= 15`
- Il punto debole residuo era il margine di rilascio: la condizione restava troppo "secca" e poteva mantenere il boost piu` del necessario.
- E` stato introdotto un helper dedicato:
  - `binary_sensor.vmc_delta_ur_active`
- La nuova bandiera applica isteresi:
  - ON quando `ur_in_media >= 55` e `delta_ur >= 15`
  - OFF quando `ur_in_media <= 52` oppure `delta_ur <= 10`
  - `delay_off: 00:05:00`
- `sensor.ventilation_priority` usa ora questa bandiera invece del confronto diretto, quindi `P1_delta_ur` non dipende piu` da una semplice soglia istantanea.

## IPOTESI

- Confidenza alta: questa e` la correzione a miglior ROI dopo il verdetto sul `vel_2`.
- Confidenza media: il nuovo comportamento ridurra` le permanenze a `vel_2` senza introdurre regressioni visibili nel comfort, ma il runtime richiede ancora reload per conferma.

## DECISIONE

- Concludere il tuning policy-side di `P1_delta_ur` lato source.
- Tenere aperta solo la verifica runtime al prossimo reload.
- Lasciare invariati gli altri rami VMC.

## Residuo

- Se in futuro il boost risultasse ancora troppo frequente, il passo successivo sara` usare IAQ/CO2 reale, non toccare ancora i relè.
