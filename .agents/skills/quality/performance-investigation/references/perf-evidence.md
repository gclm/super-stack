# Performance Evidence

Use this reference when `performance-investigation` is active and you need a sharper measurement workflow.

## Symptom Types

- latency spike
- poor steady-state throughput
- CPU saturation
- memory growth or leak
- I/O wait or network stall
- rendering jank

## Evidence Sources

- benchmark or timing output
- traces or spans
- CPU profiles
- heap or allocation data
- query plans
- browser performance traces

## Investigation Order

1. confirm the symptom with a number
2. isolate the hottest path
3. test one bottleneck hypothesis
4. re-measure after the change

## Anti-Patterns

- optimizing without a baseline
- changing several subsystems before re-measuring
- treating cache as the first answer to every slowdown
- assuming CPU when the bottleneck is actually network or I/O
