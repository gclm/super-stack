---
name: tdd-execution
description: Execute behavior changes with a RED -> GREEN -> REFACTOR loop when a practical automated test path exists.
---

# TDD Execution

Use this skill when implementing or fixing behavior that can be proven with automated tests.

## Read First

- `protocols/tdd.md`
- `docs/overview/roadmap.md` and `harness/state.md` if they exist
- `harness/history.md` if it exists
- the closest existing tests around the target behavior

## Goals

- define the expected behavior before production edits
- create a failing proof first when practical
- implement the smallest passing change
- keep verification tightly mapped to the requested outcome

## Steps

1. Identify the exact behavior to prove.
2. Choose the narrowest practical automated test.
3. Create or update the test so it fails for the expected reason.
4. Implement the smallest change that makes it pass.
5. Run the narrowest relevant test scope first.
6. Expand verification only as needed.
7. Refactor once behavior is passing and evidence is stable.

## Exceptions

If a RED step is not practical, state why clearly and use the closest concrete evidence path available instead of pretending the work was TDD.

## Output

Report:

- target behavior
- red evidence
- green evidence
- refactor summary
- remaining gaps
