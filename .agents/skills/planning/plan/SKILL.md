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
- `references/scope-refresh.md` when planning is being revisited after changed assumptions or when design-heavy work needs stronger task shaping

## Goals

- choose an implementation approach
- break work into phases and tasks
- make tasks testable and bounded
- update roadmap and state files
- preserve the chosen scope mode, such as validation-first or implementation-first
- reflect project conventions in planning outputs, especially language and commit expectations
- plan cross-surface sync explicitly when structure, entrypoints, or validation boundaries change
- freeze the currently approved scope when recent turns changed product shape, architecture, or phase boundaries

## Steps

1. Identify whether planning is new work or a scope-refresh caused by changed assumptions.
2. Identify the simplest viable architecture.
3. Confirm the planning mode: validation-first, implementation-first, or staged hybrid.
4. Use `references/scope-refresh.md` when assumptions changed midstream or when design-heavy work needs artifact, flow, or fork-boundary shaping.
5. Group work into phases with visible value.
6. For any structural task, explicitly include matching doc, test, CI, and state-file updates instead of treating them as optional follow-up.
7. Define tasks with files, verification, dependencies, and environment assumptions when relevant.
8. Update `.planning/ROADMAP.md`.
9. Update `.planning/STATE.md` with active phase, current focus, and the latest scope or architecture change when applicable.

## Task Format

For each task include:

- what changes
- likely files
- how it will be verified
- dependencies or blockers
- environment or runtime assumptions when they could block the task
- required sync surfaces when applicable, such as README, docs, CI, tests, and planning files
- whether the task preserves the frozen scope or depends on a later phase
- the artifact type and user flow coverage when the task is design- or prototype-heavy

## Output

Tell the user:

- chosen approach
- whether this was a fresh plan or a scope-refresh
- planning mode and major boundary being preserved
- number of phases
- active phase
- recommended next step: `build`
