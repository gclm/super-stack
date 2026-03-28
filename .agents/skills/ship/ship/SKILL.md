---
name: ship
description: Prepare the current work for handoff or merge by checking final quality, release readiness, and follow-up tasks.
---

# Ship

Use this skill when implementation is complete enough to prepare a handoff, PR, or merge.

## Read First

- `.planning/STATE.md`
- `.planning/ROADMAP.md`
- `.planning/CONVENTIONS.md` if it exists
- `protocols/verify.md`
- project release conventions
- `references/handoff-checks.md` when the handoff needs a sharper completion checklist

## Goals

- confirm the work is ready to hand off
- identify remaining release blockers
- summarize the change cleanly
- ensure the reported readiness matches the intended scope rather than an accidentally expanded one
- make the final handoff explicit about what is done, what is proven, what constraints remain, and what is intentionally deferred

## Steps

1. Confirm the active work is verified.
2. Inspect diff and project status.
3. Check whether the delivered work still matches the originally intended scope.
4. Use `references/handoff-checks.md` to confirm the handoff includes completed scope, verification evidence, behavior constraints, and intentionally deferred items.
5. Note release blockers, docs drift, commit-readiness, or rollback concerns.
6. If the work is not being merged immediately, say whether the current state should be captured as a stage-boundary checkpoint commit.
7. Produce a concise release summary.

## Output

Include:

- readiness status
- completed scope
- verification evidence
- current behavior constraints
- intentionally not included or follow-up items
- outstanding blockers, if any
- scope alignment
- whether the work should be committed now as a recoverable checkpoint
- recommended next action such as commit, PR, deploy, or follow-up fix
