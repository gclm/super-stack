---
name: discuss
description: Clarify the user's request, extract requirements, and prepare project memory before implementation starts.
---

# Discuss

Use this skill when the request is still fuzzy, the feature shape is incomplete, or the project needs a first-pass requirements capture.

## Goals

- understand the user outcome
- identify scope and non-goals
- capture constraints and acceptance signals
- write or update `.planning/PROJECT.md`, `.planning/REQUIREMENTS.md`, and `.planning/STATE.md`

## Steps

1. Read existing `.planning/` files if they exist.
2. Ask only the minimum clarifying questions needed to avoid risky assumptions.
3. Summarize the request as concrete requirements.
4. Persist the updated understanding into planning files.
5. Set `STATE.md` focus to planning.

## Output

Tell the user:

- what problem is being solved
- what was captured
- what remains uncertain
- that the next step is `plan`
