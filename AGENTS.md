# Super Stack

Cross-host agent workflow for Claude Code and Codex.

This repository provides a shared core:

- `AGENTS.md` for cross-host operating guidance
- `.agents/skills/` for reusable workflows
- `templates/` for project memory and planning files
- `protocols/` for stable engineering rules
- host adapters under `.claude/` and `.codex/`

## Intent

Use one workflow core across multiple agent hosts without coupling the project to a single plugin system.

The design principle is:

1. Keep shared behavior in host-neutral files.
2. Keep host-specific wiring thin.
3. Prefer reusable skills over giant system prompts.
4. Persist project state in files, not only in conversation context.

## Core Workflow

The default delivery chain is:

`discuss -> plan -> build -> review -> verify -> ship`

Treat this chain as the primary operating model across hosts.

On hosts with strong native skill execution, the matching skill may be applied directly.
On hosts where skill execution is weaker or inconsistent, follow the workflow from this file first and use `.agents/skills/` as detailed reference material.

Supporting skills can be used within or between stages when appropriate:

- `debug` for bug diagnosis before fixing
- `tdd-execution` for RED -> GREEN -> REFACTOR execution
- `release-check` for final release-readiness checks

## Default Execution Policy

When a request arrives, decide the current stage before taking action.

1. If the request is ambiguous or the desired outcome is underspecified, start at `discuss`.
2. If the user is comparing approaches or asking "what is the best way", start at `brainstorm`.
3. If the repository is unfamiliar or the task depends on understanding existing structure, start at `map-codebase`.
4. If scope is already clear but task breakdown is missing, start at `plan`.
5. If there is a current task with enough context to implement safely, go to `build`.
6. If the user asks for audit, PR review, bug/risk identification, or pre-merge confidence, go to `review`.
7. If implementation is done and the question is "is this actually finished", go to `verify`.
8. If the task is user-facing validation or release-readiness validation, go to `qa`.
9. If the work is complete and needs handoff, merge prep, or release summary, go to `ship`.

Do not skip backward silently. If work reveals missing context, explicitly step back to the earlier stage that is needed.

## Stage Preconditions

Use these checks before entering a stage:

- `discuss`
  - no stable requirements exist yet, or the user outcome is still fuzzy
- `brainstorm`
  - there is a real decision to compare, not just an implementation task
- `map-codebase`
  - the task depends on understanding an unfamiliar existing codebase
- `plan`
  - requirements are clear enough to sequence into phases or tasks
- `build`
  - there is a sufficiently clear task, scope boundary, and target code area
- `review`
  - there is already a concrete diff, branch, or implemented behavior to audit
- `verify`
  - there is an outcome that can be checked with fresh evidence
- `qa`
  - there is a user-facing flow, system interaction, or release candidate to validate
- `ship`
  - implementation is done and the remaining work is handoff, merge prep, or release readiness

Use supporting skills when the problem shape requires them:

- `debug`
  - a bug exists but the cause is not yet confirmed
- `tdd-execution`
  - a behavior change should be driven by automated tests
- `release-check`
  - readiness needs a stricter release gate than the normal `ship` summary

If a stage precondition is not met, route backward explicitly instead of improvising.

## Shared State

Project memory lives under `.planning/` in the target project:

- `PROJECT.md` - project vision, scope, constraints
- `REQUIREMENTS.md` - numbered requirements and acceptance notes
- `ROADMAP.md` - phases, tasks, dependencies
- `STATE.md` - current status, active phase, blockers, decisions

If the project does not yet have `.planning/`, initialize it from `templates/planning/`.

## Stage State Rules

Each stage should update or consume state predictably:

- `discuss`
  - read: `PROJECT.md`, `REQUIREMENTS.md`, `STATE.md` if present
  - write: clarify `PROJECT.md`, `REQUIREMENTS.md`, `STATE.md`
- `brainstorm`
  - read: requirements, constraints, existing code context
  - write: decision notes into `STATE.md` and requirement/project notes when helpful
- `map-codebase`
  - read: local docs, manifests, source layout
  - write: `.planning/codebase/*` and `STATE.md`
- `plan`
  - read: `PROJECT.md`, `REQUIREMENTS.md`, `STATE.md`
  - write: `ROADMAP.md`, `STATE.md`
- `build`
  - read: `ROADMAP.md`, `STATE.md`, relevant code and tests
  - write: code changes and progress notes in `STATE.md`
- `review`
  - read: diff, tests, `ROADMAP.md` or request context
  - write: no planning file required unless review changes release confidence or reveals blockers
- `verify`
  - read: request outcome, requirements, tests, current state
  - write: update `STATE.md` if verification changes readiness or reveals gaps
- `qa`
  - read: requirements, current state, test/preview instructions
  - write: update `STATE.md` if QA changes confidence or identifies blockers
- `ship`
  - read: `STATE.md`, `ROADMAP.md`, diff, verification evidence
  - write: final readiness or release notes into `STATE.md` when useful

## Stage Exit Criteria

Treat a stage as complete only when its exit signal exists:

- `discuss`
  - the request can be expressed as concrete scope, constraints, and success criteria
- `brainstorm`
  - one option is recommended with clear trade-offs
- `map-codebase`
  - architecture, structure, testing, integrations, and concerns are captured with evidence
- `plan`
  - there is a roadmap or bounded task breakdown with clear next work
- `build`
  - the requested task change is implemented and relevant evidence exists
- `review`
  - findings are reported or the absence of findings is stated explicitly
- `verify`
  - the requested outcome is mapped to current evidence and gaps are reported
- `qa`
  - tested scope, issues, and remaining limits are reported
- `ship`
  - readiness status and remaining blockers are explicit

Do not claim a later stage is complete while its exit criteria are still missing.

## Operating Rules

- Read local code and docs before making architectural assumptions.
- Prefer evidence over memory when behavior can be verified quickly.
- Keep edits targeted and reversible.
- Do not claim completion without fresh verification evidence.
- For reviews, prioritize correctness, regressions, security, and missing tests.
- For debugging, follow the debug protocol instead of guessing.
- When the task is explicitly bug diagnosis, prefer the `debug` skill before broad implementation.
- When a behavior is testable, prefer `tdd-execution` over ad hoc implementation.
- When release confidence is the real question, use `release-check` before optimistic handoff.
- If a later-stage request lacks prerequisites, state the missing prerequisite and route to the right earlier stage.
- Keep workflow transitions explicit in user-facing updates.
- When a task spans multiple stages in one turn, announce the transition briefly instead of blending them invisibly.
- Prefer preserving stage outputs in files when they are likely to matter beyond the current turn.

## Multi-Agent Guidance

Use parallel agents when tasks are independent and write scopes do not overlap.

Recommended roles:

- `planner` - shape requirements or break work into tasks
- `explorer` - gather read-only evidence
- `reviewer` - inspect risks, regressions, and missing tests
- `builder` - implement bounded changes

For Codex, mirror these roles through `.codex/agents/*.toml`.
For Claude Code, keep equivalent role guidance in host instructions or skill text.

## Escalation To Supporting Roles

Bring in supporting roles when a stage needs deeper evidence:

- use `explorer` when codebase structure or runtime behavior is unclear
- use `planner` when implementation scope is too large or sequencing is fuzzy
- use `reviewer` when changes are risky, broad, or about to be merged

Do not delegate the primary user-facing workflow itself unless the host supports reliable multi-agent orchestration for that task.

## Fallback And Backtracking Rules

Use these explicit backtracks:

- from `build` back to `plan`
  - when the task is larger than expected or file scope is unclear
- from `build` back to `discuss`
  - when the request itself is ambiguous or acceptance criteria are missing
- from `review` back to `build`
  - when findings require implementation changes
- from `verify` back to `build`
  - when evidence shows the requested outcome is not met
- from `qa` back to `build`
  - when user-facing defects are confirmed
- from `ship` back to `verify` or `qa`
  - when release confidence is not yet supported by evidence

Always name the backtrack when it happens.

## Host Adapters

- Claude Code adapter: `.claude/`
- Codex adapter: `.codex/`

Adapters should reference this root file, not replace it.

## Host-Neutral Routing

Map common requests to the workflow explicitly:

- vague feature or request clarification -> `discuss`
- architecture or option comparison -> `brainstorm`
- understanding an existing codebase -> `map-codebase`
- turning approved scope into tasks -> `plan`
- implementation against a current task -> `build`
- code audit or merge-readiness check -> `review`
- evidence gathering before completion -> `verify`
- user-facing or end-to-end validation -> `qa`
- release or handoff preparation -> `ship`

If the host does not automatically execute `SKILL.md` files, treat the names above as workflow stages and read the relevant skill file manually when more detail is needed.

## Manual Skill Expansion

When running on a host where skills may not auto-expand:

1. choose the stage from the routing table above
2. state the chosen stage in your own reasoning and user update
3. read the corresponding `.agents/skills/.../SKILL.md` only when more procedural detail is needed
4. continue following `protocols/` and `.planning/` state rules

If the stage is clear and the work is straightforward, the router alone may be enough.
If the stage needs a richer checklist or output shape, expand the corresponding skill file manually.

## Skill Layout

- `core/` - request shaping and implementation entry points
- `planning/` - roadmap and state management
- `quality/` - review and verification
- `ship/` - release completion steps

## Protocol References

- `protocols/tdd.md`
- `protocols/review.md`
- `protocols/verify.md`
- `protocols/debug.md`

Skills should reference these files instead of duplicating large process descriptions.
