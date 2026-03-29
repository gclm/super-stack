---
name: release-check
description: Perform a release-readiness pass that checks evidence, rollback awareness, known risks, and handoff clarity before calling work ready.
---

# Release Check

Use this skill near the end of delivery when the question is not "did we change the code" but "is this actually ready to hand off, merge, or release".

## Read First

- `harness/state.md` if it exists
- `docs/overview/roadmap.md` if it exists
- `docs/reference/conventions.md` if it exists
- recent verification or QA evidence
- diff summary or release scope summary

## Goals

- check whether readiness is supported by current evidence
- surface blockers, residual risk, and rollback concerns
- make handoff and merge decisions explicit
- catch scope drift and release-entry regressions before calling work ready

## Steps

1. Restate the release or handoff scope.
2. Review the latest verification evidence.
3. Check whether known blockers or high-risk findings remain open.
4. Confirm what was not tested or not proven.
5. Check whether default run paths, startup paths, or handoff commands still behave as expected.
6. Capture rollback or recovery considerations when relevant.
7. Conclude with a readiness status instead of vague optimism.

## Output

Report:

- scope checked
- ready / not ready / ready with caveats
- scope alignment
- supporting evidence
- unresolved risks
- rollback notes
- recommended next action
