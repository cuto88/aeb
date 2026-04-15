# AEB Supervisor Architecture

## Goal

Define a safe operating model for an automated project supervisor for `aeb`.

The supervisor is intended to:
- observe repo and runtime evidence
- summarize current project state
- detect risks, drift, and priority actions
- prepare structured tasks for Codex

The supervisor is **not** allowed to:
- modify Home Assistant runtime directly
- deploy autonomously
- rename production `entity_id`
- bypass repo rules or quality gates

## Core roles

### 1. n8n Orchestrator

`n8n` is the process orchestrator.

Responsibilities:
- trigger runs on schedule or on demand
- collect input files and repo signals
- normalize context into a compact payload
- call the supervisor model
- persist outputs to markdown/json files
- send notifications
- optionally create a structured handoff for Codex

Non-responsibilities:
- making architecture decisions on its own
- changing repo code directly
- deploying to Home Assistant

### 2. Supervisor LLM

The supervisor model is the analytical layer.

Responsibilities:
- classify current project posture
- identify risks and blockers
- propose the next best action
- decide whether work should be:
  - deferred
  - escalated to human review
  - handed off to Codex as a bounded task

Non-responsibilities:
- editing the repo directly
- executing shell/deploy actions
- overriding `AI/RULES.md`

### 3. Codex Executor

Codex is the technical execution layer.

Responsibilities:
- take one bounded task at a time
- modify allowed files in the repo
- update related documentation
- run or prepare validation steps
- produce a clear change summary, risks, and rollback notes

Non-responsibilities:
- inventing scope outside the supervisor task
- deploying without approval
- changing production entities unless explicitly requested

### 4. Human Authority

The human remains the final authority.

Responsibilities:
- approve sensitive tasks
- review diffs and risks
- authorize merge and deploy
- override supervisor recommendations when needed

## Operating principle

Preferred control flow:

```text
n8n -> Supervisor -> Structured task -> Codex -> Validation -> Human approval -> Deploy
```

Forbidden initial control flow:

```text
n8n -> Supervisor -> Repo change -> Runtime deploy
```

For `aeb`, the supervisor starts as a **read-first, write-later** capability.

## Inputs

The supervisor should use only explicit, reviewable inputs.

### Required inputs

- `AI/CONTEXT.md`
- `AI/RULES.md`
- `AI/TASKS.md`
- latest files under `docs/audits/`
- latest relevant files under `docs/runtime_evidence/` when present
- repo state summary:
  - current branch
  - modified files
  - latest commits

### Optional inputs

- targeted files from `docs/logic/` for the current domain
- outputs from `ops/` validation scripts
- selected runtime exports from Home Assistant

### Input hygiene rules

- Prefer summaries over raw dumps.
- Limit each run to the minimum files needed.
- Never include secrets, tokens, or credentials.
- Treat runtime evidence as advisory unless confirmed by canonical docs or validated traces.

## Outputs

Each supervisor run should write a durable result in markdown.

### Primary output

Suggested path:
- `docs/audits/CURRENT_SUPERVISOR_STATUS.md`

Suggested sections:
- `FACT`
- `RISKS`
- `DRIFT`
- `PRIORITY`
- `NEXT ACTION`
- `RECOMMENDED OWNER`
- `GO / NO-GO`

### Optional machine-readable output

Suggested path:
- `AI/supervisor_state.json`

Suggested fields:
- `run_timestamp`
- `status`
- `priority`
- `recommended_owner`
- `needs_human_review`
- `candidate_task_id`
- `go_no_go`

### Task handoff output

If the supervisor recommends execution, it should produce a bounded handoff with:
- objective
- rationale
- allowed file scope
- required gates
- risks
- rollback note
- done criteria

Suggested path:
- `AI/handoffs/<timestamp>_supervisor_task.md`

## Decision policy

The supervisor should classify each run into one of four modes.

### Mode A: Observe only

Use when:
- no urgent change is needed
- evidence is incomplete
- the safest action is continued monitoring

Output:
- status report only

### Mode B: Ask for human review

Use when:
- risk is high
- evidence conflicts
- a runtime or governance decision is needed

Output:
- status report
- explicit blocker or decision request

### Mode C: Handoff to Codex

Use when:
- the task is repo-bounded
- file scope is clear
- rules and gates are known
- no direct runtime action is needed

Output:
- status report
- structured task handoff

### Mode D: No-Go

Use when:
- the repo or runtime posture is unsafe
- required evidence is missing
- the requested change would violate hard rules

Output:
- status report
- explicit `NO-GO`

## Autonomy levels

The supervisor should operate in staged autonomy.

### Level 0: Report only

- writes markdown summary
- sends notification
- no task creation

### Level 1: Report + task proposal

- writes markdown summary
- creates a draft task for Codex
- no automatic execution

### Level 2: Report + approved handoff

- writes markdown summary
- prepares a task that Codex may execute after human approval

### Level 3: Semi-automatic repo workflow

Not recommended for initial `aeb` rollout.

Possible future behavior:
- open branch
- prepare draft PR
- never deploy automatically

Initial target for `aeb`: **Level 1**

## n8n workflow shape

Recommended MVP workflow:

```text
Cron / Manual Trigger
  -> Collect repo state
  -> Read canonical AI files
  -> Read latest audit files
  -> Build compact supervisor payload
  -> Call supervisor model
  -> Write markdown report
  -> If needed, write task handoff draft
  -> Send Telegram or local notification
```

### Step notes

1. Trigger
- scheduled twice daily or manual

2. Context collection
- small set of canonical files only
- latest audit evidence only

3. Prompt assembly
- include repo rules
- include allowed output schema
- force concise markdown

4. Supervisor call
- read-only advice posture
- no autonomous command execution

5. Persistence
- overwrite `CURRENT_SUPERVISOR_STATUS.md`
- create handoff file only when needed

6. Notification
- short summary
- priority
- `GO` or `NO-GO`
- path to the report

## Codex handoff contract

When the supervisor hands work to Codex, the task must contain:

- `Task`
- `Why now`
- `Allowed files`
- `Forbidden files`
- `Required gates`
- `Expected docs updates`
- `Risks`
- `Rollback`
- `Definition of done`

Example:

```text
Task
- Update the runtime audit summary for the Mirai branch closure.

Why now
- Current audit posture is stale relative to the latest evidence.

Allowed files
- docs/audits/
- AI/TASKS.md

Forbidden files
- packages/
- configuration.yaml

Required gates
- docs consistency review
- include tree unchanged

Definition of done
- current audit summary updated
- risks and next step clearly stated
- no runtime files changed
```

## Safety rules

The supervisor must inherit repo hard rules from `AI/RULES.md`.

Additional supervisor-specific rules:
- no direct runtime writes
- no deploy trigger
- no secret access
- no branch deletion
- no force operations
- no file writes outside the declared output paths
- no recommendation without evidence citation in the report

## File layout proposal

```text
AI/
  CONTEXT.md
  RULES.md
  TASKS.md
  SUPERVISOR_ARCHITECTURE.md
  handoffs/

docs/audits/
  CURRENT_SUPERVISOR_STATUS.md
```

## MVP rollout

### Phase 1

- create supervisor spec
- define prompt contract
- keep workflow report-only

### Phase 2

- add draft task handoff generation
- route tasks to Codex manually

### Phase 3

- optional branch/PR preparation
- still no autonomous deploy

## Current recommendation

For `aeb` today:
- `n8n` should be the orchestrator
- the supervisor should be read-only
- Codex should remain the repo executor
- human approval should remain mandatory before merge or deploy
