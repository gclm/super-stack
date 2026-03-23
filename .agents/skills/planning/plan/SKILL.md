---
name: plan
description: Convert approved requirements into a phased roadmap with actionable tasks and current state tracking.
---

# Plan

Use this skill after requirements are clear enough to define delivery phases.

## Read First

- `.planning/PROJECT.md`
- `.planning/REQUIREMENTS.md`
- `.planning/STATE.md`
- `protocols/tdd.md`

## Goals

- choose an implementation approach
- break work into phases and tasks
- make tasks testable and bounded
- update roadmap and state files

## Steps

1. Identify the simplest viable architecture.
2. Group work into phases with visible value.
3. Define tasks with files, verification, and dependencies.
4. Update `.planning/ROADMAP.md`.
5. Update `.planning/STATE.md` with active phase and current focus.

## Task Format

For each task include:

- what changes
- likely files
- how it will be verified
- dependencies or blockers

## Output

Tell the user:

- chosen approach
- number of phases
- active phase
- recommended next step: `build`
