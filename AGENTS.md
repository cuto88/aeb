# AGENTS.md

## Session Bootstrap (Casa Mercurio)

- Ambiente Home Assistant runtime: `root@192.168.178.84`
- Porta SSH: `2222`
- Accesso primario: chiave SSH locale `C:\Users\randalab\.ssh\ha_ed25519`
- Fallback: `C:\Users\randalab\.ssh\ha_fallback_ed25519`
- Percorso config HA da usare come default: `/homeassistant`
- Nota: se `/homeassistant` non contiene `configuration.yaml`, provare `/config`

## Comandi SSH rapidi (read-only)

- Test connessione:
  - `ssh -p 2222 -i C:\Users\randalab\.ssh\ha_ed25519 root@192.168.178.84 "hostname && whoami"`
  - `ssh -p 2222 -i C:\Users\randalab\.ssh\ha_fallback_ed25519 root@192.168.178.84 "hostname && whoami"`
- Verifica file deployato:
  - `ssh -p 2222 -i C:\Users\randalab\.ssh\ha_ed25519 root@192.168.178.84 "sed -n '1,220p' /homeassistant/packages/climateops/actuators/system_actuator.yaml"`
- Verifica tracce recenti (automation ClimateOps):
  - `ssh -p 2222 -i C:\Users\randalab\.ssh\ha_ed25519 root@192.168.178.84 "grep -n \"climateops_system_actuate\" /homeassistant/.storage/trace.saved_traces | tail -n 20"`
- Verifica eventi AC recenti (logbook/trace export locale se disponibile):
  - esportare da UI trace/logbook e salvare in `docs/runtime_evidence/<date>/`

## Regola operativa

- Per audit runtime post-deploy, preferire sempre evidenza evento-level con correlazione `context_id` tra:
  - `automation.climateops_system_actuate`
  - `script.ac_giorno_apply` / `script.ac_notte_apply`
  - stato `switch.ac_giorno` / `switch.ac_notte`
