---
name: build
description: Implement the current task or phase using the shared engineering protocols and project state files.
---

# Build

Use this skill when the project has a current task ready for execution.

## Read First

- `.planning/STATE.md`
- `.planning/ROADMAP.md`
- relevant code and tests
- `protocols/tdd.md`
- project-local rules from `AGENTS.md` and nearby skill files

## Goals

- implement the current task with minimal scope
- preserve alignment with roadmap and requirements
- verify the changed behavior before moving on

## Rules

- prefer test-first changes when practical
- keep edits narrow
- do not silently expand scope
- update planning state when a task meaningfully advances

## Steps

1. Identify the current task from state or roadmap.
2. Inspect the relevant code paths.
3. Implement the smallest sufficient change.
4. Run relevant verification.
5. Update `.planning/STATE.md` with progress or blockers.

## Output

Tell the user:

- what task was implemented
- what was verified
- whether the next step is another `build`, `review`, or `verify`
