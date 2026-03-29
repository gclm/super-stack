---
name: architecture-guardrails
description: Keep long-running work inside agreed boundaries by tracking scope drift, upgrade conditions, and design decisions before implementation silently expands.
---

# Architecture Guardrails

Use when a task is at risk of drifting across architecture, migration, API, or service-boundary lines.

## Read First

- `skills/harness/architecture-guardrails/references/scope-drift-signals.md`
- `skills/harness/architecture-guardrails/references/human-escalation-gates.md`
- `docs/architecture/decisions/runtime-promotion-gates.md`

## Goals

- keep scope and non-goals explicit
- detect when execution should step back to `plan`
- record decisions before the task silently changes shape

## Process

1. restate the current scope and non-goals
2. look for scope-drift signals
3. decide whether the task can continue in `build`
4. escalate to `plan`, proposal, ADR, or review when needed
