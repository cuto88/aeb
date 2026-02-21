# Governance MIRAI

## Sorgente ufficiale

L'integrazione MIRAI è governata esclusivamente dai file in `packages/`:

- `packages/mirai_core.yaml`
- `packages/mirai_modbus.yaml`
- `packages/mirai_templates.yaml`

Questi sono gli entrypoint ufficiali e unici per entità, modbus e template.

## Owner

- Owner tecnico: team HA (sistemista)
- Owner funzionale: team impianti

## Regole

1) In `packages/` non sono ammessi file `.bak` o backup.
2) Non usare include indiretti (`!include_dir_*`) per MIRAI.
3) Le sorgenti legacy `mirai/*.yaml` sono deprecate e vanno mantenute solo in `/_quarantine/`.
4) Ogni variazione deve passare `ha core check` prima del deploy.

## Riferimenti

- Quarantine log: `/_quarantine/20260120_cleanup/README.md`

## Contract Layer

Entità di contract (osservabilità dipendenze):
- `binary_sensor.contract_meteo_stub_active`
- `binary_sensor.contract_surplus_ok_defined`
- `binary_sensor.contract_actuators_defined`
- `sensor.contract_missing_entities`

Regola: prima di ogni migrazione → `sensor.contract_missing_entities` deve essere `OK`.
