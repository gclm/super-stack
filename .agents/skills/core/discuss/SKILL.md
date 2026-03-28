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
- `references/request-shaping.md` when hidden assumptions, design intent, artifact type, or document depth could change the path

## Goals

- understand the user outcome
- identify scope and non-goals
- capture constraints and acceptance signals
- write or update `.planning/PROJECT.md`, `.planning/REQUIREMENTS.md`, and `.planning/STATE.md`
- establish language, review, and confirmation conventions early when they matter
- make the scope mode explicit when the work may be a validation sample instead of direct product delivery
- identify the document depth when the user is asking for a proposal, design doc, architecture note, or module design
- make the delivery shape explicit when the request could reasonably mean either analysis-only output or direct repository edits
- default user-facing summaries, requirement restatements, and clarification language to Chinese unless the project clearly requires another language
- when the request is ambiguous, high-stakes, or likely built on hidden assumptions, surface those assumptions before committing to an answer or implementation

## Steps

1. Read existing `.planning/` files if they exist.
2. Identify whether the user is asking for product delivery, a validation sample, or an exploratory comparison.
3. Use `references/request-shaping.md` when hidden assumptions, design intent, or artifact type could change the path.
4. If the request is for a proposal, design document, architecture note, or module design, make the primary reader, the document purpose, and the depth mode explicit when they will materially shape the draft: `brief`, `standard`, or `deep`.
5. If the request mixes analysis/design wording with possible implementation wording, explicitly choose the delivery shape before `build`: discussion-only, proposal plus plan, or direct patching.
6. Default proposal-style document requests to `standard` unless the user clearly asks for a lighter review memo or a deeper implementation appendix.
7. If the problem is likely shaped by hidden assumptions, list the main assumptions, missing information, and the most common mistake before asking for more input.
8. Ask only the minimum clarifying questions needed to avoid risky assumptions.
9. Summarize the request as concrete requirements, scope boundaries, and non-goals.
10. Capture project conventions that will affect follow-up stages, such as documentation language, commit rules, or review expectations.
11. Persist the updated understanding into planning files.
12. Set `STATE.md` focus to planning.

## Output

Tell the user:

- what problem is being solved
- what assumptions or unknowns materially affect the answer when relevant
- what artifact type or exploration mode was identified when relevant
- what document depth was selected when the task is proposal- or design-doc oriented
- what delivery shape was selected when the task could have led either to discussion-only output or direct edits
- what was captured
- what remains uncertain
- what scope mode or conventions were fixed early
- that the next step is `plan`
