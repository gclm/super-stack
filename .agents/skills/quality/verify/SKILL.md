---
name: verify
description: Map requested outcomes to fresh evidence before claiming the work is complete.
---

# Verify

Use this skill after implementation or before reporting success.

Prefer this skill when implementation already exists and the remaining question is whether the requested outcome has actually been achieved.
Do not use this skill as a substitute for findings-first review or user-flow QA:

- use `review` when the user mainly wants risks, regressions, or merge blockers
- use `qa` when confidence depends on runtime behavior, smoke checks, browser interaction, or user-visible flows

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
- catch cases where implementation drifted from the latest approved plan or where evidence is blocked by environment setup rather than product logic

## Rules

- treat verification as evidence mapping, not broad bug hunting
- prefer the narrowest fresh proof that actually answers the user request
- classify evidence boundaries explicitly instead of collapsing CI, local smoke, and real host-runtime into one confidence claim
- if verification reveals likely defects or regressions that need findings-first treatment, route back to `review` or `build`
- if verification reveals the missing confidence is really about user-flow or runtime behavior, route to `qa`

## Steps

1. Identify the relevant requirement or user request.
2. Confirm the intended scope boundary before checking evidence.
3. Choose the closest proof commands or checks.
4. Explicitly classify each proof source: static, unit, integration, local smoke, hosted CI, or real host-runtime.
5. When a check fails, distinguish missing tools from shell-init or runtime-environment issues before concluding the feature is unverified.
6. Run them.
7. Summarize what is verified and what is still partial.

## Output

Report:

- scope alignment
- verified
- partially verified
- not verified
- any evidence-boundary warning, especially when CI passes but real host validation was not run
- any environment-boundary warning when verification is blocked by shell setup, runtime activation, login state, or host-only dependencies

Use Chinese for user-facing verification summaries by default, while keeping commands, paths, and protocol identifiers in English.

End by stating the best next step: `build`, `qa`, or `ship`.
