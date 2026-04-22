# AEB Supervisor Bridge Spec

## Goal

Define the host-bridge endpoints required to support the `aeb` supervisor from `n8n`.

This spec is intentionally aligned with the existing `life-os-2100` bridge pattern:
- `n8n` stays control plane only
- host-side scripts access Windows paths and Git state
- bridge endpoints are small, explicit, and auditable

Reference pattern:
- shared bridge owner: `C:/2_OPS/n8n-bridge/README.md`
- canonical runtime entrypoint: `C:/2_OPS/n8n-bridge/scripts/bridge_server.py`
- compatibility background: `C:/2_OPS/life-os-2100/autopilot-core/specs/OPERATING_CONTEXT.md`

## Design principles

- Keep the bridge minimal.
- Prefer explicit endpoints over generic file access.
- Allow `n8n` to request prepared artifacts, not arbitrary host reads.
- Reject writes outside approved `aeb` output paths.
- Never expose secrets or raw credentials through the bridge.

## Host boundary

Expected runtime topology:

```text
n8n container
  -> http://host.docker.internal:8787
  -> shared bridge server on Windows host
  -> PowerShell scripts read/write under C:\2_OPS\aeb
```

The bridge should be treated as a narrow host API for `aeb` supervisor operations.

## Approved endpoints

### 1. `/health`

Purpose:
- basic availability check

Method:
- `GET`

Response:

```json
{
  "ok": true,
  "service": "autopilot-bridge"
}
```

This already exists in the current bridge and should remain unchanged.

### 2. `/aeb/supervisor/payload`

Purpose:
- build and return the compact supervisor input payload

Method:
- `GET`

Query params:
- `repo_b64` optional
- `max_audits` optional, default `3`
- `max_runtime_evidence` optional, default `2`

Default repo path:
- `C:\2_OPS\aeb`

Behavior:
- resolve target repo path
- verify it is exactly `C:\2_OPS\aeb` or an approved equivalent
- read canonical AI files
- summarize latest audits
- summarize latest runtime evidence
- read git state
- return a compact JSON payload

Success response:

```json
{
  "ok": true,
  "repo": {
    "path": "C:\\2_OPS\\aeb",
    "branch": "main",
    "dirty": false,
    "modified_files": [],
    "latest_commits": []
  },
  "canonical_files": {
    "context_md": "...",
    "rules_md": "...",
    "tasks_md": "..."
  },
  "audits": {
    "latest_files": [
      {
        "path": "docs/audits/CURRENT_RUNTIME_STATUS_2026-04-08.md",
        "summary": "..."
      }
    ]
  },
  "runtime_evidence": {
    "latest_files": []
  },
  "timestamp": "2026-04-08T10:30:00Z"
}
```

Failure cases:
- repo path invalid
- required canonical files missing
- git command failure

### 3. `/aeb/supervisor/write_report`

Purpose:
- persist the generated supervisor markdown report to the approved path

Method:
- `GET` for compatibility with existing bridge pattern

Required query params:
- `report_b64`

Optional query params:
- `repo_b64`

Target path:
- `C:\2_OPS\aeb\docs\audits\CURRENT_SUPERVISOR_STATUS.md`

Behavior:
- decode markdown
- verify target repo path
- create parent directories if needed
- overwrite only the approved report path

Success response:

```json
{
  "ok": true,
  "written": true,
  "path": "C:\\2_OPS\\aeb\\docs\\audits\\CURRENT_SUPERVISOR_STATUS.md"
}
```

Failure cases:
- missing `report_b64`
- repo path invalid
- write failure

### 4. `/aeb/supervisor/write_handoff`

Purpose:
- write a bounded Codex handoff draft when the workflow decides it is needed

Method:
- `GET`

Required query params:
- `handoff_b64`

Optional query params:
- `repo_b64`
- `timestamp`

Target directory:
- `C:\2_OPS\aeb\AI\handoffs\`

Target filename:
- `<timestamp>_supervisor_task.md`

Behavior:
- decode markdown
- verify target repo path
- verify output stays under `AI\handoffs\`
- create directory if missing
- write one new handoff file

Success response:

```json
{
  "ok": true,
  "written": true,
  "path": "C:\\2_OPS\\aeb\\AI\\handoffs\\20260408T103000Z_supervisor_task.md"
}
```

Failure cases:
- missing `handoff_b64`
- invalid timestamp
- output path escapes allowed directory

### 5. `/aeb/supervisor/state`

Purpose:
- optional machine-readable state snapshot

Method:
- `GET`

Optional query params:
- `repo_b64`

Behavior:
- return current state if `AI/supervisor_state.json` exists
- otherwise return `ok=true` with `exists=false`

Success response:

```json
{
  "ok": true,
  "exists": true,
  "path": "C:\\2_OPS\\aeb\\AI\\supervisor_state.json",
  "state": {
    "priority": "HIGH",
    "go_no_go": "GO"
  }
}
```

This endpoint is optional for MVP.

## Non-goals

The bridge must not expose:
- arbitrary file read
- arbitrary file write
- direct deploy actions
- direct Home Assistant runtime commands
- direct Git commit/push for the supervisor MVP

Git promotion should remain a later, separate step.

## Script mapping

Recommended host-side script layout:

```text
aeb/ops/supervisor/
  build_supervisor_payload.ps1
  write_supervisor_report.ps1
  write_supervisor_handoff.ps1
```

The bridge should call these scripts explicitly.

## Suggested endpoint implementation mapping

- `/aeb/supervisor/payload`
  - `build_supervisor_payload.ps1`

- `/aeb/supervisor/write_report`
  - `write_supervisor_report.ps1`

- `/aeb/supervisor/write_handoff`
  - `write_supervisor_handoff.ps1`

## Payload rules

The bridge should return:
- compact summaries, not full unbounded logs
- repo paths relative to `aeb` where practical
- enough context for a safe supervisor decision

The bridge should not return:
- secrets
- private tokens
- raw huge runtime dumps
- arbitrary binary data

## Path safety rules

- Resolve all paths to absolute Windows paths.
- Reject any path outside `C:\2_OPS\aeb`.
- Reject `..` traversal and path injection.
- Allow writes only to:
  - `C:\2_OPS\aeb\docs\audits\CURRENT_SUPERVISOR_STATUS.md`
  - `C:\2_OPS\aeb\AI\handoffs\*.md`
  - optionally `C:\2_OPS\aeb\AI\supervisor_state.json`

## Error contract

Follow the existing bridge style:

```json
{
  "ok": false,
  "error": "message"
}
```

Use HTTP `500` for execution errors and `404` for unknown paths.

## MVP recommendation

Implement these endpoints first:
- `/health`
- `/aeb/supervisor/payload`
- `/aeb/supervisor/write_report`

Defer until step two:
- `/aeb/supervisor/write_handoff`
- `/aeb/supervisor/state`

## Integration into n8n

Recommended MVP workflow:

```text
Schedule Trigger
  -> GET /aeb/supervisor/payload
  -> call supervisor model
  -> GET /aeb/supervisor/write_report
  -> Telegram notify
```

This keeps the first implementation small and consistent with the established `life-os-2100` host-bridge model.
