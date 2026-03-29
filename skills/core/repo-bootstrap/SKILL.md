---
name: repo-bootstrap
description: Inspect a repository and decide whether to initialize the generated-project scaffold before task-level harness work begins.
---

# Repo Bootstrap

Use when entering a repository that may not yet have the standard docs-plus-harness layout, or when the user wants to adopt super-stack's generated-project scaffold safely.

## Read First

- root `AGENTS.md`
- nearby entry docs such as `README*`, `docs/`, and top-level manifests
- `harness/state.md` if it exists
- `harness/history.md` if it exists
- `references/bootstrap-decision-rules.md`
- `~/.super-stack/runtime/scripts/workflow/init-generated-project.sh`
- `~/.super-stack/runtime/scripts/workflow/init-harness-task.sh` only if the user also wants the first task pack

## Goals

- inspect the repository before writing bootstrap files
- classify the repository as `missing`, `partial`, or `ready`
- initialize the standard docs-plus-harness scaffold only when it is truly missing or clearly safe to fill
- avoid mixing project bootstrap with task bootstrap
- hand the repository off to `task-harness`, `plan`, or migration work with a clear readiness status

## Process

1. Inspect whether the target repo already has its docs entrypoint, harness state file, and related layout.
2. Use `references/bootstrap-decision-rules.md` to classify the repository state.
3. If the repository is `ready`, do not rerun bootstrap; report readiness and move to `task-harness` or the requested stage.
4. If the repository is `missing` and the user wants the standard layout, run `bash ~/.super-stack/runtime/scripts/workflow/init-generated-project.sh --root <repo-root>`.
5. If the repository is `partial`, only fill missing scaffold files when the conflict risk is low and the user intent is explicit; otherwise step back to `plan` or migration design instead of forcing the layout.
6. If the repository has no `docs/` or `harness/` scaffold yet, treat bootstrap as a clean init.
7. If the user also has a concrete task after bootstrap, either hand off to `task-harness` or create the first task pack with `bash ~/.super-stack/runtime/scripts/workflow/init-harness-task.sh --task-id <task-id>`.

## Output

Tell the user:

- the repository readiness state
- whether bootstrap was executed, skipped, or deferred
- what files or directories were created when bootstrap ran
- whether the next step is `task-harness`, `plan`, or migration work
