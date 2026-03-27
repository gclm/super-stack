# Codex Adapter

This file supplements the root `AGENTS.md` for Codex-specific behavior.

## Source of Truth

Shared workflow truth lives in:

- root `AGENTS.md`
- `.planning/`
- `protocols/`
- `.agents/skills/`

Use this file only for Codex-specific execution details.
Do not duplicate shared routing, stage definitions, language defaults, or quality boundaries here unless Codex needs an explicit host-side override.

## Codex Operating Model

For Codex, do not assume that a visible project-local `SKILL.md` will automatically inject its full instructions.

Default behavior:

1. Follow the workflow and routing rules from root `AGENTS.md`.
2. Treat `.agents/skills/*/SKILL.md` as detailed manuals for a stage, not as the only source of behavior.
3. When a task clearly maps to a workflow stage, you may read the corresponding skill file for more detail.
4. Preserve project state in `.planning/` just like Claude Code.
5. Use `.codex/config.toml` and `.codex/agents/*.toml` for stable Codex-specific behavior.

In practice, this means Codex should behave as if `AGENTS.md` is the router and `.agents/skills/` is the manual.

When shared workflow rules change, update root `AGENTS.md` first.
Only update this adapter when the change is truly Codex-specific.

## Codex Stage Procedure

For every non-trivial request:

1. Name the current stage internally before acting.
2. Check whether `.planning/` prerequisites exist for that stage.
3. If prerequisites are missing, explicitly route backward to the stage that should happen first.
4. Use `.agents/skills/` for details only after the stage has been chosen.
5. Prefer updating `STATE.md` over keeping transient plan state only in conversation.

Treat this as a fixed procedure, not a suggestion.

## Codex Backtracking Rules

Use the backtracking rules from root `AGENTS.md`.
State the backtrack in plain language so the user can follow the workflow change.

## Codex Browser Escalation

For Codex, prefer `browse` early when a request includes a concrete URL and the answer depends on the page's real content.

Use this heuristic:

- if the user links a webpage, article, post, document, or authenticated product page and asks to analyze, summarize, inspect, or verify what is on that page, prefer `browse`
- if `super-stack-browser` is available, do not stop at `curl`, `requests`, raw HTML, search snippets, or mirror pages before attempting original-page browser evidence
- if browser evidence still cannot be obtained, say that explicitly before continuing with fallback sources

Treat this as a browse-first heuristic for URL-content analysis, not a suggestion to browse every casual link mention.

## Codex Role Escalation

Use role files in `.codex/agents/` to support a stage, not replace the stage router from root `AGENTS.md`:

- `super_stack_explorer` for read-only repository or evidence investigation
- `super_stack_planner` for decomposition and sequencing
- `super_stack_reviewer` for findings-first risk review

Recommended triggers:

- stage blocked by repository uncertainty -> `super_stack_explorer`
- stage blocked by planning ambiguity -> `super_stack_planner`
- stage near merge or risky change set -> `super_stack_reviewer`

Important:

- `.codex/config.toml` enabling `multi_agent = true` means the host can support multi-agent orchestration, not that Codex must auto-delegate on every suitable task.
- role escalation is still conditional on host policy, current session permissions, and an explicit decision that delegation will help more than local execution.
- if a conversation never explicitly authorizes delegation in a host that requires that signal, multi-agent may remain unused even when config and role files are correct.
- prefer staying local when the next critical-path step is blocked on the exact result you would delegate.
- when the host/session allows it, Codex may auto-escalate to multi-agent based on task shape, but only after checking the conditions below instead of delegating by default.

Use sub-agents only when:

- the work can run in parallel without overlapping writes
- the subtask is concrete and bounded
- the main thread can keep making progress while the helper runs
- the coordination cost is lower than the expected speed or quality gain

Auto-escalation heuristic:

- if the host/session allows delegation and the task naturally splits into independent sidecar work, Codex should prefer using the matching helper instead of staying fully local
- if the very next critical-path action depends on the delegated result, stay local unless a helper can finish in parallel without blocking the main thread
- if write ownership is unclear or likely to overlap, stay local or delegate read-only exploration only

Read `.codex/references/multi-agent-escalation-examples.md` when a concrete example will help decide whether to delegate.

## Codex File Discipline

For Codex, prefer these durable artifacts:

- use `.planning/PROJECT.md`, `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/STATE.md` for stage memory
- use `.planning/codebase/*` when `map-codebase` is active
- use root `AGENTS.md` and `.codex/AGENTS.md` as the workflow contract
- use `.agents/skills/*/SKILL.md` as optional stage manuals

Do not let important stage state live only in transient conversation if a file is available for it.

## What Counts As Success

Codex is correctly adapted when:

- root `AGENTS.md` defines the primary workflow
- `.codex/config.toml` provides stable runtime policy
- `.codex/agents/*.toml` provides stable role behavior
- `.agents/skills/` adds deeper stage-specific instructions without being the sole dependency

That is the target model for this repository.
