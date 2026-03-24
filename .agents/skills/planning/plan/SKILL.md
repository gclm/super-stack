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
- `.planning/CONVENTIONS.md` if it exists
- `protocols/tdd.md`
- `references/planning-modes.md` when phase boundaries depend on validation-first or staged delivery

## Goals

- choose an implementation approach
- break work into phases and tasks
- make tasks testable and bounded
- update roadmap and state files
- preserve the chosen scope mode, such as validation-first or implementation-first
- reflect project conventions in planning outputs, especially language and commit expectations
- plan cross-surface sync explicitly when structure, entrypoints, or validation boundaries change

## Steps

1. Identify the simplest viable architecture.
2. Confirm the planning mode: validation-first, implementation-first, or staged hybrid.
3. Group work into phases with visible value.
4. For any structural task, explicitly include matching doc, test, CI, and state-file updates instead of treating them as optional follow-up.
5. Define tasks with files, verification, dependencies, and environment assumptions when relevant.
6. Update `.planning/ROADMAP.md`.
7. Update `.planning/STATE.md` with active phase and current focus.

## Task Format

For each task include:

- what changes
- likely files
- how it will be verified
- dependencies or blockers
- environment or runtime assumptions when they could block the task
- required sync surfaces when applicable, such as README, docs, CI, tests, and planning files

## Output

Tell the user:

- chosen approach
- planning mode and major boundary being preserved
- number of phases
- active phase
- recommended next step: `build`
