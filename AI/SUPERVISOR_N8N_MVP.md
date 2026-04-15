# AEB Supervisor n8n MVP

## Goal

Define the first usable `n8n` workflow for the `aeb` supervisor.

This MVP must:
- collect a small, trusted set of repo and audit inputs
- call a supervisor model in read-only mode
- write a stable markdown status report
- optionally draft a Codex handoff
- notify the operator

This MVP must **not**:
- edit repo source files automatically
- deploy to Home Assistant
- trigger runtime writes

## Runtime assumption

Current workspace evidence indicates `n8n` runs in a Linux container and should be treated as a control plane, not as a Windows-native executor.

Implication:
- do not assume direct access from `n8n` to `C:\2_OPS\...`
- use one of these access models explicitly:
  - bind-mount the required repo subtree into the container
  - expose a small host bridge endpoint that returns approved file content
  - generate a compact payload outside `n8n` and let `n8n` only orchestrate the model call

For the MVP, the preferred model is:

```text
host-side payload builder -> n8n -> supervisor model -> report writer -> notification
```

## Recommended topology

```text
Scheduled trigger
  -> Fetch compact input payload
  -> Validate payload
  -> Call supervisor model
  -> Parse response
  -> Write CURRENT_SUPERVISOR_STATUS.md
  -> Decide if a Codex handoff draft is needed
  -> Optionally write handoff draft
  -> Send Telegram summary
```

## Files

### Canonical inputs

- `AI/CONTEXT.md`
- `AI/RULES.md`
- `AI/TASKS.md`
- latest `docs/audits/*.md`
- optional latest `docs/runtime_evidence/*`

### Primary outputs

- `docs/audits/CURRENT_SUPERVISOR_STATUS.md`
- optional `AI/handoffs/<timestamp>_supervisor_task.md`
- optional `AI/supervisor_state.json`

## Workflow nodes

### 1. Trigger

Node:
- `Schedule Trigger` or `Cron`

Recommended cadence:
- 07:00 local
- 19:00 local

Manual mode should also be available for testing.

### 2. Get Supervisor Payload

Node:
- `HTTP Request` to a host-side local endpoint

Preferred contract:
- `GET /aeb/supervisor/payload`

Expected response:
- JSON with compact repo status and selected file contents

Reason:
- keeps `n8n` simple
- avoids direct path coupling with Windows paths
- makes input selection auditable
- reuses the established host-bridge model already documented in `life-os-2100`

### 3. Validate Payload

Node:
- `IF` or `Code`

Checks:
- required fields exist
- no secrets are present
- payload is not empty
- latest audit metadata exists

Failure path:
- write a `NO-GO` style report or send a failure notification

### 4. Build Supervisor Prompt

Node:
- `Set`

Purpose:
- assemble system and user prompt parts
- inject the payload into the expected prompt structure

Guidelines:
- keep prompt deterministic
- keep output schema strict
- include repo hard rules summary

### 5. Call Supervisor Model

Node:
- `HTTP Request`

Target:
- model provider API

Behavior:
- read-only advisory mode
- markdown output only
- strict section schema

Minimum required output sections:
- `FACT`
- `RISKS`
- `DRIFT`
- `PRIORITY`
- `NEXT ACTION`
- `RECOMMENDED OWNER`
- `GO / NO-GO`

### 6. Parse And Normalize Response

Node:
- `Code` or `Set`

Purpose:
- extract markdown body
- derive metadata:
  - `priority`
  - `go_no_go`
  - `recommended_owner`
  - `needs_handoff`

Rule:
- if parsing fails, treat run as `NO-GO`

### 7. Write Current Status Report

Node:
- `HTTP Request`

Target:
- host bridge endpoint `GET /aeb/supervisor/write_report`

Payload:
- base64 encoded markdown report
- optional repo selector when needed

The persisted report should contain:
- timestamp
- source payload summary
- normalized supervisor markdown

### 8. Decide Handoff

Node:
- `IF`

Condition:
- create handoff only if:
  - `recommended_owner = Codex`
  - `go_no_go = GO`
  - task is repo-bounded

### 9. Write Handoff Draft

Node:
- `HTTP Request`

Target:
- host bridge endpoint `GET /aeb/supervisor/write_handoff`

Result:
- bridge creates `<timestamp>_supervisor_task.md` under `AI/handoffs/`

The draft should include:
- task
- why now
- allowed files
- forbidden files
- required gates
- risks
- rollback
- definition of done

### 10. Notify Operator

Node:
- `Telegram`

Suggested message shape:
- title line
- priority
- `GO` or `NO-GO`
- 2 or 3 short highlights
- reference to report path
- note if Codex handoff was drafted

## Payload contract

The host-side payload should be compact and explicit.

Suggested JSON:

```json
{
  "repo": {
    "name": "aeb",
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

## Prompt assembly rules

- System prompt defines role, output schema, and hard safety rules.
- User prompt provides compact payload only.
- Never inject raw unbounded logs.
- Never ask the model to write code in the supervisor step.

## Error handling

### Payload fetch failure

- notify operator
- do not create handoff
- report `NO-GO`

### Model call failure

- write a minimal failure report if possible
- notify operator
- mark run as `NO-GO`

### File write failure

- notify operator with explicit path failure
- do not assume state was persisted

### Invalid response schema

- mark as `NO-GO`
- store raw response in a temporary diagnostics path if available

## First rollout recommendation

Start with these enabled nodes only:
- Trigger
- Get Payload
- Validate Payload
- Call Supervisor Model
- Write Current Status Report
- Notify Operator

Defer handoff generation to step two if needed.

See also:
- `AI/SUPERVISOR_BRIDGE_SPEC.md`

## Definition of done for MVP

- one scheduled or manual run completes end-to-end
- `CURRENT_SUPERVISOR_STATUS.md` is overwritten successfully
- Telegram summary arrives
- no repo source files are modified
- no deploy or runtime action is triggered
