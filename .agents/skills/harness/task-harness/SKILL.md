---
name: task-harness
description: Initialize a durable task pack under harness/tasks so long-running work has stable brief, progress, decisions, evidence, and verdict artifacts.
---

# Task Harness

Use when the work should be anchored in `harness/tasks/<task-id>/` instead of only living in chat context.

## Read First

- `.agents/skills/harness/task-harness/references/task-artifact-contract.md`
- `.agents/skills/harness/task-harness/references/progress-and-checkpoint-rules.md`
- `.agents/skills/harness/task-harness/assets/task-brief.md`
- `.agents/skills/harness/task-harness/assets/task-progress.md`
- `.agents/skills/harness/task-harness/assets/task-decisions.md`
- `.agents/skills/harness/task-harness/assets/evidence-index.json`
- `.agents/skills/harness/task-harness/assets/verdict.json`

## Goals

- initialize a durable task pack
- keep task scope explicit
- leave stable artifacts for later `review / verify / qa`

## Process

1. choose or create a `task-id`
2. initialize `harness/tasks/<task-id>/`
3. write the first brief and progress snapshot
4. route the next step to `build`, `review`, `verify`, or `qa`
