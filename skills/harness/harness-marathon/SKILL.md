---
name: harness-marathon
description: Run long tasks with checkpoints, resume discipline, and human escalation gates so work can continue across turns without losing context.
---

# Harness Marathon

Use when the task is long enough that checkpointing, resuming, and escalation rules matter.

## Read First

- `skills/harness/harness-marathon/references/progress-and-checkpoint-rules.md`
- `skills/harness/harness-marathon/references/human-escalation-gates.md`
- `skills/harness/harness-marathon/assets/task-progress.md`

## Goals

- keep long-running work resumable
- force periodic progress snapshots
- escalate when automation is looping without signal

## Process

1. define checkpoint cadence and current objective
2. keep `progress.md` current at each checkpoint
3. stop and escalate when the task hits low-signal repetition or blocked verification
4. hand the task back to `build`, `review`, `verify`, or `qa` with a clean progress snapshot
