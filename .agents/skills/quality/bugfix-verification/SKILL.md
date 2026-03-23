---
name: bugfix-verification
description: Verify that a bugfix actually closes the reported symptom, proves the root cause path, and does not reintroduce the most likely regression.
---

# Bugfix Verification

Use this skill after a bugfix when the real question is not "did the code change" but "is the reported bug actually closed".

## Read First

- the bug report, failing test, or reproduction notes
- `.planning/STATE.md` if it exists
- the latest fix diff or summary
- the closest relevant verification evidence

## Goals

- prove the original symptom is gone
- confirm the fix maps to the actual root cause path
- check the most likely regression edge
- report any remaining uncertainty honestly

## Steps

1. Restate the original symptom in observable terms.
2. Identify the exact path that should now behave differently.
3. Run the narrowest reproduction or test that proves the bug is closed.
4. Check one neighboring path that is most likely to regress.
5. State whether the fix is:
   - verified
   - partially verified
   - not verified

## Output

Report:

- original symptom
- proof the symptom is closed
- regression path checked
- verification status
- remaining gap
