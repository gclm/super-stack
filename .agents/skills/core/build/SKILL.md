---
name: build
description: Implement the current task or phase using the shared engineering protocols and project state files.
---

# Build

Use this skill when the project has a current task ready for execution.

## Read First

- `.planning/STATE.md`
- `.planning/ROADMAP.md`
- `.planning/CONVENTIONS.md` if it exists
- relevant code and tests
- `protocols/tdd.md`
- project-local rules from `AGENTS.md` and nearby skill files
- `references/environment-preflight.md` when tools, runtimes, or entrypoints may be unstable

## Goals

- implement the current task with minimal scope
- preserve alignment with roadmap and requirements
- verify the changed behavior before moving on

## Rules

- prefer test-first changes when practical
- keep edits narrow
- do not silently expand scope
- update planning state when a task meaningfully advances
- run a quick environment preflight before assuming required tools are missing
- treat runtime entrypoints, default binaries, and dev commands as part of the implementation surface
- when changing script paths, directory layout, or default entrypoints, update docs, tests, and CI references in the same change instead of leaving transitional paths behind
- avoid solving workflow drift by adding one-off maintenance docs when the real fix belongs in skills, planning files, or stable architecture docs
- if the work is a validation sample, keep the scope aligned to validation instead of silently drifting into product expansion
- when writing user-reviewable docs or decision records, prefer Chinese unless the project overrides that rule
- when adding or editing user-facing script messages, prompts, or validation summaries, default them to Chinese unless an external interface requires English
- when a project uses super-stack default commit rules, use Angular commit structure with Chinese summaries

## Steps

1. Identify the current task from state or roadmap.
2. Run a quick preflight for the tools and entrypoints this task depends on.
3. Inspect the relevant code paths.
4. Identify downstream surfaces that must stay aligned, especially README, architecture docs, test entrypoints, CI paths, and planning state.
5. Implement the smallest sufficient change.
6. Run relevant verification, including the nearest real runtime path when practical.
7. Update `.planning/STATE.md` with progress, blockers, or environment findings.

## Output

Tell the user:

- what task was implemented
- what environment or toolchain assumptions were verified
- what was verified
- whether the next step is another `build`, `review`, or `verify`
