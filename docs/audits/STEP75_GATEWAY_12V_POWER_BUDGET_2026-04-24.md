# STEP75 - Gateway 12V power budget and consolidation posture

Date: 2026-04-24
Scope: register the real 12 V DC supply for the RS485/Ethernet gateways, calculate conservative current budget, and decide whether gateway consolidation has technical ROI.

This step does not change runtime logic and does not authorize a hardware swap by itself.

## FACT

- Two serial/Ethernet gateways are physically co-located:
  - inspectable false ceiling in the corridor
  - near the LAN switch
- Current devices:
  - `192.168.178.191`: `USR IOT serial-to-Ethernet converter`, `Type F0`, firmware `V5014`
  - `192.168.178.190`: `WAVESHARE` serial-to-Ethernet / Modbus gateway, firmware `V1.486`
- Current serial profiles are different:
  - USR / MIRAI+SDM120 path: `9600 8E1`
  - Waveshare / EHW path: `9600 8N1`
- Both gateways are powered from the same 12 V DC source already available in the project:
  - `Mean Well HDR-15-12`
  - rated output: `12 V DC`, `1.25 A`, `15 W`
  - recommended continuous design target from project constraints: `0.8-1.0 A`, about `9.6-12 W`
- The 12 V rail is upstream-switched by a smart switch for intentional remote reboot/power-cycle.
- Current 12 V distribution is simple and direct:
  - `V+` / `V-` from the PSU are split directly into two branches
  - branch 1 -> USR gateway `.191`
  - branch 2 -> Waveshare gateway `.190`
  - no dedicated branch fuse/protection is currently installed
- Current reference distribution follows the same chained logic as the serial field wiring:
  - `A` to `A`
  - `B` to `B`
  - `GND` to `GND`
- Vendor power references available:
  - Waveshare `RS232/485 TO ETH`: operating current `86.5 mA @ 5 V`, power `<1 W` (official product page)
  - USR industrial serial server family page (`USR-N520` reference): working current `45 mA @ 12 V`, power `<1 W` (official vendor page)

## IPOTESI

- Confidenza media: the exact USR model power may differ slightly from the vendor reference family page, but it is still clearly a sub-1 W class device.
- Confidenza alta: for budgeting, a conservative engineering allowance is better than using the absolute minimum catalog current.
- Confidenza alta: consolidating both gateways into one device would reduce component count only marginally, while increasing migration risk and creating a stronger single point of failure.
- Confidenza media: a single dual-port industrial serial server could replace both only if it supports independently configurable serial ports and preserves the current Modbus behaviors.

## DECISIONE

- Treat `HDR-15-12` as the canonical 12 V DC source for the gateway cluster.
- Keep the two existing gateways for now.
- Do not unify gateways only for power saving.
- Use conservative budget values, not optimistic catalog minima.

## Conservative Current Budget

### Input constraints

- PSU nominal maximum: `1.25 A @ 12 V`
- Recommended continuous operating band: `0.8-1.0 A`
- Recommended continuous power band: `9.6-12 W`

### Component budget

| component | source | nominal / known data | conservative design budget @12V | notes |
|---|---|---|---:|---|
| USR gateway `.191` | vendor family reference + field config | `45 mA @ 12 V`, `<1 W` | `0.10 A` | rounded up for design margin |
| Waveshare gateway `.190` | official product page | `<1 W`, `86.5 mA @ 5 V` | `0.10 A` | rounded up for design margin |
| 12 V rail distribution margin | engineering margin | cabling / startup / unknown small overhead | `0.05 A` | margin only |
| **total current budget** |  |  | **0.25 A** | |
| **total power budget** |  |  | **3.0 W** | |

### Result

- Remaining headroom vs recommended `0.8 A` continuous target:
  - `0.55 A`
  - about `6.6 W`
- Remaining headroom vs recommended `1.0 A` continuous target:
  - `0.75 A`
  - about `9.0 W`
- Remaining headroom vs absolute PSU maximum `1.25 A`:
  - `1.00 A`
  - about `12 W`

## Sufficiency verdict

DECISIONE
- `HDR-15-12` is sufficient for the currently documented gateway cluster.
- `HDR-30-12` is **not** required for the current known load.

DECISIONE
- Upgrade to `HDR-30-12` only if the same 12 V rail is later expanded with meaningful extra loads such as:
  - relay banks
  - solenoids / valves
  - motorized actuators
  - multiple always-on controllers
  - sustained load beyond about `1.0 A` continuous or high inrush peaks

## Consolidation posture: one gateway vs two

### Technical reading

FACT
- The two current segments are not identical:
  - different devices
  - different serial framing (`8E1` vs `8N1`)
  - different operational semantics (`transparent serial server` vs explicit `Modbus TCP to RTU gateway`)

IPOTESI (confidenza alta)
- A future single-device replacement would only be acceptable if it provides:
  - two independent serial channels/ports
  - per-port serial configuration
  - equivalent Modbus stability
  - at least the same or better electrical robustness

DECISIONE
- Do not consolidate now just to save energy.
- Current energy saving opportunity from consolidation is too small to justify migration risk.
- Two separate gateways currently provide fault containment between MIRAI/SDM120 and EHW.

## 12V topology

Textual scheme:

`230 V AC -> smart upstream switch -> Mean Well HDR-15-12 -> fused 12 V DC distribution -> USR gateway (.191) + Waveshare gateway (.190)`

Recommended 12 V distribution rules:

- keep separate `+12V` and `GND` terminals
- add low-side or branch protection/fuse for each outgoing 12 V branch if external wiring leaves the local protected area
- keep 230 V AC and 12 V DC physically separated
- document polarity at each gateway
- avoid using the smart switch as the normal control path; use it only for exceptional recovery/reboot

Current field status:

- direct split from PSU terminals: `ACCEPTABLE FOR CURRENT LOW LOAD`
- no branch fuse/protection: `OPEN HARDENING ITEM`
- no documented DIN terminal distribution block yet: `OPEN HARDENING ITEM`

## Next boundary

DECISIONE
- The next useful physical data is not a new PSU purchase.
- The next useful physical data is:
  - decide whether to add branch protection on the 12 V side
  - decide whether to replace direct split with DIN terminal distribution
  - document bus order and termination
  - document whether the smart upstream switch is accessible, local-only or cloud-dependent
