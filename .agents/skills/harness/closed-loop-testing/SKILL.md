---
name: closed-loop-testing
description: Collect fresh evidence into a task-local evidence pack and turn implemented work into a structured verdict before calling it done.
---

# Closed Loop Testing

Use when a task needs fresh evidence before it can be treated as complete.

## Read First

- `.agents/skills/harness/closed-loop-testing/references/evidence-pack-format.md`
- `.agents/skills/harness/closed-loop-testing/assets/evidence-index.json`
- `.agents/skills/harness/closed-loop-testing/assets/verdict.json`
- `protocols/verify.md`

## Goals

- collect the strongest available evidence
- update the task-local evidence pack
- separate implemented, verified, unverified, and remaining risks

## Process

1. identify the strongest available validation path
2. collect evidence into `evidence-index.json`
3. summarize the outcome in `verdict.json`
4. escalate to `verify` or `qa` when the task still needs stronger proof
