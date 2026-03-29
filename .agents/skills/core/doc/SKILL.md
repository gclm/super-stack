---
name: doc
description: Read, create, or edit `.docx` documents. Use this skill when Word document structure, formatting, tables, pagination, or rendered layout matters, and choose the lightweight text path before the full visual rendering path when layout is not the main concern.
---

# DOCX

Use this skill when the task involves `.docx` files and success depends on extracting content reliably, editing with preserved structure, or validating rendered layout.

## Read First

- the target `.docx` files
- `references/task-routing.md` to choose between lightweight text extraction and full rendering review
- `harness/state.md` if the task is part of an ongoing project workflow
- `harness/history.md` if it exists
## Goals

- choose the lightest DOCX workflow that still answers the user request correctly
- avoid over-installing heavy document tooling for one-off text extraction tasks
- preserve structure and formatting when editing DOCX files
- verify rendered layout visually when pagination, tables, or spacing matter

## Rules

- first classify the task as either `lightweight text extraction` or `full DOCX review/editing`
- for content extraction, summaries, field reads, or quick checks, prefer the lightweight path
- do not treat extracted text as proof that DOCX layout is correct
- when the document contains tables, pagination-sensitive content, diagrams, or client-facing formatting, route to the full rendering path
- prefer the user's or project's default Python environment before creating ad hoc environments
- only install system tools such as `libreoffice` and `poppler` when the task truly needs rendering or page-image review
- if visual review is impossible, state the layout risk clearly instead of pretending the document is fully verified

## Process

1. Read `references/task-routing.md` and classify the task.
2. Run a quick environment preflight for Python and DOCX/PDF rendering tools.
3. If the task is text extraction, prefer `python-docx` for structured text reads.
4. If the task is editing or rendering-sensitive, use `python-docx` for edits and render the result through `soffice` plus page-image checks when needed.
5. Use `scripts/render_docx.py` when you need a stable local render helper for page review.
6. Keep intermediate artifacts in `tmp/docs/` and final repo outputs in `output/doc/` when working inside a repository.
7. Report which workflow path was used, what dependencies were required, and what evidence supports the result.

## Output

Tell the user:

- which DOCX workflow path was used: `lightweight text extraction` or `full DOCX review/editing`
- which dependencies or tools were available, missing, or installed
- whether layout fidelity was actually verified visually
- where any output files were written
- any remaining evidence gaps such as unverified pagination, scanned assets, or missing render tooling
