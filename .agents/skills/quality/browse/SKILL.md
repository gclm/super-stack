---
name: browse
description: Use browser-side inspection to validate UI behavior, DOM state, styles, console errors, and network activity when code or tests alone are not enough.
---

# Browse

Use this skill when the task needs direct browser evidence rather than only static code inspection or test output.

## Read First

- the target flow, page, or user action to inspect
- any local run or preview instructions
- relevant acceptance criteria or bug symptoms
- `.planning/STATE.md` if it exists
- `references/browser-evidence-patterns.md` when you need a more concrete evidence checklist

## Goals

- confirm browser-visible behavior with direct evidence
- inspect runtime state that code reading cannot prove
- distinguish DOM, style, console, and network failures
- leave behind a clear summary of what was actually observed

## Good Triggers

- UI behavior differs from expectation
- layout, styling, or responsive issues need proof
- console errors or failed network requests may explain a bug
- a browser interaction must be validated before calling work done
- screenshots or runtime evidence are more trustworthy than static review

For more concrete evidence selection patterns, read `references/browser-evidence-patterns.md`.

## Host Guidance

- Claude Code: prefer `super-stack-browser` when the host has super-stack browser capability configured
- Codex: prefer `super-stack-browser` when the host has super-stack browser capability configured

For super-stack environments, the intended default browser entry is:

- `~/.claude-stack/bin/super-stack-browser`

This wrapper exists to keep browser auto-connect and session reuse stable.

If browser tooling is unavailable, say so clearly and fall back to:

- screenshots
- local preview inspection
- logs and test output
- code-level reasoning with explicit limits

## Steps

1. Restate the exact browser-side question.
2. Open the relevant page or flow.
3. Reproduce the target interaction.
4. Collect only the evidence needed:
   - DOM
   - styles
   - console
   - network
   - screenshot
5. Tie the observation back to the claimed bug or acceptance criterion.
6. Report what was confirmed, what was not reproduced, and any tooling limits.

## Output

Report:

- page or flow inspected
- actions performed
- browser evidence collected
- confirmed observations
- unresolved questions
- next best step
