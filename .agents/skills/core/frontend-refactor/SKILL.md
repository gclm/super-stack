---
name: frontend-refactor
description: Refactor frontend code by separating structural cleanup, UI consistency, state flow, and verification instead of mixing visual edits with risky behavior changes.
---

# Frontend Refactor

Use this skill when a frontend change is larger than a simple bugfix and the real goal is to improve maintainability, consistency, or interaction quality without losing existing behavior.

## Read First

- `.planning/ROADMAP.md` and `.planning/STATE.md` if they exist
- `.planning/CONVENTIONS.md` if it exists
- the closest layout, state, and routing files involved
- any existing design or product notes that constrain the refactor
- `references/refactor-slices.md` when the work needs safer slicing

## Goals

- separate structural refactor from incidental redesign
- keep behavior changes explicit
- improve consistency across layout, state, styles, and reusable components
- leave behind clearer UI patterns instead of one-off edits
- preserve the difference between reusing a reference project's structure and copying its implementation

## Steps

1. Define the refactor target.
2. Identify what must stay behaviorally stable.
3. Decide whether the task is reusing information architecture, interaction structure, implementation details, or some combination.
4. Split the work into safe slices instead of rewriting everything at once.
5. Refactor shared patterns first when multiple screens repeat them.
6. Keep visual polish subordinate to clarity, reuse, and predictable behavior.
7. For validation samples, prefer maintainable skeletons and debug-friendly structure over premature visual fidelity.
8. Verify both UI structure and the most important user flows after each slice.

Read `references/refactor-slices.md` when you need a more explicit slicing strategy.

## Output

Report:

- refactor scope
- stable behavior constraints
- reference reuse boundary chosen
- shared patterns extracted
- risky areas
- verification evidence
