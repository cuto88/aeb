# P0 Restore Drill Pass

Date: 2026-06-22

## Contesto

Eseguito un restore drill minimo e read-only dello snapshot remoto Home Assistant in una
cartella temporanea locale. Nessun deploy, nessuna modifica runtime, nessun uso di SSH o
HA API.

## Provenance

| Campo | Valore |
| --- | --- |
| Operator machine | `DS-WORK` |
| Runtime target | `none / local restore drill only` |
| Legacy machine status | `DS-01 powered off` |
| Access mode | `local filesystem only` |
| Deploy | `none` |
| Runtime changes | `none` |
| Source snapshot | `ha_runtime_snapshot_20260622_121348` |

## Percorsi

- Source snapshot: `C:\2_OPS\_repo_archives\aeb\_dr_backups\ha_runtime_snapshot_20260622_121348`
- Restore test target: `C:\2_OPS\_restore_tests\aeb_20260622`
- Local drill report: `C:\2_OPS\_restore_tests\aeb_20260622\RESTORE_DRILL_REPORT.md`

## Verifiche eseguite

- esistenza snapshot sorgente: PASS
- creazione pulita del target temporaneo: PASS
- copia locale del contenuto: PASS
- presenza `configuration.yaml`: PASS
- presenza `packages`: PASS
- presenza `lovelace`: PASS
- presenza `automations.yaml` nello snapshot: assente, atteso
- presenza `scripts.yaml` nello snapshot: assente, atteso
- assenza path esclusi: PASS

## File e cartelle presenti

- file ripristinati: `2608`
- cartelle ripristinate: `65`

Elementi minimi confermati:

- `configuration.yaml`
- `packages`
- `lovelace`

Elementi opzionali non presenti nello snapshot ispezionato:

- `automations.yaml`
- `scripts.yaml`

## Esclusioni confermate

- `.storage`
- `secrets.yaml`
- `home-assistant_v2.db`
- `home-assistant_v2.db-*`
- `.cache`
- `backups`
- `_codex_backups`

## Verdict

PASS

## Rischi residui

- il test e` filesystem-only, non un restore live di Home Assistant
- la presenza o assenza di `automations.yaml` e `scripts.yaml` va interpretata come
  dipendente dal contenuto dello snapshot, non come errore del drill
- un restore operativo completo resta un test separato se richiesto da future procedure
