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
- `.planning/CONVENTIONS.md` if it exists
- relevant local code and docs when the request targets an existing codebase
- `references/reference-reuse-boundary.md` when the decision involves reusing another project's structure or implementation

## Goals

- surface the real decision
- generate 2-3 realistic approaches
- explain trade-offs in plain language
- recommend the strongest option
- persist the decision context for later planning
- expose hidden assumptions and missing facts when they materially change which option is best

## When To Use

Good triggers:

- new feature architecture
- build vs buy decision
- data model or API shape decision
- background job or workflow choice
- frontend interaction pattern choice
- validation sample vs product implementation path
- reference structure reuse vs direct implementation reuse
- "what's the best way to do this?"

Do not use this skill when the work is already obvious and low risk.

## Approach Rules

Before comparing options, if the problem statement is likely carrying hidden assumptions, briefly surface:

- the main hidden assumptions
- the missing information that would change the recommendation
- the most common mistake people make on this kind of decision

For each option, include:

- approach name
- what it looks like in practice
- main advantages
- main costs or risks
- implementation complexity: low, medium, or high
- when this option is best

Keep options credible. Avoid fake alternatives that only exist to make one recommendation look easy.

When a reference project is involved, explicitly say whether each option reuses:

- information architecture
- interaction structure
- implementation details

## Decision Format

Use this structure:

1. Problem framing
2. Assumptions and missing information when relevant
3. Option A
4. Option B
5. Option C if a third option adds real value
6. Recommendation
7. Open questions, if any

## Persistence

If `.planning/STATE.md` exists, update current focus to reflect the decision being shaped.

If `.planning/PROJECT.md` or `.planning/REQUIREMENTS.md` exist, add a concise note about:

- chosen approach
- important rejected alternative
- why the chosen option won
- the scope mode, such as validation-first or implementation-first

If planning files do not exist yet, provide the recommendation in chat and note that `discuss` or `plan` should capture it next.

## Output

Tell the user:

- what decision was analyzed
- the recommended approach
- the biggest trade-off they are accepting
- that the next step is usually `plan`
