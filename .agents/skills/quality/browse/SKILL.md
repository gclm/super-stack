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

- `~/.super-stack/runtime/bin/super-stack-browser`
- `~/.super-stack/runtime/bin/super-stack-browser-health`
- `~/.super-stack/runtime/bin/super-stack-browser-reset`

This wrapper exists to keep browser auto-connect and session reuse stable.
`super-stack-browser-health` is the preflight/postflight probe for leaked headless Chrome, stale `browser_use` residue, and unexpectedly high Chrome RSS.
`super-stack-browser-reset` is the recovery path when the stable session drifts, hangs, or accumulates too much state.

If browser tooling is unavailable, say so clearly and fall back to:

- screenshots
- local preview inspection
- logs and test output
- code-level reasoning with explicit limits

## Steps

1. Restate the exact browser-side question.
2. In super-stack environments, preflight with `~/.super-stack/runtime/bin/super-stack-browser-health`.
3. The preflight check is mandatory before browse work when any of the following is true:
   - this host has already run browser automation earlier in the day
   - the previous browser task ended abnormally or was interrupted
   - the task is expected to be multi-page, authenticated, or longer than a quick spot check
   - there has been recent memory-growth, leaked-process, or headless-Chrome suspicion
4. If the health check shows unexpected headless Chrome residue, `browser_use` residue, or an obviously unhealthy stable session, run `~/.super-stack/runtime/bin/super-stack-browser-reset` before continuing.
5. Open the relevant page or flow with `super-stack-browser`.
6. Reproduce the target interaction.
7. Collect only the evidence needed:
   - DOM
   - styles
   - console
   - network
   - screenshot
8. Tie the observation back to the claimed bug or acceptance criterion.
9. Postflight with `~/.super-stack/runtime/bin/super-stack-browser-health` when any of the following is true:
   - the task navigated across multiple pages or tabs
   - the task used login state, uploads, long-lived flows, or repeated interactions
   - console/network investigation was part of the run
   - the session now feels slow, sticky, or suspicious
10. If postflight still shows residue or abnormal Chrome RSS, run `~/.super-stack/runtime/bin/super-stack-browser-reset`.
11. Report what was confirmed, what was not reproduced, and any tooling limits.

## Lifecycle Rules

- Default to the single stable session provided by `super-stack-browser` for serial work.
- Do not improvise alternative browser stacks such as `browser_use` when `super-stack-browser` is available.
- Do not let concurrent independent tasks share one live browser session; use isolation only when the host workflow explicitly requires concurrent browser tasks.
- Treat `~/.super-stack/runtime/bin/super-stack-browser-health` as the first stop for memory-growth or leaked-process suspicion.
- Treat `~/.super-stack/runtime/bin/super-stack-browser-reset` as the supported cleanup path instead of manual ad hoc killing.

## Output

Report:

- page or flow inspected
- actions performed
- browser evidence collected
- confirmed observations
- unresolved questions
- next best step
- whether browser health/reset steps were needed
