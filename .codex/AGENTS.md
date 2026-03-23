# Codex Adapter

This file supplements the root `AGENTS.md` for Codex-specific behavior.

## Source of Truth

Prefer the shared core:

- root `AGENTS.md`
- `.planning/`
- `protocols/`
- `.agents/skills/`

Use this file to make Codex behavior explicit when automatic skill execution is weak or host-dependent.

## Codex Operating Model

For Codex, do not assume that a visible project-local `SKILL.md` will automatically inject its full instructions.

Default behavior:

1. Follow the workflow and routing rules from root `AGENTS.md`.
2. Treat `.agents/skills/*/SKILL.md` as detailed manuals for a stage, not as the only source of behavior.
3. When a task clearly maps to a workflow stage, you may read the corresponding skill file for more detail.
4. Preserve project state in `.planning/` just like Claude Code.
5. Use `.codex/config.toml` and `.codex/agents/*.toml` for stable Codex-specific behavior.

In practice, this means Codex should behave as if `AGENTS.md` is the router and `.agents/skills/` is the manual.

## Workflow Routing For Codex

Use these stages explicitly:

- `discuss` for fuzzy requests and scope clarification
- `brainstorm` for solution comparison
- `map-codebase` for brownfield onboarding
- `plan` for phased task planning
- `build` for implementation
- `review` for findings-first code review
- `verify` for evidence collection
- `qa` for user-flow validation
- `ship` for release-readiness and handoff

When the user names one of these stages or when the task obviously matches one, read the corresponding file under `.agents/skills/` if you need detailed steps.

## Codex Stage Procedure

For every non-trivial request:

1. Name the current stage internally before acting.
2. Check whether `.planning/` prerequisites exist for that stage.
3. If prerequisites are missing, explicitly route backward to the stage that should happen first.
4. Use `.agents/skills/` for details only after the stage has been chosen.
5. Prefer updating `STATE.md` over keeping transient plan state only in conversation.

Treat this as a fixed procedure, not a suggestion.

## Codex Stage Checks

Before acting in a stage, perform the corresponding check:

- `discuss`
  - ask: do I understand outcome, scope, constraints, and success signal?
- `brainstorm`
  - ask: is there a real decision with trade-offs, not just missing implementation?
- `map-codebase`
  - ask: would implementation be risky without understanding current structure?
- `plan`
  - ask: do I have enough clarity to break work into bounded tasks?
- `build`
  - ask: do I know what to change, where to change it, and how to verify it?
- `review`
  - ask: is there a concrete diff or implemented behavior to inspect?
- `verify`
  - ask: can I produce current evidence for the requested outcome?
- `qa`
  - ask: is there a flow or user-visible surface worth validating?
- `ship`
  - ask: is the remaining work about readiness, not implementation?

If the answer is no, route to the earlier stage that fixes the gap.

Example routes:

- vague feature request -> `discuss`, then `plan`
- "which approach is better?" -> `brainstorm`, then `plan`
- unfamiliar codebase + requested change -> `map-codebase`, then `plan` or `build`
- "please implement task X" with enough context -> `build`
- "review this branch" -> `review`
- "make sure this is actually done" -> `verify`
- "check the UI / test the flow" -> `qa`
- "prepare to merge / release" -> `ship`

## Codex Backtracking Rules

Codex should backtrack explicitly when:

- `build` reveals missing acceptance criteria -> go to `discuss`
- `build` reveals task breakdown ambiguity -> go to `plan`
- `review` finds defects -> go to `build`
- `verify` fails to confirm outcome -> go to `build`
- `qa` confirms defects -> go to `build`
- `ship` lacks evidence -> go to `verify` or `qa`

State the backtrack in plain language so the user can follow the workflow change.

## Codex Role Escalation

Use role files in `.codex/agents/` to support a stage, not replace the stage router:

- `super_stack_explorer` for read-only repository or evidence investigation
- `super_stack_planner` for decomposition and sequencing
- `super_stack_reviewer` for findings-first risk review

Recommended triggers:

- stage blocked by repository uncertainty -> `super_stack_explorer`
- stage blocked by planning ambiguity -> `super_stack_planner`
- stage near merge or risky change set -> `super_stack_reviewer`

## Codex File Discipline

For Codex, prefer these durable artifacts:

- use `.planning/PROJECT.md`, `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/STATE.md` for stage memory
- use `.planning/codebase/*` when `map-codebase` is active
- use root `AGENTS.md` and `.codex/AGENTS.md` as the workflow contract
- use `.agents/skills/*/SKILL.md` as optional stage manuals

Do not let important stage state live only in transient conversation if a file is available for it.

## Codex Reliability Rules

- Do not claim a skill was fully applied unless you actually read its `SKILL.md` or the host clearly confirms automatic execution.
- If you are following a stage from `AGENTS.md` without opening the matching skill file, say you are following the stage router and not relying on automatic skill injection.
- When asked why you chose a workflow, reference the stage routing in root `AGENTS.md`.
- If a request is simple and you do not need the manual, it is fine to execute directly from the router.
- If a request is complex and you need richer procedure, read the matching `SKILL.md` explicitly before continuing.

## Default Roles

- `super_stack_explorer` for read-only evidence gathering
- `super_stack_reviewer` for correctness and risk review
- `super_stack_planner` for structured breakdown and sequencing

## What Counts As Success

Codex is correctly adapted when:

- root `AGENTS.md` defines the primary workflow
- `.codex/config.toml` provides stable runtime policy
- `.codex/agents/*.toml` provides stable role behavior
- `.agents/skills/` adds deeper stage-specific instructions without being the sole dependency

That is the target model for this repository.
