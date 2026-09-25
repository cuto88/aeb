# Codex Mercurio runtime access and Home Assistant API checks

Status: operational runbook  
Scope: M63 / AEB-DHW-001

## Execution lane

Runtime operations must run from the Codex app on DS-XPS with full access,
under the effective Windows identity `ds-xps\ds`. The sandbox identity
`ds-xps\codexsandboxoffline` is not an approved execution lane: it may be
used for static work only and must stop before SSH or runtime access.

Record the execution lane and effective identity in every runtime report.

## SSH preflight

Run the following read-only checks before any runtime operation:

```powershell
whoami
ssh -o BatchMode=yes dscomparin@192.168.178.110 "hostname && whoami"
```

The expected result is `ds-xps\ds`, followed by `mercurio-edge` and
`dscomparin`. If the identity is the sandbox account or SSH fails, stop with
`EXECUTION_LANE_BLOCKED`. Do not work around the lane by copying private keys,
tokens, or secrets into the sandbox.

Also verify that `homeassistant` is running and that the intended runtime file
is present or absent as expected before proceeding.

## API preflight

Before an authorized service call, validate the existing authenticated API
channel with one read-only request:

```text
GET /api/
```

If the configured local authentication mechanism is unavailable, stop. Do not
extract credentials from secrets, databases, browser storage, or logs. Report
the two dimensions separately:

- `API_REACHABLE`: the endpoint can be contacted;
- `API_AUTHENTICATED`: the endpoint accepts the configured authentication.

Never include tokens, Authorization headers, cookies, or credential values in
reports. A 401 or 403 is not API authentication success.

## Service-call contract

For an explicitly authorized call such as
`input_boolean.turn_on` for `input_boolean.ehw_shadow_enabled`:

1. Send `Content-Type: application/json` with the exact JSON payload.
2. Treat success as HTTP 2xx only.
3. Propagate a non-zero PowerShell, curl, SSH, or remote-command exit code.
4. Capture the response body, sanitizing secrets and sensitive identifiers.
5. Verify the resulting entity state with a bounded timeout.
6. Make at most one initial attempt.
7. Retry only a documented transient transport error.
8. Stop immediately if the expected effect is not confirmed.
9. Distinguish HTTP 401/403/404, malformed JSON, missing service, remote
   command failure, and early polling from one another.
10. Keep the count of service calls and the before/after state in the report.

An empty response body is not evidence of success. A completed SSH or curl
command is not evidence that Home Assistant applied the requested state.

## Rollback and troubleshooting

Do not deploy, restart, reload, or call a service while diagnosing a failed
channel. First preserve the evidence pack and inspect its manifest, transcript,
script, timestamps, exit codes, HTTP status, sanitized response, and before /
after state. Missing evidence must be reported as `EVIDENCE_MISSING`.

Correlate Home Assistant logs only with the recorded attempt timestamps. An
authentication error, malformed request, or service/entity-not-found entry is
positive evidence. Absence of a matching log entry is only evidence that the
request arrival was not established; it is not proof of a successful or failed
service call.

Any new deployment requires a separate authorization and must retain the
existing writer, transport, setpoint, and Modbus safety gates.
