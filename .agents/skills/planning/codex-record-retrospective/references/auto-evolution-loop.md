# Auto Evolution Loop

Use this reference when a retrospective should go beyond a one-off summary and become a candidate skill or protocol update.

## Purpose

The goal is not to let super-stack silently rewrite itself.
The goal is to turn repeated, high-signal retrospective lessons into structured recommendations that can be reviewed and, if approved, applied to the source repository.

## Default Chain

Use this chain unless the user explicitly wants only a lightweight summary:

1. collect evidence
2. extract timeline
3. classify issues
4. normalize lessons
5. generate retrospective artifact
6. generate recommendation artifact
7. append or update evolution ledger
8. ask for or infer approval level
9. only then consider repository edits

Do not collapse this into a single “I found a problem so I changed the rules” jump.

For the default scripted path, prefer:

- `scripts/process_retrospective.py`

This keeps recommendation JSON, Markdown, and ledger append in one consistent flow.

## Trigger Conditions

This loop is most justified when one or more of the following are true:

- the same problem pattern appears across multiple sessions
- the user had to correct the same workflow mistake more than once
- a backtrack such as `build -> debug` or `build -> plan` was necessary and avoidable
- `review` / `verify` exposed a repeated shared-rule gap
- the lesson is clearly reusable beyond one project

If the issue is only weakly evidenced or clearly project-specific, stop at the retrospective report.

## Lesson Normalization

Prefer stable lesson ids instead of ad hoc prose.
Examples:

- `module_scope_ambiguity`
- `verify_overclaim`
- `route_not_explicit`
- `record_path_migration_gap`
- `host_limitation_not_explained`
- `skill_entry_bloat`
- `evidence_gap_not_called_out`

If no stable id exists yet:

- use a provisional snake_case id
- say explicitly that it is provisional
- do not treat it as a new repository-wide rule until it repeats

## Recommendation Levels

Use one of these levels for each recommended change:

- `record-only`
  - keep the lesson in artifacts or ledger only
  - no source repo edit suggested yet
- `patch-proposed`
  - suggest exact target files and optionally a patch draft
  - do not apply automatically
- `apply-approved`
  - only after explicit user approval
  - apply to source repo, then run minimal validation and update `STATE.md`

## Target Selection Order

When deciding where a lesson should land, prefer this order:

1. existing `references/`
2. mapping files or helper scripts
3. existing `protocols/`
4. existing `SKILL.md`
5. `AGENTS.md`

This keeps skills thin and avoids turning entry files into giant policy dumps.

## Evidence Threshold Guidance

Use repeated signal and evidence strength together:

- weak evidence + one-off issue -> `record-only`
- strong evidence + repeated issue in one area -> `patch-proposed`
- repeated issue across projects or clearly harmful shared-rule gap -> consider `patch-proposed` or `apply-approved`

For core governance files such as `AGENTS.md` and `protocols/`, default to `patch-proposed` unless the user clearly approves direct edits.

## Artifacts

Prefer stable artifact paths when files are being created:

- `artifacts/retrospectives/YYYY-MM-DD-<topic>.md`
- `artifacts/retrospectives/YYYY-MM-DD-<topic>.json`
- `artifacts/evolution/YYYY-MM-DD-<topic>-recommendations.md`
- `artifacts/evolution/YYYY-MM-DD-<topic>-recommendations.json`
- `artifacts/evolution/evolution-ledger.jsonl`

If the user did not ask to write files, it is still useful to report these as the recommended artifact shapes.

For field-by-field expectations and repository examples, also read `references/artifact-schemas.md`.

## Ledger Entry Shape

Each ledger line should stay small and append-only.
Recommended fields:

- `timestamp`
- `project_path`
- `lesson_id`
- `evidence_strength`
- `recommendation_status`
- `accepted_targets`
- `rejected_reason`
- `applied_commit_or_note`
- `source_retrospective`
- `source_recommendation`

## Validation After Apply

After approved changes are applied, do a text-level validation pass:

- referenced files exist
- any new mapping file is parseable
- `SKILL.md` remains a thin entry file
- related routing or state files stay aligned

If the change materially alters repository workflow behavior, update `.planning/STATE.md`.
