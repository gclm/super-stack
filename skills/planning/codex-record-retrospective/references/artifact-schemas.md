# Artifact Schemas

Use this reference when creating or validating retrospective artifacts, recommendation artifacts, or ledger entries.

## Purpose

These schemas keep daily automation, manual retrospective work, and follow-up skill maintenance aligned to one stable shape.

They are intentionally lightweight:

- enough structure for scripts to consume
- enough readability for humans to review
- no attempt to become a full formal JSON Schema yet

## 1. Retrospective JSON

Recommended path:

- `artifacts/retrospectives/YYYY-MM-DD-<topic>.json`
- `artifacts/retrospectives/YYYY-MM-DD-<topic>.md`

Recommended fields:

- `schema_version`
- `generated_at`
- `project_path`
- `project_aliases`
- `records_reviewed`
- `checked_sources`
- `workflow_summary`
- `patterns`
- `classifications`
- `generalized_lessons`
- `recommended_targets`
- `evidence_strength`
- `evidence_gaps`
- `execution_shape`
- `completion_gap_signals`
- `confidence`

Notes:

- `patterns`, `classifications`, and `generalized_lessons` may be strings or objects, but objects are preferred when evidence refs matter.
- `execution_shape` should distinguish ordinary work from long-running or multi-session work.

## 2. Recommendation JSON

Recommended path:

- `artifacts/evolution/YYYY-MM-DD-<topic>-recommendations.json`

Recommended fields:

- `schema_version`
- `generated_at`
- `project_path`
- `project_aliases`
- `source_retrospective`
- `recommendations`
- `unmapped_lessons`
- `governance_sync_required`

Each `recommendations[]` item should prefer:

- `lesson_id`
- `summary`
- `problem_type`
- `target_files`
- `change_kind`
- `default_confidence`
- `approval_level`
- `validation_hint`
- `matched_mapping`
- `evidence_refs`

## 3. Evolution Ledger JSONL

Recommended path:

- `artifacts/evolution/evolution-ledger.jsonl`

Each line should stay append-only and compact.
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

## 4. Status Vocabulary

Prefer these stable values:

### `evidence_strength`

- `weak`
- `moderate`
- `strong`

### `approval_level` or `recommendation_status`

- `record-only`
- `patch-proposed`
- `apply-approved`
- `accepted`
- `rejected`

### `execution_shape`

- `one-shot`
- `multi-step`
- `multi-session`
- `long-running`

## 5. Samples

Repository examples live at:

- `artifacts/retrospectives/examples/sample-retrospective.json`
- `artifacts/evolution/examples/sample-recommendations.json`

Default render or post-process helpers:

- `scripts/render_retrospective_report.py`
- `scripts/process_retrospective.py`
