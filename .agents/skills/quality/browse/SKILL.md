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
- `references/content-acquisition-patterns.md` when the task is really about acquiring article or post content from a live page
- `references/frontend-debug-playbooks.md` when the task is a recurring frontend bug pattern such as white screen, API failure, layout regression, or auth loop

## Goals

- confirm browser-visible behavior with direct evidence
- inspect runtime state that code reading cannot prove
- distinguish DOM, style, console, and network failures
- leave behind a clear summary of what was actually observed
- establish `browse` as the base capability for future browser-driven automation

## Modes

Treat `browse` as one browser foundation with three modes:

1. `content-read`
   - acquire visible content from pages such as WeChat articles, Xiaohongshu notes, Douyin pages, and Juejin articles
2. `content-publish`
   - future browser-side drafting and publishing actions with external side effects
3. `frontend-debug`
   - inspect DOM, styles, console, network, and runtime UI behavior

Current implementation priority:

- `content-read` is the stable default expansion path
- `frontend-debug` remains a core existing use case
- `content-publish` should be treated as future capability and must keep strong confirmation boundaries

## Good Triggers

- UI behavior differs from expectation
- layout, styling, or responsive issues need proof
- console errors or failed network requests may explain a bug
- a browser interaction must be validated before calling work done
- screenshots or runtime evidence are more trustworthy than static review

For more concrete evidence selection patterns, read `references/browser-evidence-patterns.md`.

## Strong Triggers

Default to `browse` when any of the following is true:

- the user provides a concrete URL and asks to analyze the page content
- the user asks to inspect a webpage, article, post, or document page they linked directly
- the page is likely to be login-gated, verification-gated, dynamic, or socially rendered, such as WeChat articles, Xiaohongshu posts, Douyin pages, or similar surfaces
- the answer depends on the original page title, author, body text, DOM, screenshot, console, or network behavior
- static fetches or search summaries may diverge from what the user actually sees in the browser
- the request is really about extracting or viewing article/post content from a live page, not just debugging UI behavior

When these conditions hold, do not begin with mirror pages, raw HTML fetching, or search snippets unless browser tooling is unavailable.

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

## Fallback Order

When original-page browser evidence cannot be obtained, use this fallback order:

1. user-provided screenshots or pasted page text
2. trusted mirrors or reposts
3. raw HTML or static fetch extraction
4. search snippets or third-party summaries

If anything below original-page browser evidence is used, say so explicitly in the report.

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
7. For page or article analysis, collect the smallest original-page evidence set first:
   - landed URL
   - page title
   - the main rendered content container when available
   - `document.body.innerText` only as a fallback when no better content container is obvious
   - platform-specific structured fields such as author, publish time, summary, comments, and image URLs when the adapter supports them
8. Collect only the extra evidence needed:
   - DOM
   - styles
   - console
   - network
   - screenshot
9. Tie the observation back to the claimed bug or acceptance criterion.
10. Postflight with `~/.super-stack/runtime/bin/super-stack-browser-health` when any of the following is true:
   - the task navigated across multiple pages or tabs
   - the task used login state, uploads, long-lived flows, or repeated interactions
   - console/network investigation was part of the run
   - the session now feels slow, sticky, or suspicious
11. If postflight still shows residue or abnormal Chrome RSS, run `~/.super-stack/runtime/bin/super-stack-browser-reset`.
12. Report what was confirmed, what was not reproduced, and any tooling limits.

For frontend bug triage, prefer a structure-first investigation:

1. reproduce the symptom
2. capture snapshot evidence
3. inspect styles for the affected node when structure looks suspicious
4. inspect console and page errors
5. inspect network requests
6. only then escalate to broader screenshots or flow-level QA

When the affected area is known, narrow the structure evidence with a selector-scoped snapshot instead of reading the whole page first.
When the suspected failure is data-driven, use a network filter to focus the request log before broad network inspection.

## Lifecycle Rules

- Default to the single stable session provided by `super-stack-browser` for serial work.
- Do not improvise alternative browser stacks such as `browser_use` when `super-stack-browser` is available.
- Do not let concurrent independent tasks share one live browser session; use isolation only when the host workflow explicitly requires concurrent browser tasks.
- Treat `~/.super-stack/runtime/bin/super-stack-browser-health` as the first stop for memory-growth or leaked-process suspicion.
- Treat `~/.super-stack/runtime/bin/super-stack-browser-reset` as the supported cleanup path instead of manual ad hoc killing.
- For `content-publish`, do not treat “draft filled” and “publish clicked” as the same action. Final publish actions require explicit confirmation.

## Output

Report:

- page or flow inspected
- actions performed
- browser evidence collected
- landed URL and page title when a concrete page was inspected
- content source, especially whether it came from original-page browser evidence or a fallback source
- extracted structured content fields when the task is content acquisition
- when the task is frontend debugging, say whether the strongest signal came from DOM, styles, console, or network
- mention any selector scope or network filter used during the investigation
- confirmed observations
- unresolved questions
- next best step
- whether browser health/reset steps were needed
