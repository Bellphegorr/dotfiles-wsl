---
name: Implement
description: Use to implement a bounded request or approved plan, one coherent unit at a time, with focused validation, review and authorized delivery.
---

# Implement

Execute the authorized scope one coherent unit at a time. A clear request does
not need a formal plan; a batch authorization does not need another approval
for every unit. Honor requested pauses and do not expand the outcome.

## Before editing

1. Read trusted project instructions, relevant memory and existing plan/progress,
   when present. Do not require planning artifacts for a small, clear task.
2. Identify the acceptance criteria, authorized operations and pause points.
   Resolve material uncertainty before editing; use repository conventions for
   ordinary implementation choices.
3. Inspect `git status --short --branch`, including staged and untracked work.
   Establish branch policy and prepare a non-protected working branch before
   product changes. Preserve unrelated work and never stash/reset it to proceed.
4. Record the comparison base SHA and initial local changes, in existing
   progress when available. For a PR, use its merge-base with the intended base.
   Use T3's native worktree tools if a thread-bound worktree is needed.

## Per-unit loop

1. Choose one independently coherent change and the criterion it proves.
2. For a bug, reproduce it before fixing it when practical. Add a regression
   that fails on the base and passes on the fix, or state the alternative
   evidence and its limitation. For a feature, cover the actual behavior and
   relevant wiring, not a restatement of the implementation.
3. Make the smallest correct change. Check tightly coupled consumers when a
   shared contract changes. Do not weaken tests, swallow errors, add speculative
   abstractions, perform unrelated refactors or leave unfinished placeholders.
4. Run the narrowest relevant check and adjacent regression checks. Fix in-scope
   failures and rerun affected checks. Do not run every full suite per commit.
5. Use `review` on the unit before an authorized commit. Review is read-only;
   return to implementation to fix findings, then verify the affected change.
6. If commits are explicitly authorized for this task, use `ship` to commit the
   validated, reviewed unit. Otherwise keep the change uncommitted. Do not push
   intermediate work unless that publication was explicitly requested.
7. Update existing progress with the unit, command/result, revision or working
   tree state, date and remaining work. At a requested delivery pause, report
   and wait; otherwise continue the remaining authorized units.

## Failure diagnosis

Two failed attempts at the same fix require reassessing the hypothesis,
reproduction and evidence, not automatically handing the task back. Continue
only with a justified next step. Do not cycle through speculative edits.

Stop when a material user decision, unavailable access/dependency or lack of
verifiable progress prevents completion. Preserve the current work and report:

- the last validated state and the current uncommitted changes;
- the exact failed or unavailable check and attempts to unblock it;
- what remains and which decision or access would unblock it.

Do not discard changes or commit unfinished code merely to leave a clean tree.
An in-scope failing test or review finding is work to address, not permission
to weaken the check, skip the issue or publish a broken candidate.

## Final candidate

- Review the complete change from the recorded comparison base, including
  already-created commits and remaining local changes.
- Run the applicable full project gate after the last material change. Reuse
  evidence only when its relevant inputs and environment remain unchanged,
  identifying the earlier run rather than claiming an unrun check passed.
- If publication was requested, use `ship` after the final checks. Commit-only
  and local implementation requests remain local; merge/release/deploy require
  separate authorization.
- Record durable facts in project memory when useful. Update existing progress
  and handoff for a pause/blocker; do not create extra paperwork for every edit.
- Report the outcome, evidence and limitations. Missing required verification
  is a blocker, not a successful delivery.

Inspired by [github-resolution](https://github.com/akitaonrails/my-skills/tree/master/github-resolution),
without its automatic merge or specialist orchestration.
