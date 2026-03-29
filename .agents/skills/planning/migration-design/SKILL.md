---
name: migration-design
description: Plan schema or data migrations with rollout, backfill, compatibility, and rollback in mind before changing production persistence.
---

# Migration Design

Use this skill when a change touches existing data, schema evolution, backfill logic, or rollout safety across versions.

## Read First

- current schema and migration history
- deployment and rollback constraints
- data volume and downtime tolerance
- `docs/reference/requirements.md` and `harness/state.md` if they exist
- `harness/history.md` if it exists
## Goals

- make the migration sequence safe and explicit
- separate schema change from data backfill when needed
- avoid rollout plans that break mixed-version deployments
- capture rollback and repair paths before implementation

## Steps

1. Define what data shape is changing and why.
2. Check whether the system must support mixed old and new code during rollout.
3. Split the change into phases:
   - additive schema
   - dual-write or compatibility phase if needed
   - backfill
   - read-path switch
   - cleanup
4. Call out locking, batch size, retry, and observability concerns.
5. Define rollback or stop-the-rollout conditions.
6. Recommend the safest migration sequence with trade-offs.

## Output

Report:

- migration goal
- phased rollout plan
- compatibility strategy
- backfill and observability notes
- rollback path
- risks
