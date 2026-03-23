---
name: frontend-refactor
description: Refactor frontend code by separating structural cleanup, UI consistency, state flow, and verification instead of mixing visual edits with risky behavior changes.
---

# Frontend Refactor

Use this skill when a frontend change is larger than a simple bugfix and the real goal is to improve maintainability, consistency, or interaction quality without losing existing behavior.

## Read First

- `.planning/ROADMAP.md` and `.planning/STATE.md` if they exist
- the closest layout, state, and routing files involved
- any existing design or product notes that constrain the refactor

## Goals

- separate structural refactor from incidental redesign
- keep behavior changes explicit
- improve consistency across layout, state, styles, and reusable components
- leave behind clearer UI patterns instead of one-off edits

## Steps

1. Define the refactor target:
   - layout
   - component structure
   - state flow
   - routing
   - styling system
   - interaction consistency
2. Identify what must stay behaviorally stable.
3. Split the work into safe slices instead of rewriting everything at once.
4. Refactor shared patterns first when multiple screens repeat them.
5. Keep visual polish subordinate to clarity, reuse, and predictable behavior.
6. Verify both UI structure and the most important user flows after each slice.

## Output

Report:

- refactor scope
- stable behavior constraints
- shared patterns extracted
- risky areas
- verification evidence
