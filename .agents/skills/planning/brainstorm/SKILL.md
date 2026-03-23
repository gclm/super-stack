---
name: brainstorm
description: Explore 2-3 credible implementation approaches, compare trade-offs, and converge on a recommendation before detailed planning.
---

# Brainstorm

Use this skill when the user has a feature idea, architecture question, workflow choice, or a non-trivial design decision that should be compared before committing to a plan.

## Read First

- `.planning/PROJECT.md` if it exists
- `.planning/REQUIREMENTS.md` if it exists
- `.planning/STATE.md` if it exists
- relevant local code and docs when the request targets an existing codebase

## Goals

- surface the real decision
- generate 2-3 realistic approaches
- explain trade-offs in plain language
- recommend the strongest option
- persist the decision context for later planning

## When To Use

Good triggers:

- new feature architecture
- build vs buy decision
- data model or API shape decision
- background job or workflow choice
- frontend interaction pattern choice
- "what's the best way to do this?"

Do not use this skill when the work is already obvious and low risk.

## Approach Rules

For each option, include:

- approach name
- what it looks like in practice
- main advantages
- main costs or risks
- implementation complexity: low, medium, or high
- when this option is best

Keep options credible. Avoid fake alternatives that only exist to make one recommendation look easy.

## Decision Format

Use this structure:

1. Problem framing
2. Option A
3. Option B
4. Option C if a third option adds real value
5. Recommendation
6. Open questions, if any

## Persistence

If `.planning/STATE.md` exists, update current focus to reflect the decision being shaped.

If `.planning/PROJECT.md` or `.planning/REQUIREMENTS.md` exist, add a concise note about:

- chosen approach
- important rejected alternative
- why the chosen option won

If planning files do not exist yet, provide the recommendation in chat and note that `discuss` or `plan` should capture it next.

## Output

Tell the user:

- what decision was analyzed
- the recommended approach
- the biggest trade-off they are accepting
- that the next step is usually `plan`
