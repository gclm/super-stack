---
name: scalability-check
description: Review throughput, latency, concurrency, storage, and operational pressure points before a system change ships with hidden scale limits.
---

# Scalability Check

Use this skill when a feature or architecture decision may be constrained by load, concurrency, burst traffic, storage growth, or background processing pressure.

## Read First

- current architecture and bottlenecks
- workload assumptions and traffic shape
- queue, cache, database, and external dependency behavior
- `docs/reference/requirements.md` and `harness/state.md` if they exist
- `harness/history.md` if it exists
## Goals

- identify the first likely scale limits
- tie concerns to concrete workload assumptions
- distinguish present needs from premature optimization
- recommend focused protections before bigger rewrites

## Steps

1. Define the workload being evaluated:
   - request volume
   - concurrency
   - data growth
   - fan-out
   - background jobs
2. Identify pressure points:
   - CPU
   - memory
   - database
   - queue
   - external APIs
3. Check failure modes under load:
   - timeouts
   - hot rows
   - retry storms
   - unbounded backlog
4. Compare mitigation options:
   - caching
   - batching
   - queueing
   - partitioning
   - rate limiting
   - architecture split
5. Recommend what to fix now vs later.
6. Define measurable indicators to watch.

## Output

Report:

- workload assumption
- likely bottlenecks
- immediate mitigations
- deferred concerns
- metrics to watch
- recommendation
