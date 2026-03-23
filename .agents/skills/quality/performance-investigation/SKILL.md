---
name: performance-investigation
description: Investigate latency, throughput, memory, and CPU issues with evidence-first profiling and bottleneck isolation before applying speculative optimizations.
---

# Performance Investigation

Use this skill when the problem is slow response time, poor throughput, memory growth, CPU pressure, rendering jank, or unclear runtime bottlenecks.

## Read First

- current symptom and measured baseline
- profiles, traces, benchmarks, or logs if available
- the hottest path or user-visible slow flow
- `.planning/STATE.md` if it exists

## Goals

- identify the dominant bottleneck before changing code
- distinguish measurement from assumption
- focus on the slowest meaningful path first
- recommend evidence-backed fixes, not speculative tuning

## Steps

1. Restate the performance symptom with numbers if possible.
2. Identify the measured hot path:
   - CPU
   - memory
   - I/O
   - network
   - rendering
3. Compare likely bottlenecks against actual evidence.
4. Test one optimization hypothesis at a time.
5. Recommend the smallest fix that materially improves the dominant bottleneck.
6. Define how improvement should be re-measured.

## Output

Report:

- symptom and baseline
- evidence used
- dominant bottleneck
- recommended optimization
- expected trade-offs
- re-measurement plan
