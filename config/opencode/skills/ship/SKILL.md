---
name: Ship
description: Use only when the user explicitly asks to commit, push or release a validated change.
---

# Ship

Only use this skill when the user asks for a commit, push or release.
Otherwise, stop and ask.

## Before shipping

1. Read the project's `AGENTS.md`.
2. Run the full validation the project defines (test, lint, typecheck, build).
3. Check `git status` and `git diff` to see what will be included.
4. Do not include generated files, secrets, `.env`, local databases or
   out-of-scope changes without authorization.

## Commit

- Stage only the intended files.
- Short imperative message that explains the why.
- Do not use `--amend` or rewrite history unless asked.
- Do not push unless explicitly asked.
- Report the hash and the validation results.

## Push

- Confirm remote and branch first.
- If the push fails, do not force it; explain the error.
- Never use `--force` on a shared branch without authorization.

## Release

- The version follows the changelog classification: fix = patch,
  addition = minor, breaking = major.
- Only tag when CI is green on the exact SHA.
- Annotated tag, updated changelog.
- Never rewrite a published tag.
- Never cut a release nobody asked for.

## Output

- What was committed/pushed.
- Hash and branch.
- Validations run.
- What is still pending.
