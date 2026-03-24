---
name: discuss
description: Clarify the user's request, extract requirements, and prepare project memory before implementation starts.
---

# Discuss

Use this skill when the request is still fuzzy, the feature shape is incomplete, or the project needs a first-pass requirements capture.

## Read First

- `.planning/PROJECT.md` if it exists
- `.planning/REQUIREMENTS.md` if it exists
- `.planning/STATE.md` if it exists
- `.planning/CONVENTIONS.md` if it exists
- relevant project docs or user-provided reference material
- `references/scope-modes.md` when the project may be a validation sample, staged hybrid, or direct product path

## Goals

- understand the user outcome
- identify scope and non-goals
- capture constraints and acceptance signals
- write or update `.planning/PROJECT.md`, `.planning/REQUIREMENTS.md`, and `.planning/STATE.md`
- establish language, review, and confirmation conventions early when they matter
- make the scope mode explicit when the work may be a validation sample instead of direct product delivery

## Steps

1. Read existing `.planning/` files if they exist.
2. Identify whether the user is asking for product delivery, a validation sample, or an exploratory comparison.
3. Ask only the minimum clarifying questions needed to avoid risky assumptions.
4. Summarize the request as concrete requirements, scope boundaries, and non-goals.
5. Capture project conventions that will affect follow-up stages, such as documentation language, commit rules, or review expectations.
6. Persist the updated understanding into planning files.
7. Set `STATE.md` focus to planning.

## Output

Tell the user:

- what problem is being solved
- what was captured
- what remains uncertain
- what scope mode or conventions were fixed early
- that the next step is `plan`
