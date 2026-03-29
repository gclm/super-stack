---
name: service-boundary-review
description: Review whether module or service boundaries are correctly drawn, highlighting coupling, ownership drift, and misplaced responsibilities before architecture debt hardens.
---

# Service Boundary Review

Use this skill when the question is whether responsibilities sit in the right module, package, service, or domain boundary.

## Read First

- architecture map or current module layout
- dependency graph or import paths
- cross-boundary calls and shared types
- `docs/overview/project-overview.md` and `harness/state.md` if they exist
- `harness/history.md` if it exists
## Goals

- expose unclear ownership and accidental coupling
- prevent boundary decisions from drifting into shared-everything design
- recommend the smallest structural correction that improves clarity
- distinguish real boundary problems from simple code smell

## Steps

1. Define the boundary under review.
2. Identify responsibility, data ownership, and dependency direction.
3. Check for boundary smells:
   - shared mutable models
   - cross-layer leakage
   - circular knowledge
   - chatty service calls
4. Compare:
   - keep as is
   - redraw module boundary
   - extract shared kernel
   - merge split-by-accident units
5. Recommend the least disruptive correction that improves ownership.
6. Capture migration cost and expected wins.

## Output

Report:

- boundary reviewed
- observed smells
- recommendation
- dependency direction rules
- migration cost
- risks if unchanged
