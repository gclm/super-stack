---
name: review
description: Perform a code review focused on correctness, regressions, security, and missing tests.
---

# Review

Use this skill when the user asks for a review or before merging meaningful changes.

Prefer this skill when the user wants findings, merge confidence, or risk discovery on work that already exists.
Do not use this skill as the default path for proving completion or validating a real user flow:

- use `verify` when the main question is "is the requested outcome actually done"
- use `qa` when the main question is runtime behavior, smoke confidence, or user-facing flow quality

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

## Rules

- stay findings-first instead of drifting into implementation planning
- prefer concrete break scenarios over abstract quality commentary
- call out missing verification when the diff cannot be trusted from inspection alone
- if the review reveals the main unresolved question is completion evidence, route forward to `verify`
- if the review reveals the main unresolved question is user-flow or runtime confidence, route forward to `qa`

## Output Rules

- list findings first, highest severity first
- include file references
- explain the failure mode
- mention missing tests when relevant
- mention default entrypoint or dev-flow regressions when relevant

If no findings exist, say that explicitly and note any residual uncertainty.

End by stating the best next step: `build`, `verify`, `qa`, or `ship`.
