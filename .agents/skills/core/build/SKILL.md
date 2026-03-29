---
name: build
description: Implement the current task or phase using the shared engineering protocols and project state files.
---

# Build

Use this skill when the project has a current task ready for execution.

## Read First

- `harness/state.md`
- `harness/history.md` if it exists
- `docs/overview/roadmap.md`
- `docs/reference/conventions.md` if it exists
- relevant code and tests
- `protocols/tdd.md`
- project-local rules from `AGENTS.md` and nearby skill files
- `references/environment-preflight.md` when tools, runtimes, or entrypoints may be unstable
- `references/execution-guardrails.md` when scope, state writeback, or temporary unblock work may drift
- `references/pyramid-doc-writing.md` when producing or revising a proposal, design doc, architecture note, or module design

## Goals

- implement the current task with minimal scope
- preserve alignment with roadmap and requirements
- verify the changed behavior before moving on
- detect when execution should pause so planning can be refreshed instead of silently drifting
- avoid bypassing `debug` or `tdd-execution` when the work really depends on diagnosis or provable behavior change
- avoid continuing implementation when the user's real need has shifted to `review`, `verify`, or `qa`
- keep proposal and design documents at the intended depth instead of drifting into mixed-layer output

## Rules

- prefer test-first changes when practical
- keep edits narrow
- do not silently expand scope
- use `references/execution-guardrails.md` for explicit backtrack triggers, incidental issue classification, and high-risk boundary matrices
- update planning state when a task meaningfully advances
- run a quick environment preflight before assuming required tools are missing
- distinguish tool absence from shell initialization issues such as missing `fnm`, `nvm`, `asdf`, or `mise` activation
- treat runtime entrypoints, default binaries, and dev commands as part of the implementation surface
- when changing script paths, directory layout, or default entrypoints, update docs, tests, and CI references in the same change instead of leaving transitional paths behind
- avoid solving workflow drift by adding one-off maintenance docs when the real fix belongs in skills, planning files, or stable architecture docs
- if the work is a validation sample, keep the scope aligned to validation instead of silently drifting into product expansion
- on new scaffolds or unstable environments, run the smallest real build/check path early before broad implementation
- when writing user-reviewable docs or decision records, prefer Chinese unless the project overrides that rule
- when adding or editing user-facing script messages, prompts, or validation summaries, default them to Chinese unless an external interface requires English
- when a project uses super-stack default commit rules, use Angular commit structure with Chinese summaries
- when producing a user-reviewable proposal or design document, use pyramid structure as the default starting point unless the task has a stronger domain-specific required shape
- default proposal-style output to `standard` unless the user clearly asks for `brief` or `deep`
- keep the main document decision-oriented; move implementation-heavy detail to appendix or implementation notes when possible
- avoid letting a single proposal document silently become a mixed review doc, design doc, and implementation manual
- if a document starts carrying decision, design, and implementation layers together, prefer splitting or regrouping before continuing to expand it in place
- when a bounded build slice reaches a real rollback-safe checkpoint, prefer ending the turn with commit-readiness made explicit instead of silently carrying more unrelated work in the same uncommitted diff

## Steps

1. Identify the current task from state or roadmap.
2. Run a quick preflight for the required tools and entrypoints.
3. Use `references/execution-guardrails.md` to confirm scope, classify incidental issues, and decide whether the work should backtrack to `debug`, `tdd-execution`, `review`, `verify`, or `qa`.
4. When writing a proposal or design document, use `references/pyramid-doc-writing.md` to confirm depth mode and main-doc versus appendix boundaries.
5. Inspect the relevant code paths and downstream surfaces that must stay aligned.
6. Implement the smallest sufficient change.
7. Run relevant verification, including the nearest real runtime path when practical.
8. Update `harness/state.md` with current progress, blockers, environment findings, temporary-versus-final decisions, and related task-pack notes when harness artifacts are in use.
9. When the build materially changes repository workflow, runtime behavior, validation posture, or future maintenance direction, append a concise entry to `harness/history.md` if it exists.
10. If the slice is at a meaningful checkpoint, state whether it is commit-ready now or what is still blocking a clean checkpoint.

## Output

Tell the user:

- what task was implemented
- what environment or toolchain assumptions were verified
- how incidental issues were classified: `current must-fix`, `same-batch can-include`, or `follow-up`
- whether any explicit backtrack to `plan`, `discuss`, `debug`, `tdd-execution`, `review`, `verify`, or `qa` was required
- what document depth and structure were used when the task produced a proposal or design document, when relevant
- what was verified
- whether the current slice is at a rollback-safe commit checkpoint
- whether the next step is another `build`, `review`, `verify`, `qa`, or `ship`
