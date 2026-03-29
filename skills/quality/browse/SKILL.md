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
- `harness/state.md` if it exists
- `harness/history.md` if it exists
- `references/browser-evidence-patterns.md` when you need a more concrete evidence checklist
- `references/content-acquisition-patterns.md` when the task is really about acquiring article or post content from a live page
- `references/frontend-debug-playbooks.md` when the task is a recurring frontend bug pattern such as white screen, API failure, layout regression, or auth loop
- `references/session-guardrails.md` when host selection, fallback order, or browser session lifecycle matters

## Goals

- confirm browser-visible behavior with direct evidence
- inspect runtime state that code reading cannot prove
- distinguish DOM, style, console, and network failures
- leave behind a clear summary of what was actually observed
- establish `browse` as the base capability for browser-driven verification and content acquisition

## Strong Triggers

Default to `browse` when any of the following is true:

- the user provides a concrete URL and asks to analyze the page content
- the user asks to inspect a webpage, article, post, or document page they linked directly
- the page is likely to be login-gated, verification-gated, dynamic, or socially rendered, such as WeChat articles, Xiaohongshu posts, Douyin pages, or similar surfaces
- the answer depends on the original page title, author, body text, DOM, screenshot, console, or network behavior
- static fetches or search summaries may diverge from what the user actually sees in the browser
- the request is really about extracting or viewing article/post content from a live page, not just debugging UI behavior

When these conditions hold, do not begin with mirror pages, raw HTML fetching, or search snippets unless browser tooling is unavailable.

## Steps

1. Restate the exact browser-side question.
2. Confirm which browser tooling is actually available on the host.
   - Codex in this repo: prefer the configured browser MCP, currently `chrome-devtools-mcp` when present.
   - Claude Code: prefer configured browser MCP or browser plugin.
   - If availability is unclear and the managed runtime is installed, use `~/.super-stack/runtime/scripts/check/check-browser-capability.sh` as a quick capability probe.
3. Open the relevant page or flow with the active browser tooling.
4. Reproduce the target interaction.
5. For page or article analysis, collect the smallest original-page evidence set first:
   - landed URL
   - page title
   - the main rendered content container when available
   - `document.body.innerText` only as a fallback when no better content container is obvious
   - platform-specific structured fields such as author, publish time, summary, comments, and image URLs when the page visibly exposes them
6. Collect only the extra evidence needed:
   - DOM
   - styles
   - console
   - network
   - screenshot
7. Tie the observation back to the claimed bug or acceptance criterion.
8. If browser tooling becomes unhealthy or loses context, prefer opening a fresh page/tab or restarting the host-side browser tooling cleanly instead of inventing repo-local wrapper recovery steps.
9. If browser evidence cannot be obtained, say why before falling back.
10. Report what was confirmed, what was not reproduced, and any tooling limits.

For frontend bug triage, prefer a structure-first investigation:

1. reproduce the symptom
2. capture snapshot evidence
3. inspect styles when structure looks suspicious
4. inspect console and page errors
5. inspect network requests
6. only then escalate to broader screenshots or flow-level QA

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
- whether browser tooling had to be restarted or re-opened during the run
