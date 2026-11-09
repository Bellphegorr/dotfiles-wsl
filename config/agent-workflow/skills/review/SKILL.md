---
name: Review
description: Use to critically review a diff against the request and, when present, its plan and acceptance criteria, without editing code.
---

# Review

Review the change critically. **Do not edit files.** Find what is wrong before
the human accepts it. If you also implemented the change, challenge your own
assumptions; for high-impact changes, prefer a separate session or reviewer.

## Before reviewing

1. Read the project's `AGENTS.md`.
2. If `.agents/work/<slug>/plan.md` or `progress.md` exists for this change,
   read it. Otherwise, derive the acceptance criteria from the user's request.
3. Read the real diff (`git diff`, `git status`, `git diff --stat`).
4. Run or check the relevant validations. Verify reported results rather than
   relying only on the implementer's summary.

## What to check

- Acceptance criteria: is each one really satisfied?
- Scope: did anything land that the plan did not ask for?
- Regressions: can existing behavior break?
- Tests: does the test prove the behavior or just pass?
- Errors: failure paths, input validation, messages.
- Security: secrets, command execution, injection, dependencies.
- Hidden changes: lockfiles, binaries, symlinks, permissions, CI.
- Style: does it follow the project's conventions? Not the main point, but it
  counts.

## Format

List findings by severity, with `file:line` and a concrete fix:

```text
BLOCKER
- src/foo.ts:42 — [problem] → [suggested fix]

IMPORTANT
- ...

MINOR
- ...

VERDICT
- approved | needs changes
- validation that was missing
```

If there are no blockers, say so explicitly and list the residual risks. Do not
invent problems to look useful.

## Rules

- Evidence over narrative.
- Do not edit, commit or push.
- Do not rewrite the plan; point out the deviation.
- If a test was not run, say it was not run; do not assume.
