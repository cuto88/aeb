# STEP76 - Field inspection closure status

Date: 2026-04-24
Scope: consolidate the field inspection findings collected after the field/sensor ROI audit and reduce the remaining unknowns to the true residual gaps.

This step does not change runtime logic and does not authorize purchases.

## FACT

- RS485 gateway cluster is now identified:
  - `.191`: `USR IOT serial-to-Ethernet converter`, `Type F0`, firmware `V5014`
  - `.190`: `Waveshare serial-to-Ethernet / Modbus gateway`, firmware `V1.486`
- Both gateways are in the inspectable corridor false ceiling near the LAN switch.
- Both gateways are powered from `Mean Well HDR-15-12` on a shared 12 V rail.
- `HDR-15-12` is sufficient for the documented gateway cluster load.
- Current 12 V distribution is direct split from PSU terminals with no branch fuse/protection.
- RS485 field topology is now known:
  - `.191` segment: daisy-chain `gateway -> SDM120 -> MIRAI`
  - `.190` segment: single downstream branch `gateway -> EHW`
- Termination resistors are reported as installed on both segments.
- RS485 cable family is Ethernet-like / RJ45, mostly shielded, mainly on dedicated conduit.
- Potential EMI-critical points remain in the panel and junction boxes.
- Main measurable electrical branches are now understood as:
  - `VMC`
  - `EHW`
  - `MIRAI`
  - shared `Toshiba AC / plenum`
- `MIRAI` and `Toshiba AC / plenum` are separate machine domains.
- Toshiba AC domain is evidenced by:
  - outdoor unit visible in photo: `RAS-2M18U2AVG-E`
  - indoor ducted family from manuals: `RAS-M*U2DVG-E`
- Wired window/door contacts are already installed on all serramenti, with tamper and collection in the garage junction box.
- The only remaining opening-state hardware gap is the garage main door sensor.
- Minimum viable CO2 physical posture is now clear:
  - `giorno`: 230 V yes, Ethernet/PoE yes, Wi-Fi yes
  - `matrimoniale`: 230 V yes, Ethernet/PoE yes, Wi-Fi yes

## IPOTESI

- Confidenza alta: the field/sensor unknown set is now small enough that hardware selection can be constrained without blind spots.
- Confidenza alta: the next ROI is not more discovery; it is integrating what is already physically present.
- Confidenza media: RS485 biasing is likely handled implicitly or left undocumented by the gateways, but this is no longer the dominant system risk.

## DECISIONE

- Mark the broad field inspection phase as `substantially closed`.
- Do not reopen generic discovery on gateways, panel branches or serramenti wiring.
- Keep only these residual open items:
  1. garage main door state sensor
  2. exact shield bonding policy
  3. exact RS485 lengths / stub confirmation
  4. explicit biasing confirmation only if a future bus issue appears
- Promote the next hardware-design boundary as:
  - existing wired serramenti contacts -> I/O integration plan
  - CO2 `giorno + matrimoniale` -> powered/network-ready first wave
  - shared Toshiba AC branch and MIRAI branch -> measurement boundary already known

## Remaining True Gaps

| item | status | impact | urgency |
|---|---|---|---|
| garage main door sensor | missing | medium | medium |
| RS485 shield bonding exact point | unknown | low-medium | backlog |
| RS485 exact cable lengths | unknown | low | backlog |
| RS485 biasing explicit proof | unknown | low unless faults appear | backlog |

## Next Step

DECISIONE
- Move from generic field discovery to implementation planning for:
  - wired contact aggregation/I-O boundary
  - CO2 first wave (`giorno`, `matrimoniale`)
  - measurement boundary formalization for `VMC`, `EHW`, `MIRAI`, `Toshiba AC`
