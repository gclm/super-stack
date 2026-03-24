---
name: map-codebase
description: Inspect an existing project and produce a structured codebase map covering stack, architecture, conventions, integrations, testing, and risks.
---

# Map Codebase

Use this skill when entering a brownfield project, inheriting an unfamiliar repository, or preparing to plan work against an existing codebase.

## Read First

- root `AGENTS.md`
- nearby docs such as `README*`, `docs/`, architecture notes, and config files
- `.planning/CONVENTIONS.md` if it exists
- `templates/planning/codebase/` for output structure
- `references/runtime-footprint.md` when important evidence may live outside the repository

## Goals

- build a trustworthy map of how the project works
- record evidence, not guesses
- identify stack, architecture, boundaries, and risky areas
- prepare material that later skills can use without re-exploring everything

## Output Location

Write findings under `.planning/codebase/` in the target project, using these files:

- `STACK.md`
- `STRUCTURE.md`
- `ARCHITECTURE.md`
- `CONVENTIONS.md`
- `INTEGRATIONS.md`
- `TESTING.md`
- `CONCERNS.md`
- `SUMMARY.md`

If `.planning/` does not exist, initialize it first from `templates/planning/`.

## Investigation Order

1. Entry docs and top-level manifests
2. Build and runtime config
3. Source tree layout
4. Test layout and commands
5. External integrations
6. Host-runtime footprint outside the repo when relevant
7. Hotspots, risks, and unclear areas

## Evidence Rules

- cite actual files, directories, commands, and symbols
- distinguish confirmed facts from inference
- prefer short concrete notes over long prose
- if something is unknown, say it is unknown
- distinguish repository evidence from host-runtime evidence such as local config, logs, launch agents, or running processes

## File Expectations

### `STACK.md`

Capture:

- languages
- frameworks
- package managers
- test tools
- deployment/runtime clues

### `STRUCTURE.md`

Capture:

- top-level directories
- where product code lives
- where tests live
- where infra or tooling lives

### `ARCHITECTURE.md`

Capture:

- major modules or services
- request or data flow
- persistence boundaries
- background jobs, workers, or queues

### `CONVENTIONS.md`

Capture:

- naming conventions
- file organization patterns
- code style habits
- branching or release conventions if visible
- documentation language and commit conventions if visible

### `INTEGRATIONS.md`

Capture:

- third-party APIs
- auth providers
- databases or caches
- webhooks, messaging, analytics, storage

### `TESTING.md`

Capture:

- test frameworks
- test directories
- common test commands
- obvious coverage gaps

### `CONCERNS.md`

Capture:

- fragile areas
- risky dependencies
- stale or confusing sections
- missing docs or verification weak spots

### `SUMMARY.md`

Capture:

- one-paragraph summary
- likely best entry points for future work
- questions to resolve before major changes

## State Updates

If `.planning/STATE.md` exists, update it with:

- status: mapped
- current focus: codebase map completed
- decision entry summarizing the repository scan

## Output

Tell the user:

- what was mapped
- the main architectural shape
- the top concerns
- the best next step, usually `brainstorm` or `plan`
