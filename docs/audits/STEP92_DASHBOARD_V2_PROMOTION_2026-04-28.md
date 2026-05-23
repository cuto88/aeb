# STEP92 - Dashboard v2 promotion (2026-04-28)

## Scopo
Chiudere l'ambiguità tra plance legacy e plance `v2` per i domini VMC e AC.

## FACT
Esistevano coppie concorrenti:
- `02_air_loop_legacy.yaml` vs `02_air_loop.yaml`
- `04_cooling_loop_legacy.yaml` vs `04_cooling_loop.yaml`

## FACT
Entrambe le coppie erano in precedenza nascoste o comunque non governate come entrypoint ufficiali.

## IPOTESI (confidenza alta)
Se una plancia non è esposta e non è l'entrypoint effettivo del dominio, nel tempo diventa di fatto legacy anche se tecnicamente più nuova.

## DECISIONE
Promozione ufficiale:
- `02_air_loop.yaml` -> dashboard sidebar ufficiale `VMC`
- `04_cooling_loop.yaml` -> dashboard sidebar ufficiale `AC`

Declassamento:
- `02_air_loop_legacy.yaml` -> nascosta, marcata legacy
- `04_cooling_loop_legacy.yaml` -> nascosta, marcata legacy

## Effetto su configuration.yaml

### VMC
- `1-ventilazione`
  - titolo -> `1 Ventilazione (legacy)`
  - `show_in_sidebar: false`
- `1-ventilazione-v2`
  - titolo -> `VMC`
  - `show_in_sidebar: true`

### AC
- `3-ac`
  - titolo -> `3 Clima (legacy)`
  - `show_in_sidebar: false`
- `3-ac-v2`
  - titolo -> `AC`
  - `show_in_sidebar: true`

## Boundary

## FACT
Questo step non elimina i file legacy.

## DECISIONE
I file legacy restano:
- ripristinabili;
- confrontabili con la baseline `STEP87`;
- non più promossi come plance operative ufficiali.
