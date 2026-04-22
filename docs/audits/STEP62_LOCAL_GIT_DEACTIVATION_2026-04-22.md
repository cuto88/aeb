# STEP62 - Local Git deactivation

Date: 2026-04-22
Scope: `C:\2_OPS\aeb`

## FACT

- The workspace used a `.git` pointer file with content `gitdir: .git-local`.
- `.git-local` contains stale mutable state, including an `index.lock`.
- Sandbox policy blocks mutation inside `.git-local`, including lock cleanup through normal local actions.
- Local Git writes have repeatedly created operational drag: failed `add`, failed commits, stale locks, and need for connector-based publishing.
- GitHub connector publishing is already working and has been used for recent audit and cleanup commits.

## IPOTESI

- Confidenza alta: repairing `.git-local` inside this sandbox would remain fragile and would not improve runtime or project ROI.
- Confidenza alta: keeping GitHub as source of truth and treating this workspace as a working directory reduces operational friction.
- Confidenza media: `.git-local` may contain historical refs or diagnostic state, so it should not be deleted as part of the first cleanup pass.

## DECISIONE

- Disable the broken local Git backend operationally.
- Preserve `.git-local` as inert historical state for now.
- Use GitHub connector/app or a fresh external clone for commits and pushes.
- Stop spending runtime effort on local `.git-local` lock repair unless there is a specific recovery reason.

## Operational Rule

- This workspace is connector-first.
- Do not run mutating Git commands here.
- For repository publication, use the GitHub connector or a clean clone outside `C:\2_OPS\aeb`.
- Runtime HA deploy remains governed by `ops/deploy_safe.ps1` and must not include docs, repo metadata, or local Git state.
