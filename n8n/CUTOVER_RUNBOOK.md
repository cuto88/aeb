# AEB n8n Cutover Runbook

## Goal

Activate the read-only `aeb_supervisor_readonly_mvp` workflow in the live `n8n` instance and keep it on a daily automatic run.

## Source of truth

- Workflow export: `n8n/workflows/aeb_supervisor_readonly_mvp.json`
- Workflow README: `n8n/README.md`
- Freeze plan: `docs/audits/STEP109_RUNTIME_BURN_IN_FREEZE_PLAN_2026-05-14.md`
- Host bridge: `C:\2_OPS\n8n-bridge`

## Preconditions

- `n8n_api_key.txt` is present in `C:\2_OPS\secrets`
- the live `n8n` instance is reachable
- the host bridge on `http://host.docker.internal:8787` responds
- the workflow JSON is importable without schema errors

## Activation path

1. Import `n8n/workflows/aeb_supervisor_readonly_mvp.json` into the live `n8n` instance.
2. Confirm the workflow is saved with:
   - `active: true`
   - trigger `Schedule Trigger 07:30`
3. Verify the workflow uses the intended credentials:
   - `OpenAi account`
   - `Gmail account`
4. Run the workflow manually once.
5. Check that the host bridge endpoints respond:
   - `GET /aeb/supervisor/payload`
   - `GET /aeb/supervisor/write_report`
   - `GET /aeb/supervisor/write_handoff`
6. Confirm the report file is updated:
   - `docs/audits/CURRENT_SUPERVISOR_STATUS.md`

## Validation

After the first run, confirm:

- report written successfully
- email summary sent successfully
- no secrets appear in payload or output
- no repo mutation outside allowed outputs

## Failure modes

- If the workflow cannot be imported, the export is malformed.
- If the bridge endpoints fail, fix the host bridge first.
- If the model call fails, keep the workflow active but fail closed with `NO-GO`.

## Reversible rollback

- deactivate the workflow in `n8n`
- restore the previous workflow version if needed
- do not change repo logic to compensate for a broken runtime instance

