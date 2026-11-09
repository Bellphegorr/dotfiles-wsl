---
name: Plan
description: Use when a task is large, multi-file or ambiguous enough to need a short written plan before implementation.
---

# Plan

Write a short, verifiable plan. Do not implement code in this skill.

## When to use

- The task touches several files or areas.
- The "how" is not obvious.
- There is regression risk, a contract change or an architecture decision.
- The user asked for a plan.

Do not use it for questions, one-line fixes or tasks with obvious criteria. In
those cases, say a formal plan is not needed and move on to implementation.

## Before planning

1. Read the project's `AGENTS.md`.
2. Read `.agents/memory/decisions.md` and `.agents/memory/gotchas.md`, if they
   exist.
3. Explore only the code needed to understand the real surface.
4. If an essential decision is missing, ask. Do not fill gaps on your own.

## Artifacts

Pick a short kebab-case slug and create:

```text
.agents/work/<slug>/
├── plan.md
└── progress.md
```

### `plan.md`

Keep it to one page. No detailed spec, speculative code or five documents.

```markdown
# Plan: [name]

## Goal
[what must be true at the end]

## Acceptance criteria
- [ ] [verifiable criterion]
- [ ] [verifiable criterion]

## Constraints and invariants
- [behavior that must not break]
- [files/areas out of scope]

## Likely areas
- `path/to/file` — why it is involved

## Validation
- `test command`
- `lint/typecheck command`

## Tasks
### 1. [title]
- Files/areas:
- Change:
- Acceptance criterion:
- Validation:

### 2. [title]
...

## Open questions
- [question that needs a human decision]
```

### `progress.md`

```markdown
# Progress: [name]

- Status: planned
- Current task: -
- Last update: [date]

## Log

| Date | Task | Evidence | Result |
| ---- | ---- | -------- | ------ |
```

## Rules

- A plan is one page, not a side project.
- One task per item; do not mix refactor, feature and fix.
- Every task needs an acceptance criterion and a validation step.
- Do not write the code in the plan. If the plan already contains the code, you
  are micromanaging the implementer.
- Present the plan and wait for human approval before implementing.
- If the plan has to change during implementation, update `plan.md` and explain
  why; never change the scope silently.
