#!/usr/bin/env python3
"""Autonomous MIRAI watcher.

Reads Home Assistant states from a local SQLite snapshot refreshed via SCP
(`home-assistant_v2.db`). When `sensor.mirai_power_w` exceeds a
threshold for consecutive polls, runs `mirai_scan_runtime.py` automatically.
"""

from __future__ import annotations

import argparse
import csv
import sqlite3
import subprocess
import sys
import time
from datetime import datetime
from pathlib import Path


def run(cmd: list[str]) -> tuple[int, str]:
    p = subprocess.run(cmd, capture_output=True, text=True)
    out = (p.stdout or "") + (p.stderr or "")
    return p.returncode, out.strip()


def validate_sqlite(db_path: Path) -> None:
    con = sqlite3.connect(f"file:{db_path}?mode=ro&immutable=1", uri=True)
    cur = con.cursor()
    row = cur.execute("pragma quick_check;").fetchone()
    con.close()
    if not row or str(row[0]).lower() != "ok":
        raise RuntimeError(f"sqlite quick_check failed: {row}")


def refresh_db_snapshot(args: argparse.Namespace, retries: int = 3) -> Path:
    remote_db = "/homeassistant/home-assistant_v2.db"
    last_error = "unknown"

    for _ in range(retries):
        tmp_db = args.local_dir / f"home-assistant_v2.db.{int(time.time() * 1000)}.snap"

        cmd = [
            args.scp,
            "-P",
            str(args.ssh_port),
            "-i",
            args.ssh_key,
            f"{args.ssh_user}@{args.ssh_host}:{remote_db}",
            str(tmp_db),
        ]
        rc, out = run(cmd)
        if rc != 0:
            last_error = f"copy failed: {out}"
            time.sleep(0.4)
            continue

        try:
            validate_sqlite(tmp_db)
            return tmp_db
        except Exception as exc:
            last_error = str(exc)
            time.sleep(0.4)

    raise RuntimeError(f"failed to refresh db snapshot: {last_error}")


def ensure_base_db(args: argparse.Namespace) -> None:
    # Warm-up probe to fail fast on SSH/SCP misconfiguration.
    snap = refresh_db_snapshot(args)
    if snap.exists():
        try:
            snap.unlink()
        except Exception:
            pass


def cleanup_old_snapshots(local_dir: Path, keep: int = 6) -> None:
    snaps = sorted(local_dir.glob("home-assistant_v2.db.*.snap"), key=lambda p: p.stat().st_mtime, reverse=True)
    for stale in snaps[keep:]:
        try:
            stale.unlink()
        except Exception:
            pass


def get_state(db_path: Path, entity_id: str) -> tuple[str | None, str | None]:
    con = sqlite3.connect(f"file:{db_path}?mode=ro&immutable=1", uri=True)
    cur = con.cursor()
    row = cur.execute(
        """
        select s.state, datetime(s.last_updated_ts,'unixepoch','localtime')
        from states s
        join states_meta m on m.metadata_id=s.metadata_id
        where m.entity_id=?
        order by s.state_id desc
        limit 1
        """,
        (entity_id,),
    ).fetchone()
    con.close()
    if not row:
        return None, None
    return row[0], row[1]


def append_event(csv_path: Path, row: list[str]) -> None:
    exists = csv_path.exists()
    csv_path.parent.mkdir(parents=True, exist_ok=True)
    with csv_path.open("a", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        if not exists:
            w.writerow(
                [
                    "ts",
                    "event",
                    "mirai_power_w",
                    "machine_running",
                    "status_word_raw",
                    "status_code_raw",
                    "fault_code_raw",
                    "note",
                ]
            )
        w.writerow(row)


def start_scan(args: argparse.Namespace, out_dir: Path) -> tuple[int, str]:
    stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    out_csv = out_dir / f"mirai_scan_auto_{stamp}.csv"
    cmd = [
        sys.executable,
        str(args.scan_script),
        "--host",
        args.scan_host,
        "--port",
        str(args.scan_port),
        "--profile",
        args.scan_profile,
        "--rounds",
        str(args.scan_rounds),
        "--interval",
        str(args.scan_interval),
        "--timeout",
        str(args.scan_timeout),
        "--units",
        str(args.scan_units),
        "--functions",
        str(args.scan_functions),
        "--output",
        str(out_csv),
    ]
    p = subprocess.run(cmd, capture_output=True, text=True)
    txt = (p.stdout or "") + (p.stderr or "")
    return p.returncode, txt


def safe_float(v: str | None) -> float:
    if v is None:
        return 0.0
    try:
        return float(v)
    except Exception:
        return 0.0


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--ssh-host", default="192.168.178.84")
    parser.add_argument("--ssh-port", type=int, default=2222)
    parser.add_argument("--ssh-user", default="root")
    parser.add_argument("--ssh-key", default=r"C:\Users\randalab\.ssh\ha_ed25519")
    parser.add_argument("--scp", default=r"C:\Windows\System32\OpenSSH\scp.exe")
    parser.add_argument("--poll-seconds", type=int, default=30)
    parser.add_argument("--power-threshold", type=float, default=450.0)
    parser.add_argument("--consecutive-polls", type=int, default=3)
    parser.add_argument("--cooldown-minutes", type=int, default=45)
    parser.add_argument("--scan-profile", default="quick", choices=["quick", "full"])
    parser.add_argument("--scan-rounds", type=int, default=10)
    parser.add_argument("--scan-interval", type=int, default=20)
    parser.add_argument("--scan-timeout", type=float, default=0.35)
    parser.add_argument("--scan-host", default="192.168.178.191")
    parser.add_argument("--scan-port", type=int, default=502)
    parser.add_argument(
        "--scan-units",
        default="1",
        help="comma-separated unit IDs passed to mirai_scan_runtime.py",
    )
    parser.add_argument(
        "--scan-functions",
        default="3",
        help="comma-separated FCs passed to mirai_scan_runtime.py",
    )
    parser.add_argument("--workspace", default=".")
    args = parser.parse_args()

    root = Path(args.workspace).resolve()
    local_dir = root / "tmp" / "ha_snapshot"
    local_dir.mkdir(parents=True, exist_ok=True)
    args.local_dir = local_dir
    args.scan_script = root / "ops" / "mirai_scan_runtime.py"
    log_csv = root / "tmp" / "mirai_autowatch_events.csv"
    scans_dir = root / "tmp" / "mirai_auto_scans"
    scans_dir.mkdir(parents=True, exist_ok=True)

    ensure_base_db(args)

    hi_count = 0
    last_trigger_ts = 0.0

    print(
        f"autowatch started poll={args.poll_seconds}s threshold={args.power_threshold}W "
        f"consecutive={args.consecutive_polls} cooldown={args.cooldown_minutes}m"
    )
    while True:
        ts = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        try:
            snap_db = refresh_db_snapshot(args)
            pwr_s, _ = get_state(snap_db, "sensor.mirai_power_w")
            run_s, _ = get_state(snap_db, "binary_sensor.mirai_machine_running")
            sw_s, _ = get_state(snap_db, "sensor.mirai_status_word_raw")
            sc_s, _ = get_state(snap_db, "sensor.mirai_status_code_raw")
            fc_s, _ = get_state(snap_db, "sensor.mirai_fault_code_raw")
            cleanup_old_snapshots(args.local_dir)

            pwr = safe_float(pwr_s)
            if pwr >= args.power_threshold:
                hi_count += 1
            else:
                hi_count = 0

            print(f"[{ts}] power={pwr_s}W run={run_s} hi_count={hi_count}")
            append_event(
                log_csv,
                [ts, "poll", str(pwr_s), str(run_s), str(sw_s), str(sc_s), str(fc_s), ""],
            )

            cooldown_ok = (time.time() - last_trigger_ts) >= (args.cooldown_minutes * 60)
            if hi_count >= args.consecutive_polls and cooldown_ok:
                append_event(
                    log_csv,
                    [
                        ts,
                        "trigger_scan",
                        str(pwr_s),
                        str(run_s),
                        str(sw_s),
                        str(sc_s),
                        str(fc_s),
                        "threshold reached",
                    ],
                )
                rc, txt = start_scan(args, scans_dir)
                note = f"scan_rc={rc} out={len(txt)} chars"
                append_event(
                    log_csv,
                    [ts, "scan_done", str(pwr_s), str(run_s), str(sw_s), str(sc_s), str(fc_s), note],
                )
                print(f"[{ts}] scan launched -> {note}")
                last_trigger_ts = time.time()
                hi_count = 0

        except Exception as exc:
            print(f"[{ts}] watcher_error: {exc}")
            append_event(log_csv, [ts, "error", "", "", "", "", "", str(exc)])

        time.sleep(args.poll_seconds)


if __name__ == "__main__":
    raise SystemExit(main())
