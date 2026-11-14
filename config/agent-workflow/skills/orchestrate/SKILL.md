---
name: orchestrate
description: Use only for large, decomposable or high-risk work with three or more independent slices; coordinates planning, worker briefs, reports, independent review, integration and ship. Do not use for coupled or small tasks.
---

# Orchestrate

Coordinate a heavy workflow. This skill does not replace `planning`, `implement`,
`change-review` or `ship`; it sequences them and adds worker briefs, reports and gates.

## When to use

Use only when at least one condition is true:

- three or more independent slices, each with an acceptance criterion and a
  validation command;
- a change across multiple repos or packages;
- a large audit or migration;
- high-risk work that needs an independent verifier;
- a recurring operation with a budget and monitoring.

Do not use for a question, small adjustment, coupled feature, ambiguous task or
when the brief is bigger than the task. In those cases, stop and use the normal
builder flow. Do not create heavy artifacts for a coupled task.

The slices must also be substantial enough that coordination pays. Three tiny
one-file changes are independent, but they are not a heavy workflow. Rule of
thumb: if the whole job fits in one short builder session, or each slice is a
single small file, use the builder.

## Before starting

1. Read `AGENTS.md`, project memory and existing `plan.md`/`progress.md`.
2. If there is no plan, use `planning` first.
3. Confirm the plan has scope, slices, file ownership, acceptance, budget and
   stop conditions. If the user asked for a different commit behavior, record it.
4. Treat plan approval as **G1**. Do not dispatch workers before it.
5. If a slice has no command-validatable acceptance, refine it or keep it in the
   builder. Do not delegate a vague brief.

## Artifacts

Use `.agents/work/<slug>/`:

| File | Who writes | Purpose |
| --- | --- | --- |
| `plan.md` | `planning` skill | outcome, boundaries, acceptance, tasks, decisions, budget and any requested commit behavior |
| `progress.md` | plan/integrator | status, current unit, evidence, changelog |
| `tasks/<id>.md` | dispatcher | self-sufficient brief for one worker |
| `reports/<id>.md` | dispatcher | short worker report |
| `review.md` | dispatcher | verifier findings and verdict |
| `ship.md` | dispatcher | integration evidence, SHA, CI and PR |

Do not create `00-request`, `01-prd`, `02-execution`, `03-tasks` or
`04-progress`. The current `planning` contract already covers those. These extra
files exist only while `orchestrate` is active.

## Worker brief

Each `tasks/<id>.md` must fit in about one page and contain:

- objective and expected result;
- allowed files or areas;
- base branch and worktree;
- acceptance command;
- report format;
- stop conditions.

Rules:

- one owner per file or area;
- the worker edits only its scope;
- run the acceptance command before reporting;
- commit in its own worktree by default; if the user asked to keep the work
  uncommitted, return the diff instead;
- never push;
- return a short report: what changed, evidence, risks and next step;
- stop and ask if the repository contradicts the plan.

If the brief does not fit in a page or the result is not validatable by a
command, it is not ready to delegate.

## Execution

1. **G1 — plan approved.** Do not start otherwise.
2. **Dispatch one worker per independent slice.**
   - In T3, use `delegate_task` with `role: implementation`.
   - Use `isolation: "worktree"` when the project root is the repo. Otherwise,
     create the worktree manually and pass its absolute path; use
     `isolation: "shared"` and state the boundary explicitly.
   - Use `create_threads` only for batch fan-out without lineage. Prefer
     `delegate_task` when you need approvals and a result tied to the parent.
   - The child never receives broader permissions than the parent. Approvals go
     up to the parent; stopping the parent stops its subagents.
3. **Worker runs.** The worker implements only its scope, runs acceptance,
   commits in its worktree by default, and returns a short report with the
   commit. It never pushes. If the request asked for no commits, it returns the
   diff instead.
4. **G2 — each task accepted.** Check the report, the acceptance output and the
   commit or diff. Record `reports/<id>.md`. A worker that edited outside its
   scope fails the gate.
5. **Integrate.** Merge the accepted commits, or apply the returned diffs when
   the user asked for no commits; run the full suite, resolve integration
   issues and update `progress.md`.
6. **G3 — integration green.** Do not advance with a red suite or unresolved
   conflict.
7. **Independent review.** Give a read-only verifier only the diff and the
   acceptance criteria, not the implementer's reasoning. Record `review.md`.
   Fix blockers and request a new review.
8. **G4 — review clean.** No open blocker. Every acceptance criterion in
   `plan.md` must map to evidence; a missing required automated check is a
   blocker, not a nit.
9. **Ship.** Use `ship` only for the operations the user authorized. Record
   `ship.md` with SHA, validation evidence and CI status. Check CI at the exact
   pushed SHA.
10. **G5 — authorized and checked.** Pending, skipped or cancelled checks are
    not passing.

## Gates

| Gate | Criterion | Evidence |
| --- | --- | --- |
| G1 | plan approved | `plan.md` |
| G2 | each task accepted | `tasks/<id>.md`, `reports/<id>.md`, acceptance command, commit or diff |
| G3 | integration green | full suite, diff, `progress.md` |
| G4 | every plan criterion mapped to evidence; no open blocker | `review.md` |
| G5 | publication authorized | `ship.md`, CI status at SHA |

## Failure and stops

| Situation | Action |
| --- | --- |
| Brief not validatable by a command | Do not delegate; refine or use the builder |
| Two workers need the same file | Separate worktrees or serialize |
| Worker failed twice | Stop, reassess, revise the plan |
| Integration red | Do not review or ship; fix first |
| Review has a blocker | Fix and re-review; do not ship |
| Review approved with a plan criterion unmapped | Treat as blocker; fix and re-review |
| Budget exceeded | Stop and report the validated state |
| Worker asks and blocks | Answer or cancel; do not leave it hanging |
| Scope grew | Stop, update the artifacts and ask for approval |

## Output

Report the artifacts, branches/commits, gate status, validation evidence and
remaining risks. Do not claim a gate passed without its command, output or diff.
