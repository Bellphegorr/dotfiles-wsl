---
name: ship
description: Use for commits, branch push, draft PR delivery or release requested by the task.
---

# Ship

Deliver the commits, branch push, PR or release that the task asks for. Confirm
the repository state and the requested scope before each operation.

Project restrictions and harness permissions still apply. Do not disable
approval prompts, change permissions or treat a successful review as consent.

## Establish the candidate

1. Read trusted project instructions and the authorized task/plan, when present.
   Inspect status, branch, comparison base, staged/unstaged changes and new files.
2. The working branch must have been prepared before implementation. If not,
   prepare a non-protected branch before any commit; never commit directly on
   the project's default/mainline or other protected branches.
3. Identify the project's actual base/protected branches and branch naming
   policy, not just literal `main`/`master`. Preserve unrelated work and existing
   staged changes. Do not stash, reset, clean or rewrite history to make shipping
   easier.
4. Confirm which review and validation evidence applies to this unit/candidate.
   A SHA alone does not describe tests run with additional local changes.
   Recheck after material changes; never relabel old or unrun checks as current.

## Commit

- Require focused validation and a read-only `change-review` of the coherent unit.
  Correct findings in implementation, not by weakening checks.
- Stage only intended files/hunks and inspect the resulting index. Do not
  include unrelated pre-staged work, secrets, `.env`, local databases or
  generated artifacts outside the authorized change. If safe separation is
  impossible, report the blocker instead of committing other work.
- Follow the repository's commit convention and preserve required attribution;
  use Portuguese imperative messages unless the project says otherwise. Prefer
  a small independently valid commit, not a commit for every file/edit.
- Do not amend or rewrite history. A normal delivery request does not authorize
  those operations.
- Record the resulting hash. An intermediate commit needs focused evidence;
  a final local handoff also needs the applicable full project gate below.

## Final gate

- Review the complete change from the comparison base, including earlier
  commits, and verify all acceptance criteria and directly affected docs.
- Run the applicable full local project gate once after the last material change,
  before final delivery/publication. Do not rerun it per intermediate commit.
  Existing evidence may be reused only for unchanged relevant inputs and an
  equivalent environment, naming the run and its actual coverage.
- Read the result before the dependent commit/publication action. Required
  local checks that fail or cannot run block completion; do not publish anyway.
  Hosted checks are inspected after push, not required to exist before it.
- Honor any requested pause before publication. Keep the tree and evidence
  intact if a decision, missing access or unavailable validation blocks progress.

## Push

- Confirm the remote repository, source commit and destination refspec before
  pushing. A feature branch can still target `HEAD:main`; the current branch
  name alone is not protection.
- Push an explicit working-branch ref, never a protected/mainline destination,
  `--all`, `--mirror` or an implicit set of tags. Do not trust configured push
  defaults without checking the actual destination.
- Never force push, including `--force-with-lease`, in this workflow. On rejection,
  preserve both sides, report the error and do not rewrite shared history.
- Procedural checks are not a security boundary; server-side protections and
  tool permissions remain necessary. Do not claim they exist without evidence.

## Pull request

- Open or update the PR requested by the task. Reuse an existing PR for this
  branch instead of creating duplicates; otherwise create a **draft** by default.
- Confirm the target repository/base and source branch. Respect the project's
  PR template, with a summary, acceptance evidence, validation and risks/gaps.
- In T3 Code, link created or updated PRs with its native linking tools. Use
  native check/review notifications when waiting is needed, not polling loops.
- After push, inspect relevant hosted checks on the exact pushed head SHA.
  Pending, skipped, missing or cancelled jobs are not passing. If CI is absent,
  state that only local validation is available; if inspection fails, report it.
- If CI exposes an in-scope failure, fix it, validate/review the correction and
  publish a normal new commit. Refresh evidence for the new head; do not call
  the old SHA's green result current.
- Do not close an issue as completed merely because a draft PR exists. Review
  approval and green CI do not themselves request a merge.

## Release

Follow the project's versioning/changelog and release strategy; resolve a
version mismatch with the user rather than inventing a bump. Require the
release candidate's checks to pass on its exact SHA, use annotated tags and
never rewrite published tags. If hosted CI is absent, use the project's
required local gate and state that limitation. Do not import automatic merge,
deploy or cleanup steps from another project's release procedure.

## Output

Report only what actually happened: local commits, published branch and PR URL
as applicable; the candidate SHA, evidence and hosted check status; and any
remaining blocker or requested pause. Distinguish locally validated, published
with CI pending, ready for human evaluation, and blocked. An open draft PR is
not proof that the work is finished.

Adapted from the delivery boundaries in
[github-resolution](https://github.com/akitaonrails/my-skills/tree/master/github-resolution)
and [release](https://github.com/akitaonrails/my-skills/tree/master/release),
with branch/PR delivery instead of automatic landing.
