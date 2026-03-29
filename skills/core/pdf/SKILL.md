---
name: pdf
description: Read, create, or review PDF files. Use this skill when text extraction, rendering fidelity, scanned PDFs, page layout, or PDF generation matters, and choose the lightweight text path before the full rendering path when layout is not the main concern.
---

# PDF

Use this skill when the task involves PDF files and success depends on extracting content reliably, generating PDFs, or validating rendered output.

## Read First

- the target PDF files
- `references/task-routing.md` to choose between lightweight text extraction and full rendering review
- `harness/state.md` if the task is part of an ongoing project workflow
- `harness/history.md` if it exists
## Goals

- choose the lightest PDF workflow that can still answer the user request
- avoid over-installing heavy dependencies for one-off text extraction tasks
- verify rendering visually when layout fidelity actually matters
- keep temp and output files organized

## Rules

- first classify the task as either `lightweight text extraction` or `full PDF review/generation`
- for resume screening, field extraction, keyword analysis, or quick content checks, prefer the lightweight path
- do not treat extracted text as proof of layout quality
- when the PDF is scanned, image-based, or visually important, route to the full rendering path
- prefer the user's or project's default Python environment before creating ad hoc environments
- only install system tools such as `poppler` when the task truly needs rendering or image export
- if dependency installation is blocked, say which dependency is missing and continue with the best fallback path that still preserves answer quality

## Process

1. Read `references/task-routing.md` and classify the task.
2. Run a quick environment preflight for Python and PDF tools.
3. If the task is text extraction, prefer `pypdf`, then `pdfplumber` if needed.
4. If the task is rendering-sensitive, use `pdftoppm`/`poppler` and inspect rendered pages.
5. For PDF generation, use stable programmatic tools such as `reportlab` and re-render for visual checks.
6. Keep intermediate artifacts in `tmp/pdfs/` and final repo outputs in `output/pdf/` when working inside a repository.
7. Report what workflow path was used, what dependencies were required, and what evidence supports the result.

## Output

Tell the user:

- which PDF workflow path was used: `lightweight text extraction` or `full PDF review/generation`
- which dependencies or tools were available, missing, or installed
- whether layout fidelity was actually verified visually
- where any output files were written
- any remaining evidence gaps such as scanned text quality or missing OCR
