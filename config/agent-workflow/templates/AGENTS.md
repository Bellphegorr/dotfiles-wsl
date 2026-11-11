# AGENTS.md

> Instructions for agents in this repository. Fill in what is empty and keep it
> up to date. Project-specific constraints take precedence over generic skill
> defaults; they do not grant extra tool permissions.

## Project

[What this project is, main stack and how it runs.]

## Delivery policy

- Default/protected branches: `[branches or policy]`
- Working branch convention and PR base: `[convention and target]`

## Commands

- Install dependencies: `[command]`
- Run tests: `[command]`
- Run a single test: `[command]`
- Lint: `[command]`
- Typecheck: `[command]`
- Build: `[command]`
- Run locally: `[command]`

## Invariants

- [behavior that must never break]
- [file/area that should not be touched without need]
- [public contract that must stay compatible]

## Quick map

- `[directory]` — [responsibility]
- `[directory]` — [responsibility]

## Known pitfalls

- [mistake that already happened and how to avoid it]
- [command that looks like it works but does not]
- [dependency with unexpected behavior]

## Definition of done

- [ ] Acceptance criteria have test or reproducible behavioral evidence.
- [ ] The unit and complete change were reviewed, including existing commits.
- [ ] Applicable project checks passed on the final materially changed tree;
  unrun checks and limitations are explicit.
- [ ] The delivery contains no out-of-scope changes.
- [ ] If publication was requested, branch/base, PR and exact-SHA CI status
  are reported; absent CI is identified as local-only validation.
- [ ] `AGENTS.md` or `.agents/memory/` was updated if something durable was learned.

## Rules for agents

- Read this file before editing anything.
- Make the smallest coherent change.
- Respect the user's authorized scope and requested pauses. An explicit request
  for implementation, commits and PR covers that sequence without approval per
  step, subject to project rules and harness permissions.
- Questions and planning-only requests do not authorize implementation.
- Do not commit or publish unless authorized. Commit-only stays local; push/PR
  does not authorize merge, release or deploy.
- Work on a non-protected branch; never commit/push directly to the default or
  protected branches, force push or disable permissions to finish a task.
- Do not rewrite history or discard work without a separate explicit request.
- Do not weaken tests or remove assertions.
- Do not add speculative abstractions, TODOs or drive-by refactors.
- Ask about ambiguity that materially changes scope, compatibility or design.
- Fix in-scope failures; stop on a genuine blocker without discarding changes
  or claiming that failed/unavailable checks passed.
- Record useful, proven project decisions and pitfalls in `.agents/memory/`.
  Do not store secrets or unrelated project history there.
