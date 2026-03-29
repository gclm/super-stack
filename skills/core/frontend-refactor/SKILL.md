---
name: frontend-refactor
description: Refactor frontend code by separating structural cleanup, UI consistency, state flow, and verification instead of mixing visual edits with risky behavior changes.
---

# Frontend Refactor

Use this skill when a frontend change is larger than a simple bugfix and the real goal is to improve maintainability, consistency, or interaction quality without losing existing behavior.

## Read First

- `docs/overview/roadmap.md` and `harness/state.md` if they exist
- `harness/history.md` if it exists
- `docs/reference/conventions.md` if it exists
- the closest layout, state, and routing files involved
- any existing design or product notes that constrain the refactor
- `references/refactor-slices.md` when the work needs safer slicing

## Goals

- separate structural refactor from incidental redesign
- keep behavior changes explicit
- improve consistency across layout, state, styles, and reusable components
- leave behind clearer UI patterns instead of one-off edits
- preserve the difference between reusing a reference project's structure and copying its implementation
- avoid generic AI-looking visual output when the task includes meaningful UI polish or visual cleanup

## Steps

1. Define the refactor target.
2. Identify what must stay behaviorally stable.
3. Decide whether the task is reusing information architecture, interaction structure, implementation details, or some combination.
4. Split the work into safe slices instead of rewriting everything at once.
5. Refactor shared patterns first when multiple screens repeat them.
6. When visual polish matters, choose an explicit visual direction instead of defaulting to generic app UI.
7. Make typography, spacing, color, hierarchy, and background treatment intentional rather than leaving them as framework defaults.
8. Keep motion sparse but meaningful; avoid filler animation.
9. For validation samples, prefer maintainable skeletons and debug-friendly structure over premature visual fidelity, but do not accept obviously bland or placeholder-looking UI when presentation is part of the task.
10. Verify both UI structure and the most important user flows after each slice.

Read `references/refactor-slices.md` when you need a more explicit slicing strategy.

## Output

Report:

- refactor scope
- stable behavior constraints
- reference reuse boundary chosen
- visual direction chosen when relevant
- shared patterns extracted
- risky areas
- verification evidence
