---
name: security-review
description: Review code and design changes for auth, data exposure, trust boundaries, misuse paths, and remediation priority before security debt hardens.
---

# Security Review

Use this skill when a change affects authentication, authorization, secrets, user data, file access, network boundaries, privileged actions, or externally reachable attack surface.

## Read First

- code diff or design under review
- auth and permission model
- data classification and trust boundaries
- relevant config, env handling, and integration points
- `references/security-checklist.md` when you need a deeper review checklist

## Goals

- identify practical security weaknesses before release
- focus on real trust boundaries and abuse paths
- separate critical findings from lower-risk hygiene issues
- avoid vague “be secure” advice without concrete impact

## Steps

1. Identify assets and trust boundaries.
2. Review the most relevant entry points and abuse paths.
3. Assess exploitability and likely impact.
4. Recommend the highest-priority fixes first.
5. Note any remaining residual risk or missing evidence.

Read `references/security-checklist.md` when you need a more detailed pass.

## Output

Report:

- trust boundaries reviewed
- findings ordered by severity
- likely impact
- recommended fixes
- residual risk
- missing evidence or test gaps
