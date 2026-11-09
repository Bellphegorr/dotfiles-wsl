---
name: Implement
description: Use to execute one approved task from a plan, make the smallest coherent code change, validate it and update progress.
---

# Implement

Execute **one approved task** at a time. Do not re-plan or expand the scope.

## Before editing

1. Read the project's `AGENTS.md`.
2. Read `.agents/work/<slug>/plan.md` and `.agents/work/<slug>/progress.md`.
3. Read `.agents/memory/gotchas.md` and `.agents/memory/decisions.md`, if they
   exist.
4. Confirm which task is approved and what its acceptance criterion is.
5. If the plan is ambiguous, incomplete or the task is not approved, stop and
   report the blocker. Do not guess.

## Execution

- Make the smallest coherent change that satisfies the acceptance criterion.
- For a bug, try to reproduce it with a test before fixing it.
- For a feature, adjust or write the test that proves the behavior.
- Run the narrowest validation first; then the broader one, if the plan asks.
- If validation fails, fix the same task and rerun the same check before
  expanding the scope.
- Do not weaken tests, remove assertions, add speculative abstractions, do
  drive-by refactors or leave TODOs.
- Do not commit or push.

## After implementing

Update `progress.md` with:

- current task and status;
- validation evidence (command and result);
- date;
- blockers or next step.

If you discover a durable pitfall or decision, update `AGENTS.md` or
`.agents/memory/`.

## Output

End with:

- files changed;
- commands run and results;
- what is left;
- risks or blockers.
