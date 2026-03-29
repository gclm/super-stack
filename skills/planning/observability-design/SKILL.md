---
name: observability-design
description: Design logs, metrics, traces, alerts, and debugging signals so systems can be operated and diagnosed before incidents expose blind spots.
---

# Observability Design

Use this skill when a feature, service, background job, or integration needs better operational visibility before shipping or during a reliability improvement pass.

## Read First

- current logs, metrics, traces, dashboards, or alerting setup
- the flows or failure modes that matter most
- on-call, debugging, and incident response expectations
- `docs/reference/requirements.md` and `harness/state.md` if they exist
- `harness/history.md` if it exists
## Goals

- make important system behavior visible
- tie signals to real failure modes and operator questions
- avoid noisy telemetry that is expensive but not actionable
- ensure debugging evidence exists before production pressure hits

## Steps

1. Define the operator questions the system must answer.
2. Identify the key flows and failure modes.
3. Map signals to those flows:
   - structured logs
   - metrics
   - traces
   - events
4. Check cardinality, privacy, and cost constraints.
5. Define alerting only where an operator can take action.
6. Recommend the smallest useful observability set with trade-offs.

## Output

Report:

- target flows and failure modes
- recommended logs, metrics, and traces
- alerting guidance
- privacy or cost constraints
- gaps in current visibility
- recommendation
