---
name: incident-debug
description: Investigate production-like incidents with a containment-first, evidence-driven workflow that distinguishes active impact, probable cause, and next-safe action.
---

# Incident Debug

Use this skill when the problem is an outage, degraded service, production regression, reliability event, or time-sensitive operational failure.

## Read First

- current symptom, impact window, and affected scope
- dashboards, alerts, logs, traces, and recent deploys
- rollback or mitigation options already available
- `.planning/STATE.md` if it exists

## Goals

- stabilize the situation before chasing deep fixes
- separate confirmed facts from guesses
- narrow blast radius and restore service safely
- leave a clear evidence trail for follow-up repair

## Steps

1. State the incident symptom and user impact.
2. Check whether immediate mitigation is needed:
   - rollback
   - feature flag disable
   - traffic shed
   - queue pause
3. Collect direct evidence from alerts, logs, traces, and recent changes.
4. Form one concrete hypothesis at a time and test it quickly.
5. Recommend the safest next action:
   - mitigate now
   - repair now
   - gather one more missing fact
6. Capture what is confirmed, what is likely, and what remains uncertain.

## Output

Report:

- incident symptom and impact
- immediate mitigation status
- confirmed evidence
- most likely cause
- next safe action
- remaining uncertainty
