# DOCX Task Routing

Use this reference to choose the correct DOCX workflow before installing dependencies or starting edits.

## 1. Lightweight Text Extraction

Use this path when the task is mainly about document content rather than visual layout.

Typical examples:
- reading a resume or report in `.docx`
- extracting headings, paragraphs, tables as text, or key fields
- summarizing or screening document content
- quick content checks before deeper edits

Preferred tools:
- `python-docx`

Dependency strategy:
- prefer the project's or user's default Python environment
- install the minimum Python package set needed for extraction
- avoid installing `libreoffice` or `poppler` unless rendering is actually required

Important limits:
- extracted text does not prove the page layout is correct
- table structure may degrade when converted to plain text summaries
- pagination, floating elements, and visual alignment remain unverified

## 2. Full DOCX Review Or Editing

Use this path when layout, formatting, or rendered fidelity matters.

Typical examples:
- editing a professional Word document while preserving structure
- checking margins, tables, fonts, page breaks, or pagination
- reviewing interview forms, reports, proposals, or client-facing documents
- validating that a generated `.docx` renders cleanly page by page

Preferred tools:
- `python-docx` for edits
- `soffice` for DOCX -> PDF rendering
- `pdftoppm` or equivalent page-image export for visual checks
- `scripts/render_docx.py` as a local helper when useful

Dependency strategy:
- install `libreoffice` and `poppler` only when page rendering is needed
- install Python libraries only when the task needs real DOCX editing or render helpers

## 3. Environment Choice

Before creating a temporary environment, check:
- whether the repository already defines a Python environment
- whether the user has a default `conda` environment preference
- whether the task is one-off or likely to repeat

Recommended order:
1. project-declared environment
2. user default environment such as `conda`
3. temporary `venv` for isolated fallback work

## 4. Reporting Expectations

Always report:
- the chosen workflow path
- whether the answer relies on extracted text, rendered pages, or both
- which dependencies were missing or installed
- any quality limits, especially when pagination or layout was not visually verified
