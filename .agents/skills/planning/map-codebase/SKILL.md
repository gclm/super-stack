---
name: map-codebase
description: Inspect an existing project and produce a structured codebase map covering stack, architecture, conventions, integrations, testing, and risks.
---

# Map Codebase

Use this skill when entering a brownfield project, inheriting an unfamiliar repository, or preparing to plan work against an existing codebase.

## Read First

- root `AGENTS.md`
- nearby docs such as `README*`, `docs/`, architecture notes, and config files
- `docs/reference/conventions.md` if it exists
- `harness/state.md` if it exists
- `harness/history.md` if it exists
- `references/layered-entry.md`
- `references/output-shape.md`
- `references/runtime-footprint.md` when important evidence may live outside the repository
- `~/.agents/skills/using-contextweaver/SKILL.md` when `ContextWeaver` is available

## Context Retrieval

When `ContextWeaver` is available in the environment, use it as the primary evidence accelerator, not as a replacement for architectural judgment.

- first check whether `contextweaver` (or `cw`) is available
- if available, verify index scope before scanning deeply
- use `search --format json` and `prompt-context --format json` to collect candidate files and symbols
- prefer official distributed scripts from `contextweaver install-skills` when stable structured output is needed
- follow the decision rules in `~/.agents/skills/using-contextweaver/SKILL.md` to choose `read` vs `grep` vs semantic retrieval
- then confirm critical claims by opening repository files directly
- if unavailable, continue with normal repository-first scanning

## Goals

- build a trustworthy map of how the project works
- record evidence, not guesses
- identify stack, architecture, boundaries, and risky areas
- prepare material that later skills can use without re-exploring everything
- surface mismatches between documented structure and actual repository structure

## Multi-Module Guard

If the baseline scan shows this is a multi-module or multi-app repository, do not assume the user wants a full-repository map unless they clearly asked for that.

Use this rule:

- if the user already names the target module, service, app, or flow, continue with that boundary
- if the repository is clearly multi-module and the target is still ambiguous, pause and ask one short question to confirm which module or scope they want mapped first
- only do a broad full-repository map without confirmation when the user explicitly asks for the whole repository or when the module boundary truly cannot be separated safely

The confirmation should be short and concrete, for example:

- `这个仓库看起来是多模块的，你这次想先聚焦哪个模块？`

## Investigation Order

Use a layered entry strategy:

1. Baseline layer
2. Design layer
3. Target layer

Within those layers, investigate in this order:

1. Entry docs and top-level manifests
2. Build and runtime config
3. Source tree layout
4. Test layout and commands
5. Compare docs, scripts, and CI entrypoints against the real repository layout
6. External integrations
7. Host-runtime footprint outside the repo when relevant
8. User-targeted deepening only after the baseline and nearby design are stable
9. Hotspots, risks, and unclear areas

When the user already points to a module or objective, do not treat that as permission to skip the baseline layer.
When the repository is multi-module, keep the baseline layer narrow and only wide enough to identify the module boundary before deepening.
When the baseline is already clear, do not keep broadening the scan beyond the target layer.

## Evidence Rules

- cite actual files, directories, commands, and symbols
- distinguish confirmed facts from inference
- prefer short concrete notes over long prose
- if something is unknown, say it is unknown
- distinguish repository evidence from host-runtime evidence such as local config, logs, launch agents, or running processes
- when docs or planning files disagree with the repository, record that drift explicitly instead of smoothing it over

## State Updates

If `harness/state.md` exists, update it with:

- status: mapped
- current focus: codebase map completed
- decision entry summarizing the repository scan

If the mapping reveals durable repository-level drift, structural mismatch, or workflow implications worth preserving, append a concise entry to `harness/history.md`.

## Output

Tell the user:

- what was mapped
- the main architectural shape
- the top concerns
- the best next step, usually `brainstorm` or `plan`

Choose output depth using `references/output-shape.md`:

- default to `minimal` output (`summary.md` + `concerns.md`)
- use `full` output only when repository-level onboarding or handoff needs a full map pack
