# Bootstrap Decision Rules

Use these rules before calling `init-generated-project.sh`.

## 1. Readiness States

- `ready`
  - the target repo docs entrypoint exists
  - the target repo harness state file exists
  - the repository already has the expected execution and documentation entrypoints
- `missing`
  - both the target repo docs entrypoint and harness state file are absent
  - the user wants to adopt the standard generated-project layout
- `partial`
  - one of the expected paths exists, but the other is missing
  - or the repository has nearby custom structure that may conflict with the generated layout

## 2. Safe To Run Directly

Direct bootstrap is usually safe when all of these are true:

- the repository is `missing`
- the user explicitly wants the standard super-stack layout
- there is no stronger existing documentation or execution convention that should win

## 3. Fill-Missing Mode

`init-generated-project.sh` is non-destructive and does not overwrite existing files, so it can be used to fill missing paths in low-conflict `partial` cases.

Still check these conditions first:

- the existing `docs/` tree is not intentionally using a conflicting top-level design
- the user intent is to converge toward the generated-project layout
- adding the missing scaffold will not mislead later automation into thinking migration is already complete

If any of those are unclear, do not silently run the generator.

## 4. When To Stop And Escalate

Do not run bootstrap blindly when:

- the repository already has an established documentation architecture that differs materially
- the user asked for analysis only, not direct repository edits
- the repository is multi-module and the target bootstrap boundary is still ambiguous

In those cases, step back to `plan`, `migration-design`, or `discuss`.

## 5. Separation From Task Bootstrap

Keep these two actions separate:

- project bootstrap
  - initialize repo-level docs-plus-harness scaffold
- task bootstrap
  - initialize the repo task pack under `harness/tasks/<task-id>/...`

`task-harness` owns the second action, not the first.
