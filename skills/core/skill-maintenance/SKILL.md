---
name: skill-maintenance
description: Create, refactor, or update repository skills so they stay thin, triggerable, and aligned with super-stack workflow rules.
---

# Skill Maintenance

Use this skill when the task is to add a new skill, revise an existing skill, split a bloated skill into references, or tighten how skills fit the repository workflow.

This skill is source-repo maintenance only. Even if a helper script is mirrored into `~/.super-stack/runtime`, keep the edit target and validation authority in the source repository under `skills/`.

## Read First

- the target `SKILL.md`
- nearby `references/` files if they exist
- `AGENTS.md`
- `harness/state.md` if it exists
- `harness/history.md` if it exists
- `references/skill-authoring-checklist.md`
- `scripts/check/validate-skills.py`

## Goals

- decide whether the work needs a new skill or a revision to an existing one
- keep skill entry files thin and triggerable
- move detailed material into references instead of bloating `SKILL.md`
- align skill wording with super-stack workflow, language rules, and state discipline
- leave behind a reusable skill that is easier to maintain after this turn

## Rules

- create a new skill only when the workflow or decision surface is meaningfully distinct from existing skills
- prefer updating an existing skill when the change is a boundary clarification, stronger rule, or additional reference guidance
- keep `SKILL.md` focused on trigger conditions, core goals, workflow steps, and output shape
- move long checklists, variant handling, and detailed heuristics into `references/`
- avoid auxiliary files such as README, CHANGELOG, or installation notes inside a skill folder
- when a skill changes repository-wide behavior expectations, update `AGENTS.md` or `harness/state.md` if that context would otherwise drift
- when a skill changes repository-wide behavior expectations in a durable way, append a concise entry to `harness/history.md`
- keep skill maintenance anchored to the source repo even when a mirrored runtime helper also exists
- when host-installed skill copies also exist, treat the repository skill under `skills/` as the source of truth and avoid making the runtime copy the only edited location
- default user-facing examples, summaries, and prompts to Chinese unless the repository or external interface requires English

## Process

1. Identify whether this is a new skill, a revision, a split-and-thin refactor, or a retirement/merge of an existing skill.
2. Use `references/skill-authoring-checklist.md` to confirm the target trigger, scope boundary, and file layout.
3. Decide the minimum write set:
   - target `SKILL.md`
   - needed `references/`
   - any routing or state files that must stay aligned
   - if runtime-installed skill copies exist, the source-repository location that must be updated first
4. Implement the smallest coherent skill change.
5. Run a text-level self-check for:
   - clear trigger description
   - thin `SKILL.md`
   - direct references to any new `references/`
   - no obvious duplication with nearby skills
   - output/report shape matches the intended workflow
   - run `python3 scripts/check/validate-skills.py` from the source repo when the repository skill set was changed
6. Update `harness/state.md` when the change materially affects current workflow behavior or maintenance conventions.
7. Append `harness/history.md` when the change materially affects repository-wide workflow behavior or maintenance conventions beyond the current state snapshot.

## Output

Report:

- what skill was created or updated
- whether this was a new skill or an existing-skill revision
- what was moved into references
- any routing or state files updated to keep behavior aligned
- what text-level validation was performed
