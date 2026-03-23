# TDD Protocol

Use RED -> GREEN -> REFACTOR whenever the target project has an automated test path.

## Rules

1. Write or update a test before production code when the behavior is testable.
2. Confirm the test fails for the expected reason.
3. Implement the smallest change that makes the test pass.
4. Run the most relevant test scope first, then expand if needed.
5. Refactor only after behavior is passing.
6. Do not hide gaps in coverage when the behavior could reasonably be tested.

## Exceptions

If the task is documentation, configuration wiring, or environment bootstrap where a failing test is not practical, state that clearly and verify with the closest concrete evidence available.
