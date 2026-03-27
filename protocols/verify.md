# Verification Protocol

Do not declare success without fresh evidence from the current state of the project.

Verification must distinguish implementation state from proof state.

## Verification Sources

- targeted tests
- full relevant test suite
- lint or typecheck
- build output
- screenshots or browser checks
- diff inspection

## Evidence Status

Use these labels explicitly in verification summaries when the task is non-trivial or when confidence could be misunderstood:

- `已实现`
  - code or configuration appears to satisfy the requested change
- `已验证`
  - fresh evidence directly proves the requested outcome
- `未验证`
  - implementation may exist, but no fresh proof was completed
- `缺口`
  - the remaining issue that prevents stronger confidence, such as missing tests, blocked environment, absent runtime hookup, or failed checks

Do not collapse `已实现` and `已验证` into one statement.
If only implementation evidence exists, say so directly instead of implying completion.

## Requirements

1. Match evidence to the requested outcome.
2. Prefer the narrowest command that proves the change.
3. Report partial verification honestly.
4. If verification could not run, explain why and what remains unverified.
5. State the strongest evidence reached and the next missing evidence level when that gap matters to delivery confidence.
