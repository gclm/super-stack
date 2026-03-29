# Incident Triage

Use this reference when `incident-debug` is active and you need a tighter containment-first flow.

## First Five Minutes

1. confirm user impact and blast radius
2. check if rollback or feature-flag mitigation exists
3. inspect the closest alerts, logs, and recent deploys
4. avoid broad changes before a likely cause exists

## Safe Next Actions

- rollback the last risky deploy
- disable the smallest feature flag that reduces impact
- pause consumers or background jobs when queues are cascading
- rate limit or shed non-critical traffic

## Evidence Ladder

Prefer this order:

1. current symptom and impact
2. deploy/config timeline
3. logs and traces around the failure window
4. dependency health
5. deeper code-path hypothesis

## Reporting Rules

- say what is confirmed now
- say what is only likely
- recommend one next safe action, not five parallel guesses
