# Review Checklist

Use this reference when `review` is active and the diff is large, risky, or spans multiple subsystems.

## Review Priorities

Review in this order:

1. correctness and failure modes
2. regressions against current behavior
3. security and trust-boundary impact
4. missing tests or weak evidence

## Good Findings

Strong findings usually include:

- a concrete failure mode
- why the current change allows it
- who or what is affected
- what evidence is missing

## High-Signal Areas

- conditional logic changes
- error handling paths
- state transitions
- migrations and data writes
- auth and permission checks
- concurrency or retry behavior
- API contract changes

## Low-Signal Areas

Avoid spending time on:

- personal style preferences
- harmless formatting differences
- speculative refactors unrelated to risk

## No-Findings Rule

If no findings are discovered:

- say so explicitly
- mention residual uncertainty
- note major testing or scope limits
