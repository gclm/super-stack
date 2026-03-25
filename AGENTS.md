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
- `skill-maintenance` for creating, refactoring, or tightening repository skills and their references
- `release-check` for final release-readiness checks
- `frontend-refactor` for larger UI and interaction cleanup
- `frontend-design` for new UI direction, visual language, and anti-generic frontend execution
- `bugfix-verification` for proving a fix really closes the reported bug
- `api-change-check` for contract drift and compatibility review
- `database-design` for schema, constraint, and index design
- `api-design` for contract and caller ergonomics
- `architecture-design` for larger structural decisions
- `codex-record-retrospective` for reviewing Codex local records tied to a project path and feeding reusable lessons back into super-stack
- `migration-design` for phased schema and data rollout planning
- `query-optimization` for evidence-based query and index tuning
- `backend-refactor` for structural backend cleanup without behavior drift
- `integration-design` for service and vendor boundary design
- `service-boundary-review` for responsibility and dependency boundary review
- `scalability-check` for load, growth, and concurrency risk review
- `observability-design` for logs, metrics, traces, and alerting design
- `incident-debug` for production-style incident triage and mitigation
- `security-review` for trust-boundary and abuse-path review
- `performance-investigation` for evidence-based bottleneck diagnosis
- `browse` for browser-side DOM, style, console, and network verification

## Default Execution Policy

When a request arrives, decide the current stage before taking action.

1. If the request is ambiguous or the desired outcome is underspecified, start at `discuss`.
2. If the request is a bug, failing test, flaky behavior, incorrect output, or unexplained runtime issue and the cause is not yet confirmed, start at `debug`.
3. If the request is a behavior change or bugfix with a practical automated test path, prefer `tdd-execution` before broad `build`.
4. If the user is comparing approaches or asking "what is the best way", start at `brainstorm`.
5. If the repository is unfamiliar or the task depends on understanding existing structure, start at `map-codebase`.
6. If scope is already clear but task breakdown is missing, start at `plan`.
7. If there is a current task with enough context to implement safely, go to `build`.
8. If the user asks for audit, PR review, merge readiness, bug/risk scan, regression review, or "帮我看看哪里有问题", go to `review`.
9. If implementation already exists and the remaining question is whether the requested outcome was actually achieved, go to `verify`.
10. If the task is user-facing validation, end-to-end confidence, staging checks, smoke validation, or release-candidate validation, go to `qa`.
11. If the work is complete and needs handoff, merge prep, or release summary, go to `ship`.

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
  - the main question is completion confidence, not broad risk discovery
- `qa`
  - there is a user-facing flow, system interaction, or release candidate to validate
  - the task needs runtime or flow-level confidence beyond static review
- `ship`
  - implementation is done and the remaining work is handoff, merge prep, or release readiness

Use supporting skills when the problem shape requires them:

- `debug`
  - a bug exists but the cause is not yet confirmed
- `tdd-execution`
  - a behavior change should be driven by automated tests
- `release-check`
  - readiness needs a stricter release gate than the normal `ship` summary
- `review`
  - the user primarily wants risks, regressions, missing tests, or merge blockers called out
- `verify`
  - implementation exists and the main need is evidence that the requested result is truly done
- `qa`
  - the user wants confidence in a real flow, staging candidate, smoke path, or user-visible behavior rather than a diff audit
- `frontend-refactor`
  - the work is a frontend cleanup or restructuring effort, not just a small UI tweak
- `frontend-design`
  - the task is creating or reshaping a frontend visual direction and the main risk is bland, generic, or inconsistent UI
  - before designing, identify whether the target is a marketing surface, product workbench, redesign slice, or clickable prototype
  - when redesigning an existing product, inspect real pages and user flows before choosing a layout direction
- `bugfix-verification`
  - a bugfix exists and needs focused proof that the symptom is truly closed
- `api-change-check`
  - the change may affect API contracts, callers, validation, or compatibility
- `database-design`
  - the task changes schema, indexes, query patterns, or persistence boundaries
- `api-design`
  - the task defines or changes an API contract before implementation hardens
- `architecture-design`
  - the task is really about system boundaries, module shape, or service structure
- `migration-design`
  - the task changes existing data shape and needs phased rollout, backfill, or rollback planning
- `query-optimization`
  - the problem is a slow query, poor index fit, or uncertain data access path
- `backend-refactor`
  - backend code needs structural cleanup across handlers, services, repositories, or side effects
- `integration-design`
  - the task introduces or reshapes a service, queue, webhook, or vendor integration boundary
- `service-boundary-review`
  - the question is whether modules or services are split across the right ownership boundaries
- `scalability-check`
  - the design may face throughput, concurrency, or growth limits that should be reviewed before shipping
- `observability-design`
  - the task needs better operational signals, dashboards, alerts, or debugging visibility
- `incident-debug`
  - the problem is an active production-like outage or degraded service that needs containment and diagnosis
- `security-review`
  - the change crosses auth, secret, data exposure, or external attack-surface boundaries
- `performance-investigation`
  - the problem is latency, throughput, memory, CPU, or rendering slowdown and the bottleneck is not yet confirmed
- `browse`
  - the task needs browser-side evidence such as DOM state, styles, console errors, network requests, or runtime UI behavior

If a stage precondition is not met, route backward explicitly instead of improvising.

## Shared State

Project memory lives under `.planning/` in the target project:

- `PROJECT.md` - project vision, scope, constraints
- `REQUIREMENTS.md` - numbered requirements and acceptance notes
- `ROADMAP.md` - phases, tasks, dependencies
- `STATE.md` - current status, active phase, blockers, decisions
- `CONVENTIONS.md` - language, commit, and project-specific engineering conventions

If the project does not yet have `.planning/`, initialize it from `templates/planning/`.
Version these planning files by default so workflow state survives across turns, hosts, and collaborators.
Only ignore host-generated or machine-local `.planning` artifacts such as hook logs.

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

When workflow defaults such as state continuity, commit conventions, language defaults, or shared operating guards matter, use `protocols/workflow-governance.md`.

## Documentation And Commit Conventions

See `protocols/workflow-governance.md` for documentation language defaults, state continuity defaults, and commit conventions.

If the project already has explicit commit rules, follow the project rule instead of this default.

## Reference Reuse Boundary

See `protocols/workflow-governance.md` for the default interpretation of reference reuse.

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
- Use `protocols/workflow-governance.md` when shared operating guards matter, especially for scope backtracking, environment interpretation, design artifact typing, and fork-aware redesign work.
- For reviews, prioritize correctness, regressions, security, and missing tests.
- Route to `review` when the user wants findings, not implementation.
- For debugging, follow the debug protocol instead of guessing.
- When the task is explicitly bug diagnosis, or when a failure exists but the root cause is not yet confirmed, route to `debug` before broad implementation.
- Route to `verify` when implementation already exists and the real question is whether the requested outcome is actually satisfied by fresh evidence.
- Route to `qa` when confidence depends on user-facing flow validation, runtime interaction, smoke checks, or release-candidate behavior.
- When a behavior change or bugfix has a practical automated test path, route to `tdd-execution` before ad hoc implementation unless you can clearly justify why RED is impractical.
- When release confidence is the real question, use `release-check` before optimistic handoff.
- If a later-stage request lacks prerequisites, state the missing prerequisite and route to the right earlier stage.
- Keep workflow transitions explicit in user-facing updates.
- When a task spans multiple stages in one turn, announce the transition briefly instead of blending them invisibly.
- Prefer preserving stage outputs in files when they are likely to matter beyond the current turn.

## Multi-Agent Guidance

Use parallel agents when tasks are independent and write scopes do not overlap.

Do not assume multi-agent work starts automatically just because a host has agent support enabled.
Treat multi-agent as an explicit escalation path that requires all of the following:

- the host/session actually allows sub-agent orchestration
- the task has independent sidecar work, not one tightly coupled critical path
- file ownership can stay disjoint or read-only
- the expected gain is real enough to justify coordination overhead

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
If multi-agent support exists in configuration but does not activate in practice, check host policy, current session permissions, and whether the request ever crossed the explicit escalation threshold above.

## Fallback And Backtracking Rules

Use these explicit backtracks:

- from `build` back to `plan`
  - when the task is larger than expected or file scope is unclear
  - when product entry shape, current-phase scope, architecture direction, database strategy, or reference-reuse boundary changed after coding began
- from `build` back to `debug`
  - when a bug, failing test, flaky behavior, or incorrect output is being discussed but the root cause is still unconfirmed
- from `build` back to `tdd-execution`
  - when the requested work is a behavior change or bugfix and a practical automated test path exists
- from `build` back to `discuss`
  - when the request itself is ambiguous or acceptance criteria are missing
- from `review` back to `build`
  - when findings require implementation changes
- from `build` back to `review`
  - when the user request is really an audit, risk scan, or merge-readiness check rather than implementation
- from `build` back to `verify`
  - when code already exists and the unresolved question is completion evidence
- from `build` back to `qa`
  - when the main work is validating a user flow, smoke path, staging candidate, or real runtime behavior
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
