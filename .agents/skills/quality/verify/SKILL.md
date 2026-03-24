---
name: verify
description: Map requested outcomes to fresh evidence before claiming the work is complete.
---

# Verify

Use this skill after implementation or before reporting success.

## Read First

- `.planning/REQUIREMENTS.md`
- `.planning/STATE.md`
- `.planning/CONVENTIONS.md` if it exists
- `protocols/verify.md`
- `references/scope-alignment.md` when the work may have drifted beyond the original intent

## Goals

- gather fresh evidence
- connect evidence to the requested outcome
- report any verification gaps honestly
- confirm the work still aligns with the intended scope, especially for validation samples or staged delivery
- distinguish local/unit/integration proof from true host-runtime proof instead of collapsing them into one confidence statement

## Steps

1. Identify the relevant requirement or user request.
2. Confirm the intended scope boundary before checking evidence.
3. Choose the closest proof commands or checks.
4. Explicitly classify each proof source: static, unit, integration, local smoke, hosted CI, or real host-runtime.
5. Run them.
6. Summarize what is verified and what is still partial.

## Output

Report:

- scope alignment
- verified
- partially verified
- not verified
- any evidence-boundary warning, especially when CI passes but real host validation was not run

Use Chinese for user-facing verification summaries by default, while keeping commands, paths, and protocol identifiers in English.
