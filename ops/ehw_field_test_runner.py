#!/usr/bin/env python3
"""Minimal assisted EHW field-test runner."""

from __future__ import annotations

import argparse
import csv
import sqlite3
import subprocess
import sys
import time
from datetime import datetime
from pathlib import Path


ENTITIES = [
    "binary_sensor.cm_modbus_ehw_ready",
    "sensor.ehw_tank_top",
    "sensor.ehw_tank_bottom",
    "sensor.ehw_setpoint_raw_a",
    "sensor.ehw_setpoint_raw_b",
    "sensor.ehw_setpoint_raw_calc",
    "sensor.ehw_setpoint",
    "binary_sensor.ehw_running",
]


def run(cmd: list[str]) -> tuple[int, str]:
    proc = subprocess.run(cmd, capture_output=True, text=True)
    out = (proc.stdout or "") + (proc.stderr or "")
    return proc.returncode, out.strip()


def refresh_db_snapshot(ssh_port: int, ssh_key: str, ssh_user: str, ssh_host: str, local_dir: Path) -> Path:
    remote_db = "/homeassistant/home-assistant_v2.db"
    local_dir.mkdir(parents=True, exist_ok=True)
    snap = local_dir / f"home-assistant_v2.db.{int(time.time() * 1000)}.snap"
    cmd = [
        r"C:\Windows\System32\OpenSSH\scp.exe",
        "-P",
        str(ssh_port),
        "-i",
        ssh_key,
        f"{ssh_user}@{ssh_host}:{remote_db}",
        str(snap),
    ]
    rc, out = run(cmd)
    if rc != 0:
        raise RuntimeError(f"SCP failed: {out}")
    return snap


def cleanup_old_snapshots(local_dir: Path, keep: int = 4) -> None:
    snaps = sorted(local_dir.glob("home-assistant_v2.db.*.snap"), key=lambda p: p.stat().st_mtime, reverse=True)
    for stale in snaps[keep:]:
        try:
            stale.unlink()
        except OSError:
            pass


def fetch_states(db_path: Path, entities: list[str]) -> list[dict[str, str]]:
    con = sqlite3.connect(f"file:{db_path}?mode=ro&immutable=1", uri=True)
    cur = con.cursor()
    rows: list[dict[str, str]] = []
    for entity_id in entities:
        row = cur.execute(
            """
            select s.state,
                   datetime(s.last_updated_ts,'unixepoch','localtime')
            from states s
            join states_meta m on m.metadata_id = s.metadata_id
            where m.entity_id = ?
            order by s.state_id desc
            limit 1
            """,
            (entity_id,),
        ).fetchone()
        if row:
            state, last_updated = row
            rows.append(
                {
                    "entity_id": entity_id,
                    "state": "" if state is None else str(state),
                    "last_updated_local": "" if last_updated is None else str(last_updated),
                }
            )
        else:
            rows.append(
                {
                    "entity_id": entity_id,
                    "state": "__MISSING__",
                    "last_updated_local": "",
                }
            )
    con.close()
    return rows


def write_csv(path: Path, rows: list[dict[str, str]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=["capture_ts_local", "entity_id", "state", "last_updated_local"])
        writer.writeheader()
        writer.writerows(rows)


def write_summary(path: Path, baseline_start: str, baseline_end: str, rows: list[dict[str, str]]) -> None:
    lines = [
        "# EHW Field Test Baseline Summary",
        "",
        f"- baseline_start: `{baseline_start}`",
        f"- baseline_end: `{baseline_end}`",
        f"- sample_count: `{len(rows)}`",
        "",
        "## Latest sample by entity",
        "",
        "| Entity | State | Last updated |",
        "|---|---|---|",
    ]
    latest: dict[str, dict[str, str]] = {}
    for row in rows:
        latest[row["entity_id"]] = row
    for entity_id in ENTITIES:
        row = latest.get(entity_id, {"state": "__MISSING__", "last_updated_local": ""})
        lines.append(f"| `{entity_id}` | `{row['state']}` | `{row['last_updated_local']}` |")
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def latest_by_entity(rows: list[dict[str, str]]) -> dict[str, dict[str, str]]:
    latest: dict[str, dict[str, str]] = {}
    for row in rows:
        latest[row["entity_id"]] = row
    return latest


def load_csv_rows(path: Path) -> list[dict[str, str]]:
    with path.open("r", newline="", encoding="utf-8") as handle:
        return list(csv.DictReader(handle))


def find_latest_file(out_dir: Path, pattern: str) -> Path:
    matches = sorted(out_dir.glob(pattern), key=lambda p: p.stat().st_mtime, reverse=True)
    if not matches:
        raise FileNotFoundError(f"No file matching {pattern} in {out_dir}")
    return matches[0]


def write_post_summary(
    path: Path,
    event_ts: str,
    capture_start: str,
    capture_end: str,
    baseline_latest: dict[str, dict[str, str]],
    post_rows: list[dict[str, str]],
) -> dict[str, dict[str, str]]:
    first_changes: dict[str, dict[str, str]] = {}
    unchanged: list[str] = []
    latest_post = latest_by_entity(post_rows)

    for entity_id in ENTITIES:
        baseline_value = baseline_latest[entity_id]["state"]
        changed = None
        for row in post_rows:
            if row["entity_id"] != entity_id:
                continue
            if row["state"] != baseline_value:
                changed = row
                break
        if changed is not None:
            first_changes[entity_id] = changed
        else:
            unchanged.append(entity_id)

    ordered = sorted(first_changes.values(), key=lambda row: row["capture_ts_local"])
    readiness_ok = all(
        row["state"] == "on" for row in post_rows if row["entity_id"] == "binary_sensor.cm_modbus_ehw_ready"
    )
    raw_a_changed = "sensor.ehw_setpoint_raw_a" in first_changes
    raw_b_changed = "sensor.ehw_setpoint_raw_b" in first_changes
    ambiguity = []
    if raw_a_changed and raw_b_changed:
        ambiguity.append("both raw_a and raw_b changed")
    elif not raw_a_changed and not raw_b_changed:
        ambiguity.append("neither raw_a nor raw_b changed")
    if "sensor.ehw_setpoint" not in first_changes:
        ambiguity.append("scaled setpoint did not change")

    lines = [
        "# EHW Field Test Post-Change Summary",
        "",
        f"- event_timestamp_used: `{event_ts}`",
        f"- post_capture_start: `{capture_start}`",
        f"- post_capture_end: `{capture_end}`",
        f"- readiness_stayed_on: `{'yes' if readiness_ok else 'no'}`",
        "",
        "## First-change order",
        "",
    ]
    if ordered:
        for row in ordered:
            lines.append(f"- `{row['capture_ts_local']}` {row['entity_id']} -> `{row['state']}`")
    else:
        lines.append("- no state change observed against baseline values")

    lines += [
        "",
        "## Changed vs unchanged",
        "",
        "Changed:",
    ]
    if first_changes:
        for entity_id in ENTITIES:
            if entity_id in first_changes:
                row = first_changes[entity_id]
                lines.append(f"- `{entity_id}` baseline `{baseline_latest[entity_id]['state']}` -> `{row['state']}`")
    else:
        lines.append("- none")

    lines += [
        "",
        "Unchanged:",
    ]
    if unchanged:
        for entity_id in unchanged:
            lines.append(f"- `{entity_id}` stayed `{baseline_latest[entity_id]['state']}`")
    else:
        lines.append("- none")

    lines += [
        "",
        "## Ambiguity",
        "",
    ]
    if ambiguity:
        for item in ambiguity:
            lines.append(f"- {item}")
    else:
        lines.append("- none observed")

    path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    return {
        "first_changes": first_changes,
        "latest_post": latest_post,
        "readiness_ok": {"value": "yes" if readiness_ok else "no"},
        "ambiguity": {"value": "; ".join(ambiguity) if ambiguity else ""},
    }


def update_state_table(
    path: Path,
    event_ts: str,
    baseline_start: str,
    observation_end: str,
    baseline_latest: dict[str, dict[str, str]],
    analysis: dict[str, dict[str, str]],
) -> None:
    rows = load_csv_rows(path)
    first_changes = analysis["first_changes"]
    latest_post = analysis["latest_post"]
    ambiguity_value = analysis["ambiguity"]["value"]

    for row in rows:
        entity_id = row["entity_id"]
        row["event_timestamp"] = event_ts
        row["baseline_start"] = baseline_start
        row["observation_end"] = observation_end
        row["baseline_value"] = baseline_latest[entity_id]["state"]
        row["baseline_ts"] = baseline_latest[entity_id]["capture_ts_local"]
        if entity_id in first_changes:
            row["first_change_ts"] = first_changes[entity_id]["capture_ts_local"]
            row["changed_yn"] = "Y"
        else:
            row["first_change_ts"] = ""
            row["changed_yn"] = "N"
        row["post_change_value"] = latest_post[entity_id]["state"]
        row["post_change_ts"] = latest_post[entity_id]["capture_ts_local"]
        if entity_id in ("sensor.ehw_setpoint_raw_a", "sensor.ehw_setpoint_raw_b", "sensor.ehw_setpoint_raw_calc", "sensor.ehw_setpoint"):
            row["ambiguity_note"] = ambiguity_value
        else:
            row["ambiguity_note"] = ""

    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(
            handle,
            fieldnames=[
                "event_label",
                "event_timestamp",
                "baseline_start",
                "observation_end",
                "entity_id",
                "baseline_value",
                "baseline_ts",
                "first_change_ts",
                "post_change_value",
                "post_change_ts",
                "changed_yn",
                "ambiguity_note",
            ],
        )
        writer.writeheader()
        writer.writerows(rows)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--ssh-host", default="192.168.178.84")
    parser.add_argument("--ssh-port", type=int, default=2222)
    parser.add_argument("--ssh-user", default="root")
    parser.add_argument("--ssh-key", default=r"C:\Users\randalab\.ssh\ha_ed25519")
    parser.add_argument("--workspace", default=".")
    parser.add_argument("--date", default=datetime.now().strftime("%Y-%m-%d"))
    parser.add_argument("--mode", choices=["baseline", "post"], default="baseline")
    parser.add_argument("--baseline-seconds", type=int, default=300)
    parser.add_argument("--post-seconds", type=int, default=900)
    parser.add_argument("--interval-seconds", type=int, default=30)
    parser.add_argument("--event-ts", default="")
    args = parser.parse_args()

    root = Path(args.workspace).resolve()
    out_dir = root / "docs" / "runtime_evidence" / args.date
    tmp_dir = root / "tmp" / "ha_snapshot"
    out_dir.mkdir(parents=True, exist_ok=True)
    tmp_dir.mkdir(parents=True, exist_ok=True)

    stamp = datetime.now().strftime("%Y%m%d_%H%M%S")

    try:
        snap = refresh_db_snapshot(args.ssh_port, args.ssh_key, args.ssh_user, args.ssh_host, tmp_dir)
        precheck_rows = fetch_states(snap, ENTITIES)
        cleanup_old_snapshots(tmp_dir)
        if any(row["state"] == "__MISSING__" for row in precheck_rows):
            print("PRECHECK FAILED")
            missing = [row["entity_id"] for row in precheck_rows if row["state"] == "__MISSING__"]
            (out_dir / f"ehw_field_test_precheck_failed_{stamp}.md").write_text(
                "# EHW Field Test Precheck Failed\n\nMissing entities:\n"
                + "\n".join(f"- `{entity}`" for entity in missing)
                + "\n",
                encoding="utf-8",
            )
            return 2
    except Exception as exc:
        print("PRECHECK FAILED")
        (out_dir / f"ehw_field_test_precheck_failed_{stamp}.md").write_text(
            f"# EHW Field Test Precheck Failed\n\n- error: `{exc}`\n",
            encoding="utf-8",
        )
        return 2

    if args.mode == "baseline":
        samples_csv = out_dir / f"ehw_field_test_baseline_samples_{stamp}.csv"
        summary_md = out_dir / f"ehw_field_test_baseline_summary_{stamp}.md"
        print("BASELINE RUNNING")
        baseline_start = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        deadline = time.time() + args.baseline_seconds
        all_rows: list[dict[str, str]] = []

        while True:
            capture_ts = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            snap = refresh_db_snapshot(args.ssh_port, args.ssh_key, args.ssh_user, args.ssh_host, tmp_dir)
            states = fetch_states(snap, ENTITIES)
            cleanup_old_snapshots(tmp_dir)
            for row in states:
                row["capture_ts_local"] = capture_ts
                all_rows.append(row)
            if time.time() >= deadline:
                break
            time.sleep(args.interval_seconds)

        baseline_end = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        write_csv(samples_csv, all_rows)
        write_summary(summary_md, baseline_start, baseline_end, all_rows)
        print("ARMED  change setpoint now")
        return 0

    post_samples_csv = out_dir / f"ehw_field_test_postchange_samples_{stamp}.csv"
    post_summary_md = out_dir / f"ehw_field_test_postchange_summary_{stamp}.md"
    baseline_file = find_latest_file(out_dir, "ehw_field_test_baseline_samples_*.csv")
    baseline_rows = load_csv_rows(baseline_file)
    baseline_latest = latest_by_entity(baseline_rows)

    print("POST-CHANGE CAPTURE RUNNING")
    event_ts = args.event_ts or datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    capture_start = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    deadline = time.time() + args.post_seconds
    post_rows: list[dict[str, str]] = []
    sample_index = 0

    while True:
        capture_ts = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        snap = refresh_db_snapshot(args.ssh_port, args.ssh_key, args.ssh_user, args.ssh_host, tmp_dir)
        states = fetch_states(snap, ENTITIES)
        cleanup_old_snapshots(tmp_dir)
        for row in states:
            row["capture_ts_local"] = capture_ts
            post_rows.append(row)
        if time.time() >= deadline:
            break
        sample_index += 1
        if sample_index < 10:
            time.sleep(30)
        else:
            time.sleep(60)

    capture_end = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    write_csv(post_samples_csv, post_rows)
    analysis = write_post_summary(post_summary_md, event_ts, capture_start, capture_end, baseline_latest, post_rows)
    state_table = out_dir / "state_table.csv"
    if state_table.exists():
        update_state_table(
            state_table,
            event_ts,
            baseline_rows[0]["capture_ts_local"],
            capture_end,
            baseline_latest,
            analysis,
        )
    print("CAPTURE COMPLETE")
    return 0


if __name__ == "__main__":
    sys.exit(main())
