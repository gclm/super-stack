# Harness History

This file is append-first project history for repository-level workflow changes.

Rules:
- Add new entries; do not rewrite older conclusions unless correcting a factual error.
- Keep `harness/state.md` focused on the current state only.
- Put durable implementation history, validation outcomes, and workflow changes here.
- Prefer one entry per meaningful repository-level change, not one entry per trivial edit.

Entry Template:

```md
## YYYY-MM-DD

### Title
- what changed
- what changed

Reason:
- why the change was made

Evidence:
- tests, checks, screenshots, logs, or other proof

Impact:
- current effect on workflow, runtime, or future work

Next:
- optional follow-up, if any
```

## 2026-03-29

### Source Path Visibility Migration
- Renamed source-repository directories from hidden host-style paths to visible names: `.agents/skills` -> `skills/`, `.codex/` -> `codex/`, `.claude/` -> `claude/`.
- Updated install, check, smoke, test, skill, and architecture/documentation references to use visible source paths while keeping runtime/home paths unchanged (`~/.agents/skills`, `~/.codex`, `~/.claude`, and runtime `/.codex/hooks`).
- Adjusted skill validation to treat `~/...` runtime references as external/home paths instead of broken repo-local references.

Reason:
- Repo-local hidden directories collided semantically with home/runtime hidden directories, making requests like “去 `.agents` 查一下” ambiguous.
- The source/runtime boundary becomes clearer when only runtime stays hidden and source uses visible names.

Evidence:
- `python3 scripts/check/validate-skills.py --path skills`
- `python3 -m unittest -v tests.python.test_super_stack_state tests.python.test_skill_validation_and_evolution tests.python.test_skill_validation_exceptions tests.python.test_retrospective_processing tests.python.test_session_slicing tests.python.test_retrospective_rendering tests.python.test_harness_scaffold tests.python.test_managed_config_rendering tests.python.test_managed_config_checks`
- `bash tests/shell/test_hook_merge_idempotent.sh`
- `bash tests/shell/test_global_install_roundtrip.sh`

Impact:
- The source repo no longer contains `.agents`, so future references to `.agents` can safely bias toward `~/.agents`.
- Source and runtime paths now follow a clearer split: visible names in-repo, hidden names in home/runtime.

Next:
- Watch for downstream tools or prompts that still assume source-side hidden paths and update them in the same change-set when found.

## 2026-03-29

### MCP Config Cleanup
- Fixed `codex_mcp` rendering so server-level `env` is preserved for OpenSpace.
- Clarified that `[projects.*].trust_level` is project trust config, not MCP config.
- Cleaned local `~/.codex/config.toml` so project trust lives outside the managed MCP block.

Reason:
- MCP ownership and project trust ownership were mixed.
- Managed MCP output was being simplified during rendering.

Evidence:
- Codex MCP render tests passed after the change.
- Local `~/.codex/config.toml` now keeps the project trust block outside `# BEGIN/END SUPER-STACK CODEX MCP`.

Impact:
- MCP managed blocks no longer mix project-trust config.
- OpenSpace MCP env survives managed rendering.

### Config Manifest Unification
- Merged `config/managed-config.json` and `config/skill-validation-exceptions.json` into `config/manifest.json`.
- Unified `mcp.servers`, `managed_blocks`, and `skill_validation.ignore_warnings` under one config source.

Reason:
- Config truth was split across multiple JSON files.
- Future extension would otherwise keep adding more file-level drift.

Evidence:
- Rendering, check, and skill validation logic now all read `config/manifest.json`.
- Repository tests passed after the migration.

Impact:
- Config governance now has one source of truth.

### Manifest Validation And Install Checks
- Added `scripts/config/validate_manifest.py`.
- Added `config/manifest.schema.json`.
- Wired manifest validation into `scripts/test/python.sh` and `scripts/check/check-global-install.sh`.

Reason:
- Config breakage needed to fail early, before install/check logic drifted.

Evidence:
- Manifest validation passes in test and check entrypoints.
- `check-global-install.sh` now prints a `Manifest` section before runtime checks.

Impact:
- Config structure and semantics now fail fast during validation and install checks.

### Manifest Interface Hardening
- Added `manifest_version = 1` to `config/manifest.json`.
- Added explicit block `kind` values: `agents`, `hooks`, `mcp`.
- Removed key logic that depended on block id naming patterns.

Reason:
- Block behavior should be driven by explicit metadata, not naming conventions.

Evidence:
- Schema validation rejects missing `kind` and invalid `manifest_version`.
- Python test suite passed with the upgraded manifest interface.

Impact:
- Config behavior no longer depends on block-id naming conventions.

### Legacy State Cutover Completion
- `.planning/` directory removed entirely (15 files: STATE.md, PROJECT.md, REQUIREMENTS.md, ROADMAP.md, CONVENTIONS.md, codebase/*.md, hook logs).
- `harness/state.md` trimmed to active execution state only; stabilized decisions moved here as durable record.
- `harness/history.md` is now the sole location for historical changes and architecture decisions.

Reason:
- The `.planning/` heavy model was inherited from an earlier workflow experiment (GSD-style spec-heavy directory). It has been fully superseded by `docs/ + harness/` single-source-of-truth layout.
- `state.md` was still carrying decisions that had already landed and no longer needed active tracking.

Evidence:
- No remaining references to `.planning/` in the repository (rg verified before deletion).
- `harness/state.md` reduced to status, focus, active constraints, active decisions, and next actions.
- `harness/history.md` now holds all durable decision and change records.

Impact:
- The repository no longer has a parallel legacy state directory.
- `state.md` reads as a low-cost execution summary; `history.md` carries all durable context.
- Future work should only add entries to `docs/` and `harness/`.

Next:
- Phase 5 items can proceed without legacy sync overhead.

## 2026-03-29

### Codex Runtime Skill Boundary And Parity Gate
- Enforced Codex runtime skill boundary: `~/.codex/skills` now keeps only host/system-local `.system` entries; super-stack global skills are sourced from `~/.agents/skills`.
- Added runtime parity checker: `scripts/check/check-skill-runtime-parity.py` to compare repo source-of-truth (`skills`) with `~/.agents/skills` using normalized paths and content hash checks.
- Wired parity checker into source checks via `scripts/check/run-source-checks.sh` with `--enforce-codex-system-only`.
- Updated `scripts/install/install-codex.sh` to stop copying OpenSpace skills into `~/.codex/skills`.
- Removed GitHub-hosted minimal CI workflow (`.github/workflows/ci.yml`) per current project policy.

Reason:
- Runtime skill ownership between `~/.agents/skills` and `~/.codex/skills` needed a strict, durable boundary to prevent drift and duplicate/conflicting copies.
- Release-time confidence should come from local/source checks aligned with real runtime constraints instead of low-fidelity hosted CI.

Evidence:
- Manual cleanup completed: non-`.system` entries removed from `~/.codex/skills`.
- `python3 scripts/check/check-skill-runtime-parity.py --enforce-codex-system-only` returned `PASS`.
- `bash scripts/check/run-source-checks.sh` completed with skill validation + parity check + unit tests + shell syntax checks all passing.
- Commit recorded: `01480c3 chore: enforce runtime skill parity and remove github ci`.

Impact:
- Codex runtime can no longer silently consume stale repo skills from `~/.codex/skills`.
- Release path now fails fast when `~/.agents/skills` drifts from source-of-truth or when Codex local skills violate `.system`-only policy.
- Repository no longer depends on GitHub CI for the minimal regression layer.

Next:
- If installation policy changes again, update parity checker and install scripts in the same change-set to keep policy and enforcement synchronized.

## 2026-03-29

### Harness State Hygiene Guardrails
- Added `scripts/check/check-harness-state.sh` to enforce lightweight `harness/state.md` hygiene.
- Wired harness governance check into `scripts/check/run-source-checks.sh`.
- Added `State Hygiene` section to `protocols/workflow-governance.md` with event-driven archive defaults and soft thresholds.
- Refreshed `harness/state.md` to keep only current execution context, moving durable context to history.

Reason:
- Avoid `state.md` growth turning into long-lived dependency context that increases routing drift and decision noise.
- Ensure state/history discipline is enforced by checks, not only manual habit.

Evidence:
- `bash scripts/check/run-source-checks.sh` passed with harness governance check active.
- Current `harness/state.md` line and bullet counts are below configured thresholds.

Impact:
- Stage-boundary and release-boundary changes are less likely to leave durable decisions only in volatile state.
- Future turns get cleaner current-state context with lower prompt bloat risk.

Next:
- If team cadence changes, tune `HARNESS_STATE_MAX_LINES` and `HARNESS_STATE_MAX_BULLETS` defaults with one recorded history entry.

## 2026-03-29

### Script Layout Refactor: release + workflow
- Moved promotion orchestrator from `scripts/runtime/promote-to-runtime.sh` to `scripts/release/promote-to-runtime.sh`.
- Consolidated developer-facing workflow scripts into `scripts/workflow/`:
  - `init-generated-project.sh`
  - `init-harness-task.sh`
  - `worktree-manager.sh`
- Removed legacy directories `scripts/runtime/`, `scripts/generate/`, and `scripts/dev/` (no compatibility wrappers retained by request).
- Updated risk classification and targeted smoke path rules to recognize `scripts/release/*` and `scripts/workflow/*`.
- Updated README and rollout guidance docs to reflect the new script topology and Git Flow worktree usage.

Reason:
- Previous structure mixed release orchestration with runtime naming, and split workflow tools across unrelated folders.
- New layout improves discoverability and matches responsibilities: `release` for promotion, `workflow` for developer orchestration.

Evidence:
- `tests/shell/test_runtime_promotion_gate.sh` passes with new release/workflow paths.
- `python3 -m unittest tests.python.test_harness_scaffold -v` passes after path updates.
- Repository-wide grep shows no remaining references to removed script directories in docs/tests/scripts.

Impact:
- Script entrypoints are now responsibility-aligned and easier to reason about.
- Direct path migration requires consumers to use new paths immediately.

Next:
- Keep future workflow bootstrap/worktree tools under `scripts/workflow/`.
- Keep release gate orchestration under `scripts/release/`.
