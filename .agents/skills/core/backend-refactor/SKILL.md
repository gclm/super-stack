---
name: backend-refactor
description: Refactor backend code by separating domain logic, transport, persistence, and side effects so maintainability improves without accidental behavior drift.
---

# Backend Refactor

Use this skill when backend code has become tangled and the goal is to improve structure, testability, and change safety without rewriting the whole service.

## Read First

- the entry handlers, services, models, and side-effect boundaries involved
- current tests and failure-prone flows
- `docs/overview/roadmap.md` and `harness/state.md` if they exist
- `harness/history.md` if it exists
## Goals

- separate transport, domain, persistence, and integration concerns
- make behavior-preserving refactors explicit
- leave clearer seams for testing and future changes
- reduce hidden coupling without over-abstracting

## Steps

1. Define the refactor target:
   - fat handler
   - mixed domain and persistence logic
   - repeated integration code
   - unclear module ownership
2. Identify behavior that must remain stable.
3. Extract one stable seam at a time:
   - validation
   - mapping
   - domain rules
   - repository access
   - side-effect adapters
4. Keep API and storage changes out unless explicitly in scope.
5. Add or preserve tests around the risky seams before deeper cleanup.
6. Verify the original flow still works after each slice.

## Output

Report:

- refactor target
- stable behavior constraints
- seams extracted or clarified
- risky areas
- verification evidence
