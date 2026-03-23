---
name: debug
description: Diagnose bugs, failing tests, and unexpected behavior with a reproduce-observe-hypothesis-verify loop before fixing.
---

# Debug

Use this skill when the problem is a bug, failing test, flaky behavior, incorrect output, or unexplained runtime issue.

## Read First

- `protocols/debug.md`
- `.planning/STATE.md` if it exists
- the closest failing test, log, stack trace, or reproduction steps

## Goals

- reproduce the issue or narrow the uncertainty
- identify the confirmed root cause before editing
- avoid guess-and-patch behavior
- capture what was verified and what is still uncertain

## Steps

1. Restate the observed symptom in concrete terms.
2. Find the closest reproduction path.
3. Collect direct evidence:
   - failing tests
   - logs
   - stack traces
   - screenshots
   - request/response traces
4. Form one concrete hypothesis at a time.
5. Test the hypothesis before making a broader fix.
6. Apply the smallest confirmed fix.
7. Verify both:
   - the original bug is closed
   - the most likely regression path still works

## Output

Report:

- symptom
- reproduction
- root cause
- fix
- verification
- remaining risk
