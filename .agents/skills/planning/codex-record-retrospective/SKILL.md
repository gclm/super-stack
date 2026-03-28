---
name: codex-record-retrospective
description: Review Codex local records for a specific project path, reconstruct what happened, and generate reusable retrospective or skill-evolution recommendations for super-stack.
---

# Codex Record Retrospective

Use this skill when the user wants to review or 复盘某个项目里的 Codex 实战记录，并把经验反哺到 workflow、skills、prompts 或治理规则。

Prefer this skill when:

- the user gives a concrete project path
- the user mentions Codex records, history, sessions, archived sessions, or local conversation traces
- the goal is not just to inspect the target codebase, but to inspect how Codex behaved while working in that codebase
- the user wants structured retrospective or recommendation artifacts

If the project path is missing, ask the user for it in one short sentence:

- `请把要复盘的项目路径发给我，我会先定位相关 Codex 记录，再总结问题模式和可回写的优化点。`

## Read First

- `AGENTS.md`
- `.planning/STATE.md` if it exists
- `references/record-sources.md`
- `references/auto-evolution-loop.md`
- `references/artifact-schemas.md`
- `references/long-running-agent-patterns.md`
- `references/lesson-target-map.json`
- `scripts/find_codex_project_records.py`
- `scripts/extract_codex_session_timeline.py`
- `scripts/slice_codex_session.py`
- `scripts/process_retrospective.py`

## Goals

- locate the Codex records most likely tied to the target project path
- reconstruct the real workflow that happened instead of relying on memory
- distinguish product/code problems from workflow/prompt/routing problems
- normalize reusable lessons into stable categories when possible
- generate reusable retrospective or recommendation artifacts
- avoid mutating user records while analyzing them

## Rules

- treat Codex records as read-only evidence
- prefer project-path filtering over broad global history summaries
- do not assume the current or very recent live session has already been indexed into local record stores
- distinguish confirmed evidence from inference when records are partial
- focus on repeated route misses, scope drift, verification gaps, communication friction, and long-running execution issues
- do not assume one session equals one task; when a long session contains multiple asks, slice first and extract lessons from the relevant slice
- separate project messiness from shared workflow weakness
- prefer exact source-repo target files when proposing reusable changes
- use `report -> recommendation -> approval` as the default chain instead of jumping straight to repository edits
- prefer updating `references/`、mapping、or scripts before bloating `SKILL.md`
- default retrospective summaries and recommendations to Chinese

For source selection, slicing heuristics, long-running patterns, and artifact fields, rely on the references above instead of expanding this entry file.

## Process

1. Confirm the target project path.
2. Run `scripts/find_codex_project_records.py --project-path <path>` first.
   - if the project moved, add `--project-path-alias <old-path>` before falling back to broader correlation
3. For the strongest candidate sessions, run `scripts/extract_codex_session_timeline.py --session-id <id>`.
4. If one session contains multiple tasks or long gaps, run `scripts/slice_codex_session.py` and work from the relevant slice.
5. Use `references/record-sources.md` to continue through stronger sources before broad history summaries.
6. If the current live session is not yet indexed, call that out explicitly and continue with the next best evidence.
7. Reconstruct the sequence:
   - user intent
   - chosen workflow path
   - major pivots or backtracks
   - verification path
   - unresolved friction
8. Classify issues into:
   - routing problem
   - planning problem
   - implementation discipline problem
   - verification problem
   - host/runtime limitation
   - project-specific noise
   - long-running execution gap
9. Normalize reusable lessons with stable ids from `references/lesson-target-map.json`; mark new ids as provisional.
10. Produce a retrospective artifact when the work is likely to be reused.
11. For the default post-processing path, run `scripts/process_retrospective.py` against the retrospective JSON.
12. When recommendations or strong reusable lessons are produced, append them to the evolution ledger unless the user explicitly wants a no-file summary.
13. Separate recommendation levels clearly:
    - `record-only`
    - `patch-proposed`
    - `apply-approved`
14. Recommend where each lesson belongs: `references/`、mapping/scripts、`protocols/`、existing skill、`AGENTS.md`，or no repository change.
15. Update `.planning/STATE.md` when the retrospective changes repository workflow direction or maintenance priorities.

## Output

Report should include:

- target project path and records reviewed
- evidence gaps, especially when current-session records are not yet indexed
- reconstructed workflow summary and main friction patterns
- normalized lessons, provisional ids, and project-specific noise
- recommended super-stack targets and recommendation level
- retrospective / recommendation artifact paths when generated
