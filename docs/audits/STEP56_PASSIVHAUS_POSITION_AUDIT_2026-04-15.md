# STEP56 Passivhaus Position Audit (2026-04-15)

## Scope
- Valutare la posizione corrente del repository `aeb` rispetto a una traiettoria `Passivhaus`.
- `Passivhaus` qui significa: priorita` ai comportamenti passivi dell’involucro e uso prudente degli impianti come layer successivo, non principale.

## Passivhaus definition used here
- Per questo repo `Passivhaus` non significa certificazione formale.
- Il livello minimo difendibile e`:
  - lettura credibile dei segnali passivi
  - distinzione tra casa media e stanza peggiore
  - uso sensato di free-cooling / night flush / shading advisory
  - impianti trattati come supporto, non come primo riflesso automatico

## FACT

### 1. Il fronte involucro e` ormai un filone vero del repo
- Esistono:
  - advisory `envelope_*`
  - advisory `solar_gain_*`
  - vista operatore `Passive House`
  - runbook/checklist involucro
  - script di snapshot audit dedicato
- Quindi il repo non ragiona piu` solo in termini impiantistici.

### 2. L’audit ultimi 7 giorni conferma hotspot locali reali
- L’audit `STEP54` mostra che:
  - `notte2` e` la stanza peggiore dominante
  - `bagno` e` secondo hotspot reale
  - `t_in_med` da sola e` troppo rassicurante
- Questo e` esattamente il tipo di lettura che serve a una postura `Passivhaus-like`: prima capire il comportamento passivo reale, poi decidere l’intervento.

### 3. Il sistema distingue gia` posture passive sensate
- Distribuzione osservata su 7 giorni:
  - `keep_closed`
  - `prepare_night_flush`
  - `open_for_night_flush`
- Anche `night_flush_potential` si muove tra `none / low / high`, quindi il modello non e` monolitico.

### 4. Il fronte `solar gain` non e` ancora chiuso
- Il modulo e` presente e operativo come advisory.
- La calibrazione per uso decision-grade resta aperta.
- Questa prudenza e` corretta: chiudere troppo presto `solar gain` sarebbe anti-Passivhaus, perche' significherebbe automatizzare prima di aver capito bene l’involucro.

### 5. L’AC non e` oggi la lente giusta per leggere la settimana
- Gli switch AC nella finestra osservata non sono informativi.
- Questo rafforza l’idea che il lavoro utile ora sia sull’involucro e non su una lettura impianto-centrica.

## RISKS
- Basarsi troppo su `t_in_med` e perdere il problema stanza-per-stanza.
- Fare tuning `solar gain` o shading troppo presto.
- Scambiare `night flush advisory plausibile` con `night flush fisicamente validato abbastanza`.
- Usare l’AC come scorciatoia prima di aver chiuso meglio il comportamento passivo di `notte2` e `bagno`.

## DRIFT
- Nessun drift forte tra direzione `Passive House` della UI e i dati della settimana.
- Drift ancora presente tra:
  - advisory passivo ragionevole
  - evidenza operatore completa su finestre/scuri/azioni umane
- In altre parole:
  - la teoria passiva e` presente
  - la closure osservativa sul campo non e` ancora completa

## JUDGEMENT

### Passivhaus posture
- `GOOD ADVISORY / NOT YET CLOSED`

### Why
- Il repo sta gia` privilegiando una lettura passiva reale:
  - stanza peggiore
  - night flush
  - passive gain
  - involucro room model
- Pero` non e` ancora “chiuso” perche':
  - il comportamento passivo non e` ancora abbastanza consolidato con evidenza umana ripetuta
  - `solar gain` e` ancora in calibrazione
  - il night flush e` promettente ma non ancora forensically closed

## Practical conclusion
- Oggi il repo e` piu` vicino a una postura `Passivhaus-aware` che a un controllo HVAC classico.
- Il fronte giusto non e` spingere subito altra automazione attiva.
- Il fronte giusto e` consolidare:
  - `notte2` come stanza sentinella
  - `bagno` come hotspot secondario
  - finestra utile di `night flush`
  - distinzione tra carico passivo e interferenza impianto

## NEXT ACTION
1. Continuare il mini-ciclo audit involucro stanza-per-stanza.
2. Validare meglio `night flush` con stato finestre/scuri annotato.
3. Tenere `solar gain` in `HOLD` finche' la lettura passiva non e` piu` difendibile.
4. Aggiornare il judgement `Passivhaus` solo dopo evidenza multi-finestra meglio annotata.
