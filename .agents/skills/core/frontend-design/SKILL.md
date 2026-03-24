---
name: frontend-design
description: Design or reshape frontend UI with an explicit visual direction, stronger aesthetic judgment, and browser-verifiable outcomes instead of generic AI-looking layouts.
---

# Frontend Design

Use this skill when the task is not just frontend cleanup, but choosing or executing a meaningful UI direction.

## Read First

- `.planning/ROADMAP.md` and `.planning/STATE.md` if they exist
- `.planning/CONVENTIONS.md` if it exists
- the closest UI files, design notes, screenshots, or reference examples
- `references/reference-reuse-boundary.md` when the task involves borrowing from another product

## Goals

- choose an intentional visual direction before implementation
- avoid generic AI-looking layout, spacing, typography, and color choices
- make visual trade-offs explicit instead of hiding behind vague “modern UI” language
- preserve usability while increasing distinctiveness and coherence
- leave behind UI that can be verified with browser evidence, not only by reading code

## Design Rules

- start by naming the visual direction in plain language
- define the intended feel before choosing components
- make typography deliberate: hierarchy, rhythm, density, and personality should be chosen, not inherited by default
- make color deliberate: define a clear palette and contrast model instead of falling back to generic neutrals
- make spacing and composition deliberate: avoid evenly padded card grids unless they truly fit the product
- use motion only when it clarifies focus, state change, or spatial transition
- backgrounds should contribute to atmosphere or hierarchy, not default to flat emptiness
- when using a reference product, prefer reusing information architecture and interaction structure over copying low-quality implementation details
- when the design must stay within an existing system, preserve that system instead of forcing novelty

## Process

1. Restate the UI problem in terms of user perception, not only component structure.
2. Surface any hidden assumptions about the audience, brand tone, or device context.
3. If the request is under-specified, define 2-3 plausible visual directions and recommend one.
4. Identify what must stay stable: flows, content hierarchy, design system boundaries, or accessibility constraints.
5. Choose the visual direction and express it in concrete terms:
   - typography
   - color
   - layout
   - motion
   - background treatment
6. Implement or guide implementation in a way that keeps the visual language consistent across the touched surface.
7. Verify the result in the browser when possible, especially for spacing, hierarchy, responsive behavior, and interaction polish.

## Output

Report:

- UI problem being solved
- visual direction chosen
- key aesthetic decisions
- stability constraints preserved
- browser-visible evidence or verification path
- remaining risks, especially where the UI may still feel generic
