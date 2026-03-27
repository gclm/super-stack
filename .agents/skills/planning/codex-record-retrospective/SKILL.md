---
name: codex-record-retrospective
description: Review Codex local records for a specific project path, reconstruct what happened, and extract workflow or skill improvements worth feeding back into super-stack.
---

# Codex Record Retrospective

Use this skill when the user wants to review or 复盘某个项目里的 Codex 实战记录，并希望把经验反哺到 workflow、skills、prompts 或治理规则中。

Prefer this skill when:

- the user gives a concrete project path
- the user mentions Codex records, history, sessions, archived sessions, or local conversation traces
- the goal is not just to inspect the target codebase, but to inspect how Codex behaved while working in that codebase

If the project path is missing, ask the user for it in one short sentence:

- `请把要复盘的项目路径发给我，我会先定位相关 Codex 记录，再总结问题模式和可回写的优化点。`

## Read First

- `AGENTS.md`
- `.planning/STATE.md` if it exists
- `references/record-sources.md`
- `scripts/find_codex_project_records.py`
- `scripts/extract_codex_session_timeline.py`

## Goals

- locate the Codex records most likely tied to the target project path
- reconstruct the real workflow that happened instead of relying on memory
- distinguish product/code problems from workflow/prompt/routing problems
- extract reusable improvements for super-stack rules, skills, or references
- avoid mutating user records while analyzing them

## Rules

- treat Codex records as read-only evidence
- prefer project-path filtering over broad global history summaries
- do not assume the current or very recent live session has already been indexed into local record stores
- distinguish confirmed evidence from inference when records are partial
- focus on repeated failure patterns, route misses, scope drift, verification gaps, and communication friction
- separate “this project was unusually messy” from “super-stack rule design is weak”
- when proposing repository changes, name the exact file or skill that should absorb the lesson
- when the lesson implies a skill change, recommend the source-repository skill path rather than a host-installed runtime copy
- do not rely on broad global history summarizers as the default or only evidence path; start from path-correlated sources first
- do not stop after a single weak source; if path correlation is missing, continue through the next record source or explicitly report the evidence gap
- default retrospective summaries and recommendations to Chinese

## Process

1. Confirm the target project path.
2. Run `scripts/find_codex_project_records.py --project-path <path>` first to get a path-correlated evidence scan.
   - if the project was moved or renamed across roots, add `--project-path-alias <old-path>` for each known historical path before falling back to broader fuzzy correlation.
3. For the strongest candidate sessions, run `scripts/extract_codex_session_timeline.py --session-id <id>` to get a readable timeline before doing manual deep reads.
4. Use `references/record-sources.md` to locate any extra sources still needed.
5. Start with path-correlated sources such as `session_index`, `sessions`, or `archived_sessions` before broad history summaries.
6. Filter records by project path, cwd, session metadata, or nearby timestamps.
7. If the most recent live session is missing from indexed records, say so explicitly and continue with the next best sources instead of pretending the evidence is complete.
8. Reconstruct the sequence:
   - user intent
   - chosen workflow path
   - major pivots or backtracks
   - verification path
   - unresolved friction
9. Classify issues into:
   - routing problem
   - planning problem
   - implementation discipline problem
   - verification problem
   - host/runtime limitation
   - project-specific noise
10. Extract only the lessons that generalize beyond that one project.
11. Recommend where each lesson belongs:
   - `AGENTS.md`
   - `protocols/`
   - an existing skill
   - a new reference
   - no repository change, just project-specific caution
12. Update `.planning/STATE.md` when the retrospective changes repository workflow direction or maintenance priorities.

## Output

Report:

- target project path
- records reviewed
- evidence gaps, especially when current-session records are not yet indexed
- reconstructed workflow summary
- main failure or friction patterns
- what appears project-specific
- what should be fed back into super-stack
- the exact repository files or skills that should absorb the lesson
- whether you recommend immediate repository changes or just a tracked note
