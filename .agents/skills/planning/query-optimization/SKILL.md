---
name: query-optimization
description: Analyze slow or expensive queries and recommend indexing, shape, and access-path improvements before performance issues harden into the design.
---

# Query Optimization

Use this skill when the problem is query latency, scan cost, N+1 access, pagination inefficiency, or uncertainty about the right index or access path.

## Read First

- query code and ORM usage
- explain plans, logs, or observed latency evidence
- table sizes and expected growth
- `.planning/STATE.md` if it exists

## Goals

- optimize based on evidence instead of folklore
- match indexes to real filters, joins, and sort paths
- separate query-shape fixes from schema fixes
- avoid local optimizations that hurt write cost or correctness

## Steps

1. Restate the slow path and its evidence.
2. Identify the exact query shape:
   - filters
   - joins
   - ordering
   - pagination
   - selected columns
3. Check for obvious waste:
   - N+1 access
   - wide selects
   - missing limits
   - unbounded scans
4. Compare improvement options:
   - query rewrite
   - index change
   - denormalization or cache
5. Estimate the write, storage, and maintenance cost of the optimization.
6. Recommend the smallest evidence-backed improvement first.

## Output

Report:

- slow path summary
- query shape
- evidence used
- recommended optimization
- cost or trade-off
- verification plan
