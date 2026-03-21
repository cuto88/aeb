#!/usr/bin/env python3
"""Quick Modbus runtime scanner for MIRAI validation windows."""

from __future__ import annotations

import argparse
import csv
import socket
import time
from pathlib import Path
from typing import Iterable


def read_register(host: str, port: int, unit: int, fc: int, addr: int, timeout: float) -> int | None:
    tx = int(time.time() * 1000) & 0xFFFF
    req = bytes(
        [
            (tx >> 8) & 0xFF,
            tx & 0xFF,
            0,
            0,
            0,
            6,
            unit,
            fc,
            (addr >> 8) & 0xFF,
            addr & 0xFF,
            0,
            1,
        ]
    )

    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.settimeout(timeout)
    try:
        sock.connect((host, port))
        sock.sendall(req)
        data = sock.recv(260)
        if len(data) >= 11 and data[7] == fc:
            return (data[9] << 8) + data[10]
        return None
    except Exception:
        return None
    finally:
        sock.close()


def parse_csv_ints(value: str) -> list[int]:
    return [int(x.strip()) for x in value.split(",") if x.strip()]


def resolve_addresses(profile: str) -> list[int]:
    if profile == "quick":
        return sorted(
            {
                1000,
                1001,
                1002,
                1003,
                1013,
                1015,
                1023,
                1208,
                1209,
                3500,
                3503,
                3504,
                3507,
                3508,
                3515,
                3522,
                3524,
                3526,
                3532,
                3533,
                3537,
                3541,
                3542,
                3546,
                3547,
                3548,
                3549,
                4000,
                4001,
                9050,
                9086,
                9087,
            }
        )

    return sorted(
        {
            *range(995, 1061),
            *range(1198, 1221),
            *range(3490, 3561),
            *range(3990, 4051),
            9050,
            9086,
            9087,
        }
    )


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", default="192.168.178.191")
    parser.add_argument("--port", type=int, default=502)
    parser.add_argument("--interval", type=int, default=20, help="seconds between rounds")
    parser.add_argument("--rounds", type=int, default=15, help="number of rounds")
    parser.add_argument("--timeout", type=float, default=0.35)
    parser.add_argument("--profile", choices=["quick", "full"], default="quick")
    parser.add_argument(
        "--units",
        default="1",
        help="comma-separated unit IDs (default aligned to active HA config)",
    )
    parser.add_argument(
        "--functions",
        default="3",
        help="comma-separated FCs (default aligned to active HA config)",
    )
    parser.add_argument("--output", default="tmp/mirai_scan_changes.csv")
    args = parser.parse_args()

    units = parse_csv_ints(args.units)
    fcs = parse_csv_ints(args.functions)
    addrs = resolve_addresses(args.profile)

    out_path = Path(args.output)
    out_path.parent.mkdir(parents=True, exist_ok=True)

    probes_per_round = len(units) * len(fcs) * len(addrs)
    print(
        f"scan_config profile={args.profile} units={units} fcs={fcs} "
        f"addrs={len(addrs)} probes_per_round={probes_per_round}"
    )

    with out_path.open("w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(["ts", "round", "unit", "fc", "addr", "old", "new"])

        baseline: dict[tuple[int, int, int], int] = {}
        for r in range(1, args.rounds + 1):
            current: dict[tuple[int, int, int], int] = {}
            for unit in units:
                for fc in fcs:
                    for addr in addrs:
                        val = read_register(args.host, args.port, unit, fc, addr, args.timeout)
                        if val is not None:
                            current[(unit, fc, addr)] = val

            ts = time.strftime("%Y-%m-%d %H:%M:%S")
            if r == 1:
                print(f"[{ts}] round={r} responding={len(current)} (baseline)")
            else:
                changes = 0
                for key, new_val in current.items():
                    if key in baseline and baseline[key] != new_val:
                        unit, fc, addr = key
                        w.writerow([ts, r, unit, fc, addr, baseline[key], new_val])
                        changes += 1
                print(f"[{ts}] round={r} responding={len(current)} changes={changes}")

            baseline = current
            if r < args.rounds:
                time.sleep(args.interval)

    print(f"saved: {out_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
