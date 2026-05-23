# STEP118 - VMC delta UR thermal veto (2026-05-23)

## Scope
- Evitare che `P1_delta_ur` spinga `vel_2` quando l'aria esterna e` termicamente sfavorevole.
- Nessun cambio su relè, writer o metering.

## FACT

- `P1_delta_ur` era gia` stato reso meno persistente con isteresi:
  - helper `binary_sensor.vmc_delta_ur_active`
  - ON: `ur_in_media >= 55` e `delta_ur >= 15`
  - OFF: `ur_in_media <= 52` oppure `delta_ur <= 10`
  - `delay_off: 00:05:00`
- Rimaneva il rischio che l'aria piu` secca ma piu` calda continuasse a caricare termicamente la massa interna.
- E` stato quindi aggiunto un veto termico esplicito nella priority:
  - `P1_delta_ur` vale solo se `delta_t_in_out >= 0.5`
- In altre parole:
  - se fuori e` piu` caldo dell'interno, `P1_delta_ur` non deve alzare la ventilazione;
  - il sistema cade su baseline invece di imporre boost igrometrico controproducente.

## IPOTESI

- Confidenza alta: questo e` il freno giusto dopo l'osservazione del rischio di surriscaldamento.
- Confidenza media: il veto termico ridurra` i casi in cui la VMC asciuga ma scalda troppo la massa interna.

## DECISIONE

- Concludere il tuning di sicurezza su `P1_delta_ur`.
- Tenere `vel_2` disponibile solo quando il segnale igrometrico non entra in conflitto con il segnale termico.
- Lasciare invariati gli altri rami VMC.

## Residuo

- Se in futuro serviranno decisioni piu` fini, il passo successivo sara` una policy multimetrica piu` ricca, non un ulteriore allentamento di questo veto.
