# AGENTS.md

> Instructions for agents in this repository. Fill in what is empty and keep it
> up to date. This file outranks any generic skill.

## Project

[What this project is, main stack and how it runs.]

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

- [ ] The behavior was validated by a test or a reproducible command.
- [ ] Relevant tests, lint and typecheck passed.
- [ ] The diff has no out-of-scope changes.
- [ ] `AGENTS.md` or `.agents/memory/` was updated if something durable was learned.

## Rules for agents

- Read this file before editing anything.
- Make the smallest coherent change.
- Do not commit, push or rebase without an explicit request.
- Do not weaken tests or remove assertions.
- Do not add speculative abstractions, TODOs or drive-by refactors.
- If the request is ambiguous, ask before implementing.
- Record decisions and pitfalls in `.agents/memory/`.
