---
name: qa
description: Run a structured quality pass using the strongest available evidence path, from tests and logs to browser-driven checks when host capabilities allow it.
---

# QA

Use this skill when the user wants validation beyond code review, especially for user-facing flows, regressions, staging checks, or pre-ship confidence.

## Read First

- `.planning/REQUIREMENTS.md` if it exists
- `.planning/STATE.md` if it exists
- `.planning/CONVENTIONS.md` if it exists
- `protocols/verify.md`
- project docs for local run, test, and preview commands
- `references/qa-tiers.md` when you need a clearer depth choice
- `references/runtime-hygiene.md` when startup or toolchain quality may be part of the QA surface

## Goals

- validate the most important user flows
- find observable failures or weak spots
- separate confirmed issues from suspicion
- produce a clear report the user can act on
- detect host, toolchain, and startup-path noise that could mislead later work
- keep CI-capable checks separate from host-runtime-only checks so confidence is not overstated

Choose the smallest tier that gives useful confidence.

Read `references/qa-tiers.md` when you need a more explicit quick/standard/exhaustive split.

## Browser Guidance

If the host and project support browser automation, use it for UI validation.

- Claude Code: use the configured browser tools or project browser workflow
- Codex: use available MCP/browser tooling if configured

If browser automation is not available, fall back to:

- test commands
- screenshots
- local previews
- static inspection with honest reporting about limitations

If the task depends on real host tools such as `codex`, `claude`, browser login state, or local desktop integration:

- do not treat hosted CI as equivalent evidence
- report that the check requires local smoke or a prepared self-hosted runner

## Runtime Hygiene

Include lightweight runtime hygiene checks when they are relevant to the task:

- shell initialization or PATH issues
- package manager and toolchain warnings
- default run entrypoints
- desktop or service startup noise
- config or asset issues that break local development before product logic is exercised

## Report Format

Produce:

- scope tested
- environment used
- checks performed
- issues found
- issues not reproduced
- gaps or limits
- evidence tier used for each major check when confidence depends on the environment

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

Use Chinese for user-facing QA summaries, issue descriptions, and confidence notes by default, while preserving commands, paths, and tool names in English.
