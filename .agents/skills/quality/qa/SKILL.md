---
name: qa
description: Run a structured quality pass using the strongest available evidence path, from tests and logs to browser-driven checks when host capabilities allow it.
---

# QA

Use this skill when the user wants validation beyond code review, especially for user-facing flows, regressions, staging checks, or pre-ship confidence.

Prefer this skill when confidence depends on runtime interaction, smoke paths, browser checks, staging behavior, or other user-visible flows.
Do not use this skill as the default path for diff audit or narrow completion proof:

- use `review` when the user mainly wants findings on an existing change
- use `verify` when the main question is whether a requested result is complete and a narrower proof path exists

## Read First

- `docs/reference/requirements.md` if it exists
- `harness/state.md` if it exists
- `harness/history.md` if it exists
- `docs/reference/conventions.md` if it exists
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

## Rules

- choose the smallest QA tier that gives meaningful confidence
- prefer runtime evidence over static speculation when the question is user-visible behavior
- keep environment/setup issues separate from confirmed product issues
- if the task can be fully answered by narrow completion evidence, route back to `verify`
- if the task is really about code/diff risk rather than runtime validation, route back to `review`

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
- distinguish missing binaries from shells that failed to load version managers such as `fnm`, `nvm`, `asdf`, or `mise`

## Report Format

Produce:

- scope tested
- environment used
- checks performed
- issues found
- issues not reproduced
- gaps or limits
- evidence tier used for each major check when confidence depends on the environment
- environment-boundary notes when CI, local smoke, or real host-runtime evidence cannot be treated as equivalent

For each issue include:

- severity
- reproduction summary
- likely affected flow
- confidence level

## State Updates

If `harness/state.md` exists, update current focus or add a decision note when QA changes release confidence, reveals a new blocker, or proves that a supposed product issue is actually a runtime/setup issue.

If QA materially changes repository-level confidence, release posture, or operating guidance, append a concise entry to `harness/history.md`.

## Output

End with one of:

- `QA status: pass`
- `QA status: pass with concerns`
- `QA status: fail`

Include the best next step: fix issues, `verify`, or `ship`.

Use Chinese for user-facing QA summaries, issue descriptions, and confidence notes by default, while preserving commands, paths, and tool names in English.
