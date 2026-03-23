---
name: architecture-design
description: Compare and shape system structure, boundaries, dependencies, and scaling trade-offs before committing to a larger technical direction.
---

# Architecture Design

Use this skill when the real question is system shape: module boundaries, service decomposition, responsibility split, dependency direction, or long-term structural trade-offs.

## Read First

- the current architecture map if it exists
- key requirements, risks, and non-goals
- integration boundaries and operational constraints
- `.planning/PROJECT.md`, `.planning/REQUIREMENTS.md`, and `.planning/STATE.md` if they exist

## Goals

- recommend a structure that matches the problem instead of abstract purity
- make boundaries and dependency flow explicit
- compare realistic options with trade-offs
- avoid locking into architecture for the wrong reason

## Steps

1. Define the architectural decision that must be made.
2. Identify the forces on the decision:
   - scale
   - team workflow
   - deployment model
   - reliability
   - change frequency
   - domain complexity
3. Compare 2-3 credible structures.
4. Explain why the recommended structure is better for this context.
5. Call out what should stay simple and what actually deserves abstraction.
6. Capture risks, migration cost, and follow-up implications.

## Output

Report:

- decision to make
- options considered
- recommended structure
- dependency and boundary rules
- trade-offs
- migration or rollout implications
