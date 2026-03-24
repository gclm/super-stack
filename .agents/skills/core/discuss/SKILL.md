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
- `references/request-shaping.md` when hidden assumptions, design intent, or artifact type could change the outcome

## Goals

- understand the user outcome
- identify scope and non-goals
- capture constraints and acceptance signals
- write or update `.planning/PROJECT.md`, `.planning/REQUIREMENTS.md`, and `.planning/STATE.md`
- establish language, review, and confirmation conventions early when they matter
- make the scope mode explicit when the work may be a validation sample instead of direct product delivery
- default user-facing summaries, requirement restatements, and clarification language to Chinese unless the project clearly requires another language
- when the request is ambiguous, high-stakes, or likely built on hidden assumptions, surface those assumptions before committing to an answer or implementation

## Steps

1. Read existing `.planning/` files if they exist.
2. Identify whether the user is asking for product delivery, a validation sample, or an exploratory comparison.
3. Use `references/request-shaping.md` when hidden assumptions, design intent, or artifact type could change the path.
4. If the problem is likely shaped by hidden assumptions, list the main assumptions, missing information, and the most common mistake before asking for more input.
5. Ask only the minimum clarifying questions needed to avoid risky assumptions.
6. Summarize the request as concrete requirements, scope boundaries, and non-goals.
7. Capture project conventions that will affect follow-up stages, such as documentation language, commit rules, or review expectations.
8. Persist the updated understanding into planning files.
9. Set `STATE.md` focus to planning.

## Output

Tell the user:

- what problem is being solved
- what assumptions or unknowns materially affect the answer when relevant
- what artifact type or exploration mode was identified when relevant
- what was captured
- what remains uncertain
- what scope mode or conventions were fixed early
- that the next step is `plan`
