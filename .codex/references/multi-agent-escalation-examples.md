# Multi-Agent Escalation Examples

Use this reference when Codex needs a concrete sanity check for whether sub-agents should be used.

The point is not to maximize delegation.
The point is to delegate only when parallel sidecar work will materially improve speed, clarity, or confidence without creating coordination drag.

## 1. Unfamiliar Repository Bugfix

- stage: `debug` or early `build`
- use sub-agent: yes, `super_stack_explorer`
- why:
  - the main thread can start reproducing or shaping hypotheses
  - a read-only helper can map entrypoints, related modules, and recent evidence in parallel
- avoid delegation when:
  - the bug lives in one already-open file and the main thread is blocked on reading that exact code path

## 2. Large Refactor Before Coding

- stage: `plan`
- use sub-agent: yes, `super_stack_planner`
- why:
  - decomposition, file scope, verification steps, and migration order can be prepared in parallel with local repository reading
  - this reduces mid-implementation plan drift
- avoid delegation when:
  - the refactor is actually a small local cleanup that the main thread can bound in minutes

## 3. High-Risk Merge Readiness

- stage: `review`
- use sub-agent: yes, `super_stack_reviewer`
- why:
  - the main thread can keep tracing context while a reviewer helper performs a findings-first pass
  - this is especially useful when the diff is broad, security-sensitive, or near release
- avoid delegation when:
  - there is no concrete diff or implemented behavior to inspect yet

## 4. Brownfield Feature In An Unclear Area

- stage: `map-codebase` or early `build`
- use sub-agent: yes, `super_stack_explorer`
- why:
  - the helper can gather file map, module ownership, and adjacent test surfaces while the main thread clarifies the requested outcome
- avoid delegation when:
  - the task boundary is still too fuzzy and should first backtrack to `discuss`

## 5. Phase Refresh After Scope Change

- stage: `plan`
- use sub-agent: yes, `super_stack_planner`
- why:
  - once scope, architecture, or rollout order changes, a planner helper can rewrite bounded phases and dependencies while the main thread validates the new direction with the user
- avoid delegation when:
  - the real issue is not sequencing but a missing product decision that still belongs in `discuss`

## 6. Runtime Or Startup Evidence Gathering

- stage: `debug`, `qa`, or `verify`
- use sub-agent: yes, `super_stack_explorer`
- why:
  - read-only collection of startup paths, scripts, docs, logs, and environment assumptions often parallelizes well
  - this helps separate product issues from setup issues
- avoid delegation when:
  - the next action is to directly edit the exact startup script being inspected

## 7. Single-File Tightly Coupled Change

- stage: `build`
- use sub-agent: no
- why:
  - the next critical-path step depends on one exact code path
  - delegation would only add handoff cost and duplicate reading
- better choice:
  - stay local and keep the change narrow

## 8. Overlapping Write-Scope Feature Work

- stage: `build`
- use sub-agent: usually no
- why:
  - if two helpers are likely to touch the same files or same fast-moving module boundary, coordination cost outweighs parallelism
- better choice:
  - either stay local or delegate read-only exploration only, then implement from the main thread

## Quick Decision Test

Use a sub-agent only if the answer is yes to all of these:

- can the subtask run in parallel with the next local step
- is the subtask bounded enough to describe in one short instruction
- can file ownership stay read-only or clearly disjoint
- will the result save more time than the coordination it introduces

If any answer is no, prefer staying local.
