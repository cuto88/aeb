# STEP39 - HA Core Auth Path Closure (2026-03-23)

## Scope

Document the validated Home Assistant Core API path for this workspace using `HA_TOKEN` only.

## Effective Environment

- `HA_URL=http://192.168.178.84:8123`
- `HA_TOKEN` stored in [`.env`](C:\2_OPS\aeb\.env)

## Validation Method

Read-only validation from the current host using Bearer authentication:

- `GET $HA_URL/api/config`
- `GET $HA_URL/api/services`

No write call was executed.

## Result

| Endpoint | Status |
|---|---:|
| `/api/config` | 200 |
| `/api/services` | 200 |

## Decision

- Home Assistant Core API is reachable from this host at `http://192.168.178.84:8123`
- `HA_TOKEN` is the working credential for Core API access
- `SUPERVISOR_TOKEN` and `HASSIO_TOKEN` are not required for Core API calls in this project path

## Next Boundary

Future Core API validation or service calls for DHW writer candidate testing must use:

- `HA_URL`
- `HA_TOKEN`

and must remain read-only unless the next step explicitly authorizes a reversible write validation.
