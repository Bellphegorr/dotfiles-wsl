---
name: Reflect
description: Use on request to learn from recurring workflow friction and propose the smallest evidence-based improvement to existing instructions, skills or configuration.
---

# Reflect

Review how the work went, not just the code it produced. Find a useful lesson
or recurring obstacle and recommend the smallest improvement. Creating nothing
is a valid outcome.

## Evidence boundary

- Start with the current conversation, explicit user feedback, project guidance,
  relevant memory and existing task progress.
- Inspect the relevant skills, commands or configuration before proposing a
  replacement. Prefer improving an existing asset over adding a near-duplicate.
- Stay within the authorized project/workflow. Do not search other projects'
  histories, personal logs, credentials or external accounts without permission.
- Separate observed events from hypotheses. Do not turn one unexplained failure
  into a universal rule or include sensitive examples in reusable instructions.

## Find the smallest useful change

1. Identify repeated user-visible friction, wasted verification, repeated manual
   steps or a verified failure with a durable lesson. Cite the concrete evidence
   and frequency; do not manufacture a pattern.
2. Check whether an existing rule, test or skill already addresses it. If so,
   distinguish missing guidance from failure to follow that guidance.
3. Consider benefit, risk and recurrence. Prefer a regression test for a code
   defect, a project-memory fact for local knowledge, or a narrow edit to an
   existing instruction for a repeated process problem.
4. Propose a new skill only when there is a reusable task with clear inputs,
   output and stopping point that existing assets do not cover. Do not create
   agents, orchestration, MCP access or permissions to justify the reflection.
5. If the evidence is weak or the current setup is sufficient, explain why no
   change is recommended.

## Proposal and approval

Report the evidence, proposed file/asset change, expected benefit and relevant
risk. A general request to reflect authorizes this proposal, not silent edits
to prompts, skills, commands, agents, MCP access or configuration.

Apply only specifically requested or subsequently approved changes. Keep them
narrow, preserve existing user settings, and validate the affected asset.
Technical facts may be recorded in project memory within an existing authorized
task; that does not grant permission to change global workflow behavior.

Do not run reflection after every edit or impose new approval gates on ordinary
implementation. The Builder can record useful project facts without inventing
a separate improvement project.

## Output

Keep the report short:

- observed friction and its evidence;
- the smallest recommended change, or why none is needed;
- what is already covered and should not be duplicated;
- any decision required before applying a change.

After an approved edit, report what changed, how it was checked and any loading
requirements. New shared skills need the relevant installer rerun; an existing
session may need restarting to discover or reload changed assets. Do not claim
the running agent has adopted a rule merely because a file was edited.

Adapted from [reflect](https://github.com/akitaonrails/my-skills/tree/master/reflect),
without dependencies on a particular orchestrator, plugin or memory service.
