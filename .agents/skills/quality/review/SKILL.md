---
name: review
description: Perform a code review focused on correctness, regressions, security, and missing tests.
---

# Review

Use this skill when the user asks for a review or before merging meaningful changes.

## Read First

- `protocols/review.md`
- diff against the target base
- impacted tests and relevant project docs
- `.planning/CONVENTIONS.md` if it exists
- `references/review-checklist.md` when the change is broad or risky

## Goals

- find real bugs and risks
- avoid style-only noise
- highlight missing evidence
- catch entrypoint, startup-path, and default-run regressions in addition to logic bugs

## Output Rules

- list findings first, highest severity first
- include file references
- explain the failure mode
- mention missing tests when relevant
- mention default entrypoint or dev-flow regressions when relevant

If no findings exist, say that explicitly and note any residual uncertainty.
