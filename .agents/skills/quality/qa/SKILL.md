---
name: qa
description: Run a structured quality pass using the strongest available evidence path, from tests and logs to browser-driven checks when host capabilities allow it.
---

# QA

Use this skill when the user wants validation beyond code review, especially for user-facing flows, regressions, staging checks, or pre-ship confidence.

## Read First

- `.planning/REQUIREMENTS.md` if it exists
- `.planning/STATE.md` if it exists
- `protocols/verify.md`
- project docs for local run, test, and preview commands

## Goals

- validate the most important user flows
- find observable failures or weak spots
- separate confirmed issues from suspicion
- produce a clear report the user can act on

## QA Tiers

Choose the smallest tier that gives useful confidence.

### Quick

Use when the change is narrow.

- run targeted tests
- inspect relevant logs or screenshots
- check the changed flow only

### Standard

Use for most feature work.

- run targeted tests
- run the nearest broader verification command
- validate the primary user path
- inspect one or two important edge cases

### Exhaustive

Use before a risky ship or after bug-heavy work.

- run broad verification
- test primary and secondary flows
- validate edge cases and failure paths
- inspect logs, browser behavior, and regression surfaces

## Browser Guidance

If the host and project support browser automation, use it for UI validation.

- Claude Code: use the configured browser tools or project browser workflow
- Codex: use available MCP/browser tooling if configured

If browser automation is not available, fall back to:

- test commands
- screenshots
- local previews
- static inspection with honest reporting about limitations

## Report Format

Produce:

- scope tested
- environment used
- checks performed
- issues found
- issues not reproduced
- gaps or limits

For each issue include:

- severity
- reproduction summary
- likely affected flow
- confidence level

## State Updates

If `.planning/STATE.md` exists, update current focus or add a decision note when QA changes release confidence.

## Output

End with one of:

- `QA status: pass`
- `QA status: pass with concerns`
- `QA status: fail`

Include the best next step: fix issues, `verify`, or `ship`.
