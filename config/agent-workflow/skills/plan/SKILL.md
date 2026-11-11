---
name: Plan
description: Use to write a short plan when scope, uncertainty or risk needs it, or when the user asks for planning, with acceptance criteria and credible evidence.
---

# Plan

Make the outcome and its evidence clear before implementation. This stage plans
the work; it does not edit product files.

## When to use

Use a written plan for meaningful uncertainty, dependent delivery steps,
compatibility/architecture risk, or an explicit planning request.

Several changed files alone do not require a plan. Handle a small, clear
implementation request directly with `implement`; do not create artifacts for
questions or obvious edits.

## Before planning

1. Read project instructions, relevant memory and existing task artifacts,
   when present. Inspect only the code and consumers needed for this change.
2. Establish what the user authorized and any requested pause points.
3. Identify the observable result, invariants and important failure cases.
   Ask about decisions that materially change scope, compatibility or design;
   do not invent those decisions.

## Plan the evidence

- For each acceptance criterion, identify an input/action and an observable
  result that can establish or refute it. Prefer a regression test that fails
  on the base when practical.
- Use trusted project commands and facilities. Focused checks guide iteration;
  the applicable full project gate covers the final materially changed tree.
- Match verification to the actual change. Do not run unrelated ecosystems or
  invent test, lint, typecheck or build commands when they do not exist.
- Identify missing access, setup, platform or observability. If extra diagnostic
  tooling is needed, propose the smallest option; do not silently add dependencies
  or permanent infrastructure solely for verification.
- State what the evidence cannot prove. A dry run or command rehearsal is not
  end-to-end validation of an agent, hosted service or user interaction.

## Artifacts

Use a short kebab-case slug under `.agents/work/<slug>/`. Reuse existing
`plan.md` and `progress.md` rather than creating parallel tracking.

Keep `plan.md` to about one page, with no implementation code or heavy spec:

```markdown
# Plan: [name]

## Outcome and boundaries
[observable result, constraints and what is out of scope]

## Acceptance and evidence
| Criterion | Check / observable result | Limitations |
| --------- | ------------------------- | ----------- |

## Tasks
1. [coherent unit: files/areas, change, acceptance and validation]

## Decisions needed
[material questions, or none]
```

In `progress.md`, record status, current unit, date and the comparison base/
working branch once established. Log each completed unit with its command,
result and remaining limitation. Preserve pre-existing local changes and note
them when relevant to the handoff.

## Approval and continuation

- A planning-only request ends with the plan. It does not authorize implementation.
- If the user already authorized implementation of this bounded scope, present
  the short plan and continue with `implement` without another approval round,
  unless a material decision remains or the user requested a pause.
- If implementation was not authorized, wait for approval. Authorization of
  implementation alone does not include commits, push, PR, merge or release.
- Adjust implementation details within the agreed outcome as evidence changes;
  update the plan. Ask before expanding scope or changing a material contract.

Inspired by [verification-planning](https://github.com/akitaonrails/my-skills/tree/master/verification-planning),
adapted to the shared Builder workflow.
