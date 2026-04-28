# STEP84 - VMC speed 2 runtime audit (2026-04-27)

## Scopo
Capire se `vmc_vel_target = 2` ha effetto reale oppure se è solo un livello logico che lascia la VMC accesa "senza cambiare davvero".

## Sintesi

## FACT
L'audit di oggi mostra che:
- `vel_2` è realmente attuata;
- `vel_2` non è equivalente a `vel_1`;
- la permanenza prolungata su `2` oggi è coerente con la logica `P1_delta_ur`, non con un bug già dimostrato.

## DECISIONE
Per oggi il verdetto corretto è:

`VMC level 2 = EFFECTIVE AND PERSISTENT BY POLICY`

Non c'è evidenza che `2` sia un "falso livello".

---

## Evidenza live

Campione live interrogato via HA API durante l'audit:

## FACT
- `sensor.vmc_vel_target = 2`
- `sensor.vmc_vel_index = 2`
- `sensor.vmc_active_speed_proxy = 2`
- `binary_sensor.vmc_is_running_proxy = on`
- `switch.vmc_vel_0 = off`
- `switch.vmc_vel_1 = off`
- `switch.vmc_vel_2 = on`
- `switch.vmc_vel_3 = off`
- `sensor.pm1_mss310_power_w_main_channel = 70.33 W`
- `sensor.vmc_power_mean_15m = 72.21 W`
- `sensor.vmc_power_max_24h = 158.78 W`
- `sensor.ventilation_priority = P1_delta_ur`
- `sensor.ventilation_reason = P1 – aria esterna più secca (ΔUR)`
- `input_boolean.climateops_cutover_vmc = off`
- `input_select.vmc_mode = auto`
- `input_boolean.vmc_manual = off`

## DECISIONE
Questo campione mostra che:
- il writer legacy VMC è attivo;
- il relè `switch.vmc_vel_2` è effettivamente ON;
- la macchina assorbe una potenza coerente con uno stato diverso dal baseline `vel_1`.

---

## Evidenza igrometrica che giustifica la persistenza

## FACT
Campione live contestuale:
- `sensor.ur_in_media = 55.0 %`
- `sensor.ur_out = 38 %`
- `sensor.delta_ah_in_out = 2.29 g/m3`
- `sensor.delta_t_in_out = -2.52 C`
- `sensor.t_in_med = 22.98 C`
- `sensor.t_out_effective = 25.5 C`
- `binary_sensor.vmc_sensors_ok = on`

## FACT
La logica in `packages/climate_ventilation.yaml` promuove `P1_delta_ur` quando:

`ur_in_media > 50 and (ur_in_media - ur_out) >= 10`

e mappa `P1_delta_ur -> vmc_vel_target = 2`.

## DECISIONE
Con i valori live di oggi:
- `55 - 38 = 17`
- quindi la condizione `P1_delta_ur` è soddisfatta con margine.

La permanenza a `2` è quindi spiegata dalla policy attuale, non da un actuation gap già dimostrato.

---

## Evidenza storica di giornata

## FACT
History API ultime ~8h:
- `switch.vmc_vel_1` era ON fino a `2026-04-27 08:28`
- `switch.vmc_vel_2` è passato ON a `2026-04-27 08:28`
- `switch.vmc_vel_2` è andato OFF a `2026-04-27 11:16`
- il target è andato a `0` alle `11:16` per finestra `P0_failsafe`
- `switch.vmc_vel_2` è tornato ON a `2026-04-27 11:26`
- da allora è rimasto attivo fino al campione live

## FACT
Nello stesso storico:
- prima di `08:28`, con `vel_1`, la potenza PM1 stava tipicamente attorno a `26 W`
- dopo il passaggio a `vel_2`, la potenza PM1 si stabilizza tipicamente nell'ordine `70-73 W`

## DECISIONE
Questo è il punto chiave dell'audit:
- `vel_2` produce un delta di potenza molto netto rispetto a `vel_1`;
- quindi `2` non è solo "VMC comunque accesa", ma uno stato fisico distinguibile.

---

## Limiti dell'audit

## FACT
Il feedback "velocità reale" oggi è ancora composto da:
- relè `switch.vmc_vel_*`
- proxy `sensor.vmc_active_speed_proxy`
- metering PM1

Non c'è ancora:
- feedback elettrico dedicato in quadro;
- feedback nativo macchina che certifichi RPM/portata reali.

## DECISIONE
L'audit chiude la domanda "il livello 2 ha effetto?" con un **sì**.
Non chiude invece il livello "quanto varia davvero la portata aria macchina" perché manca ancora feedback macchina-grade.

---

## Diagnosi

## FACT
Il sistema oggi non sembra bloccato in un loop spurio su `2`.
Sembra invece mantenere `2` perché la policy `P1_delta_ur` resta vera per molte ore.

## IPOTESI (confidenza media-alta)
Se la tua percezione è che la VMC "resti troppo accesa", il nodo da rivedere non è l'attuazione `vel_2`, ma:
- la soglia `ur_in_media > 50`
- la soglia differenziale `(ur_in_media - ur_out) >= 10`
- l'assenza di una componente CO2 reale che limiti decisioni troppo solo-igrometriche

## DECISIONE
Il prossimo step corretto, se vuoi ridurre le ore a `2`, non è cercare un bug di relè:
- è un tuning audit della policy `P1_delta_ur`.

---

## Verdetto finale

1. ## FACT
   `vmc_vel_2` oggi è realmente attuato.
   ## DECISIONE
   Nessuna evidenza di "speed 2 finta".

2. ## FACT
   `vel_2` ha una firma di potenza distinta da `vel_1` (`~70-73 W` vs `~26 W`).
   ## DECISIONE
   Il livello 2 ha effetto reale.

3. ## FACT
   La persistenza di oggi è coerente con `P1_delta_ur`.
   ## DECISIONE
   Il problema, se c'è, è di policy/tuning, non di output VMC non funzionante.
