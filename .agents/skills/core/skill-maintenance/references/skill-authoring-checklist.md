# Skill Authoring Checklist

Use this checklist when creating or revising a repository skill.

## 1. Decide New Skill Vs Existing Skill

Prefer updating an existing skill when:

- the task only sharpens a rule or boundary
- the workflow is already represented nearby
- the real issue is bloated wording, not missing capability

Prefer a new skill when:

- the task has a distinct trigger surface
- the workflow is meaningfully different from existing skills
- users will likely ask for it directly by intent or by name

## 2. Shape The Trigger Carefully

The `description` field is the main trigger surface.

Check that it answers:

- what the skill does
- when it should be used
- what makes it distinct from similar skills

If the description could fit three other skills, it is too vague.

## 3. Keep SKILL.md Thin

`SKILL.md` should usually contain:

- what the skill is for
- what to read first
- goals
- core rules
- process
- output shape

Move these into `references/` instead:

- long checklists
- detailed heuristics
- variant-specific guidance
- examples that are helpful but not core
- repeated repository-specific rationale

## 4. Keep References One Step Away

If a skill uses references:

- link to them directly from `SKILL.md`
- say when to read them
- avoid deep nesting and reference-chasing

The skill should still make sense without loading every reference file.

## 5. Align With Repository Workflow

Check whether the skill must reflect any repository-wide rules:

- Chinese-first user-facing communication
- explicit stage backtracking
- `harness/state.md` updates
- `harness/history.md` if it exists
- validation evidence boundaries
- structure/doc/test/CI sync expectations

If the skill changes these expectations materially, update shared routing or state files too.

## 6. Avoid Skill Drift

Before creating a new skill, inspect nearby skills for overlap.

Common failure modes:

- two skills with nearly identical trigger descriptions
- a new skill that should have been a reference file
- a `SKILL.md` that copies repository policy already defined in `AGENTS.md`
- adding one-off process docs instead of improving the skill itself

## 7. Text-Level Validation

Before closing the task, verify:

- the folder name is lowercase hyphen-case
- the frontmatter `name` matches the folder conceptually
- the `description` is specific enough to trigger well
- references mentioned in `SKILL.md` actually exist
- the skill is not obviously duplicating another skill
- the output section tells the agent what to report back

## 8. Good Outcomes

A good skill change should leave behind:

- a clear trigger
- a thin entry file
- references only where they add real value
- minimal duplication
- stable alignment with the rest of super-stack
