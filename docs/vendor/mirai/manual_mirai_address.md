# manual_mirai_address.md

# MIRAI Smart-MT address notes for Codex testing

Source basis:
- MIRAI-SMI manual, Smart-MT parameter list, pages with `Register (Base 0)` values.
- Adapted for the current local test context.
- This file is intentionally filtered to keep only items worth probing now.

Assumed local context:
- DHW / ACS is **not connected**
- Febos-Crono Master is **not installed**
- Focus is **read-first**, low-noise validation
- `Base 0` addresses are kept exactly as shown in the manual

---

## 1) Immediate high-priority candidates

These are the first registers worth testing because they are directly relevant to the current runtime and do not depend on excluded hardware.

| Label | Register (Base 0) | Type | Manual meaning | Practical note |
|---|---:|---|---|---|
| `L161` | `8988` | read | Water inlet temperature to heat pump | Strong candidate |
| `L162` | `8987` | read | Water outlet temperature from heat pump (`L114 + offset`) | Strong candidate |
| `L163` | `8986` | read | Outdoor air temperature (`L111 + offset`) | Strong candidate; best documented outdoor candidate |
| `L170` | `9043` | read | 0–10 V compressor signal from remote input | Candidate for compressor activity correlation |
| `L201` | `9003` | read | Digital output DO1 / Terminal Block output 203 (`Out P2`) | Output-state candidate |
| `L202` | `9004` | read | Digital output DO2 / Terminal Block output 204 (`Out W1`) | Output-state candidate |
| `L203` | `9005` | read | Digital output DO3 / Terminal Block output 205 (`Out U1`) | Output-state candidate |
| `L204` | `9007` | read | Digital output DO4 of Smart-MT (heat pump circulator) | Very interesting for pump corroboration |
| `L206` | `9002` | read | Digital output DO6 / Terminal Block output 202 (`Out M1 / Out M2`) | Secondary output-state candidate |
| `L211` | `9001` | read | Analog output AO1 / Terminal Block output 201 (`Out T1`) | Secondary analog-output candidate |

---

## 2) Offset / helper parameters linked to core temperatures

These are write/service parameters according to the manual.
Do **not** write them in live runtime unless explicitly entering a controlled test window.

| Label | Register (Base 0) | Type | Manual meaning | Use |
|---|---:|---|---|---|
| `C160` | `9024` | write/service | Auto-alignment procedure for HP inlet/outlet water probes | Avoid for now |
| `C161` | `16394` | write/service | Offset for HP inlet water temperature | Read doc only |
| `C162` | `16392` | write/service | Offset for HP outlet water temperature | Read doc only |
| `C163` | `16393` | write/service | Offset for outdoor air temperature | Read doc only |

---

## 3) Excluded now: ACS / DHW

The manual exposes DHW-related points, but they are not relevant in the current plant because ACS is not connected.

| Label | Register (Base 0) | Type | Manual meaning | Status |
|---|---:|---|---|---|
| `L164` | `8989` | read | Domestic hot water temperature | Exclude now |
| `C164` | `16395` | write/service | DHW temperature offset | Exclude now |

---

## 4) Excluded now: Febos-Crono Master dependent signals

These depend on Febos-Crono Master, which is not installed locally.

| Label | Register (Base 0) | Type | Manual meaning | Status |
|---|---:|---|---|---|
| `L167` | `9146` | read | Indoor room temperature (Febos-Crono Master) | Exclude now |
| `L168` | `9147` | read | Indoor relative humidity (Febos-Crono Master) | Exclude now |
| `L169` | `9148` | read | Indoor dew point (Febos-Crono Master) | Exclude now |
| `L181` | `9151` | read | Room temperature not satisfied consent | Exclude now |
| `L182` | `9066` | read | Booster consent | Exclude now unless proven wired independently |
| `L183` | `9152` | read | High humidity consent | Exclude now |
| `L184` | `9153` | read | Season selected on Febos-Crono (`On = winter`) | Exclude now |

---

## 5) Alarm history block

Potentially useful, but not first priority for runtime truth closure.

| Label range | Register range (Base 0) | Type | Manual meaning | Priority |
|---|---|---|---|---|
| `L311..L318` | `9110..9117` | read | Alarm history slots | Medium |

---

## 6) Operational interpretation for the current MIRAI mapping work

### Likely useful now
- `8986` outdoor air temperature
- `8987` outlet water temperature
- `8988` inlet water temperature
- `9007` circulator output state
- `9043` compressor analog signal
- `9003`, `9004`, `9005`, `9002`, `9001` as output-state probes

### Explicitly not useful now
- DHW / ACS points
- Febos-Crono Master points
- service write parameters
- anything requiring recipe-specific peripherals unless later validated

---

## 7) Suggested probe order

1. `8986` -> outdoor candidate
2. `8987` -> leaving water
3. `8988` -> entering water
4. `9007` -> pump state corroboration
5. `9043` -> compressor activity correlation
6. `9003`, `9004`, `9005`, `9002`, `9001` -> output-state exploration
7. `9110..9117` -> alarm history only if needed

---

## 8) Testing rules

- Keep reads only on first pass
- Keep `base 0` addressing
- Compare every probe against known runtime signals and physical reality
- Do not promote a register into the stable profile without repeated evidence
- Do not write `Cxxx` service parameters in live runtime

---

## 9) Minimal Codex-ready target list

```yaml
manual_candidates:
  read_now:
    - 8986   # L163 outdoor air temperature
    - 8987   # L162 outlet water temperature
    - 8988   # L161 inlet water temperature
    - 9007   # L204 Smart-MT DO4 circulator
    - 9043   # L170 compressor 0-10V signal
    - 9003   # L201 DO1 / Out P2
    - 9004   # L202 DO2 / Out W1
    - 9005   # L203 DO3 / Out U1
    - 9002   # L206 DO6 / Out M1/M2
    - 9001   # L211 AO1 / Out T1
  exclude_now:
    - 8989   # L164 ACS/DHW temp
    - 16395  # C164 ACS/DHW offset
    - 9146   # L167 Febos-Crono room temp
    - 9147   # L168 Febos-Crono RH
    - 9148   # L169 Febos-Crono dew point
    - 9151   # L181 Febos room temp consent
    - 9066   # L182 booster consent (likely Febos dependent)
    - 9152   # L183 high humidity consent
    - 9153   # L184 season from Febos
  write_service_do_not_touch_live:
    - 9024   # C160 auto-alignment procedure
    - 16394  # C161 inlet water offset
    - 16392  # C162 outlet water offset
    - 16393  # C163 outdoor offset
```

---

## 10) Notes against current experimental mapping

Cross-check reminders versus current experimental mapping:
- documented outdoor candidate from manual: `8986`
- documented leaving water: `8987`
- documented entering water: `8988`
- current experimental outdoor candidate `3515` should not be preferred over `8986`
- current stable status/fault words (`1003`, `1208`, `1209`) remain a separate proven namespace

End of file.
