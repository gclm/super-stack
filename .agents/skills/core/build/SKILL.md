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
- when implementation uncovers adjacent issues, classify them before editing:
  - `current must-fix`
  - `same-batch can-include`
  - `follow-up`
- do not fix adjacent issues in the same batch until they are classified against the active task
- if the work is a bug, failing test, flaky behavior, incorrect output, or unexplained runtime issue and the root cause is still unconfirmed, explicitly backtrack to `debug`
- if the work is a behavior change or bugfix with a practical automated test path, explicitly backtrack to `tdd-execution` unless RED is clearly impractical
- if the user mainly wants risk findings, merge readiness, or an audit of existing work, explicitly backtrack to `review`
- if implementation already exists and the remaining question is whether the requested outcome is actually complete, explicitly backtrack to `verify`
- if the main task is user-facing validation, smoke confidence, staging validation, or runtime flow checking, explicitly backtrack to `qa`
- for API, auth, tenant, admin, callback, webhook, upload, or download tasks, confirm the boundary matrix before broad edits:
  - who can call
  - which workspace or tenant the resource belongs to
  - what fields can be created or mutated
  - what response data must be hidden or sanitized
  - what external or script-based verification path exists
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

## Steps

1. Identify the current task from state or roadmap.
2. Run a quick preflight for the tools and entrypoints this task depends on.
3. Use `references/execution-guardrails.md` to confirm the task still matches the current scope, to classify any temporary unblock work, to classify incidental findings, and to decide whether the work should really be routed through `debug`, `tdd-execution`, `review`, `verify`, or `qa` first.
4. When writing a proposal or design document, use `references/pyramid-doc-writing.md` to confirm the selected depth mode, the default section structure, the main-doc versus appendix boundary, and any relevant drift signals before finalizing the draft.
5. For API, auth, tenant, admin, upload, download, callback, or webhook changes, write down the boundary matrix before editing.
6. Inspect the relevant code paths.
7. Identify downstream surfaces that must stay aligned, especially README, architecture docs, test entrypoints, CI paths, SDK callers, and planning state.
8. Implement the smallest sufficient change.
9. Run relevant verification, including the nearest real runtime path when practical.
10. Update `.planning/STATE.md` with progress, blockers, environment findings, and any temporary-versus-final decisions.

## Output

Tell the user:

- what task was implemented
- what environment or toolchain assumptions were verified
- how incidental issues were classified: `current must-fix`, `same-batch can-include`, or `follow-up`
- whether any explicit backtrack to `plan`, `discuss`, `debug`, `tdd-execution`, `review`, `verify`, or `qa` was required
- what document depth and structure were used when the task produced a proposal or design document, when relevant
- what was verified
- whether the next step is another `build`, `review`, `verify`, `qa`, or `ship`
