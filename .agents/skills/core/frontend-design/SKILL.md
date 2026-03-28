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
- `references/frontend-task-shaping.md` when the task could drift between marketing, product-flow, redesign, or prototype work
- `.agents/skills/planning/brainstorm/references/reference-reuse-boundary.md` when the task involves borrowing from another product

## Goals

- choose an intentional visual direction before implementation
- avoid generic AI-looking layout, spacing, typography, and color choices
- make visual trade-offs explicit instead of hiding behind vague “modern UI” language
- preserve usability while increasing distinctiveness and coherence
- leave behind UI that can be verified with browser evidence, not only by reading code
- keep design exploration aligned to the actual product surface instead of drifting into the wrong artifact type

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

1. Restate the UI problem in terms of user perception and product surface, not only component structure.
2. Use `references/frontend-task-shaping.md` to identify the artifact type, real page coverage, and any fork/upstream boundary that should shape the work.
3. Surface any hidden assumptions about the audience, brand tone, device context, and whether the user is asking for brand exploration or product-flow exploration.
4. If the request is under-specified, define 2-3 plausible directions and recommend one, making clear how each direction changes the artifact type or user flow.
5. Identify what must stay stable: flows, content hierarchy, design system boundaries, accessibility constraints, or upstream-merge boundaries.
6. Choose the visual direction and express it in concrete terms:
   - typography
   - color
   - layout
   - motion
   - background treatment
7. State the deliverable type explicitly before implementation or handoff: visual mockup, clickable prototype, or implementation-ready spec.
8. Implement or guide implementation in a way that keeps the visual language consistent across the touched surface.
9. Verify the result in the browser when possible, especially for spacing, hierarchy, responsive behavior, and interaction polish.

## Output

Report:

- UI problem being solved
- artifact type chosen
- visual direction chosen
- key aesthetic decisions
- real pages or user flows the design is covering
- stability constraints preserved
- whether upstream-merge boundaries or reference-reuse boundaries influenced the design
- browser-visible evidence or verification path
- remaining risks, especially where the UI may still feel generic
